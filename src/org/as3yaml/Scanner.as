/*
 * Copyright (c) 2007 Derek Wischusen
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of 
 * this software and associated documentation files (the "Software"), to deal in 
 * the Software without restriction, including without limitation the rights to 
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
 * SOFTWARE.
 */


package org.as3yaml {
	import org.as3yaml.tokens.*;
	import org.idmedia.as3commons.util.*;
	import org.rxr.actionscript.io.StringReader;

	


public class Scanner {
    private static const LINEBR : String = "\n\u0085\u2028\u2029";
    private static const NULL_BL_LINEBR : String = "\x00 \r\n\u0085";
    private static const NULL_BL_T_LINEBR : String = "\x00 \t\r\n\u0085";
    private static const NULL_OR_OTHER : String = NULL_BL_T_LINEBR;
    private static const NULL_OR_LINEBR : String = "\x00\r\n\u0085";
    private static const FULL_LINEBR : String = "\r\n\u0085";
    private static const BLANK_OR_LINEBR : String = " \r\n\u0085";
    private static const S4 : String = "\0 \t\r\n\u0028[]{}";    
    private static const ALPHA : String = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-_";
    private static const STRANGE_CHAR : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789][-';/?:@&=+$,.!~*()%";
    private static const RN : String = "\r\n";
    private static const BLANK_T : String = " \t";
    private static const SPACES_AND_STUFF : String = "'\"\\\x00 \t\r\n\u0085";
    private static const DOUBLE_ESC : String = "\"\\";
    private static const NON_ALPHA_OR_NUM : String = "\x00 \t\r\n\u0085?:,]}%@`";
    private static const NON_PRINTABLE : RegExp = new RegExp("[^\x09\x0A\x0D\x20-\x7E\x85\xA0-\uD7FF\uE000-\uFFFD]");
    private static const NOT_HEXA : RegExp = new RegExp("[^0-9A-Fa-f]");
    private static const NON_ALPHA : RegExp = new RegExp("[^-0-9A-Za-z_]");
    private static const R_FLOWZERO : RegExp = new RegExp(/[\x00 \t\r\n\u0085]|(:[\x00 \t\r\n\u0028])/);
    private static const R_FLOWNONZERO : RegExp = new RegExp(/[\x00 \t\r\n\u0085\\\[\\\]{},:?]/);
    private static const LINE_BR_REG : RegExp = new RegExp("[\n\u0085]|(?:\r[^\n])");
    private static const END_OR_START : RegExp = new RegExp("^(---|\\.\\.\\.)[\0 \t\r\n\u0085]$");
    private static const ENDING : RegExp = new RegExp("^---[\0 \t\r\n\u0085]$");
    private static const START : RegExp = new RegExp("^\\.\\.\\.[\x00 \t\r\n\u0085]$");
    private static const BEG : RegExp = new RegExp(/^([^\x00 \t\r\n\u0085\\\-?:,\\[\\\]{}#&*!|>'\"%@]|([\\\-?:][^\x00 \t\r\n\u0085]))/);

    private static var ESCAPE_REPLACEMENTS : Map = new HashMap();
    private static var ESCAPE_CODES : Map = new HashMap();

	static: { 
        ESCAPE_REPLACEMENTS.put('0',"\x00");
        ESCAPE_REPLACEMENTS.put('a',"\u0007");
        ESCAPE_REPLACEMENTS.put('b',"\u0008");
        ESCAPE_REPLACEMENTS.put('t',"\u0009");
        ESCAPE_REPLACEMENTS.put('\t',"\u0009");
        ESCAPE_REPLACEMENTS.put('n',"\n");
        ESCAPE_REPLACEMENTS.put('v',"\u000B");
        ESCAPE_REPLACEMENTS.put('f',"\u000C");
        ESCAPE_REPLACEMENTS.put('r',"\r");
        ESCAPE_REPLACEMENTS.put('e',"\u001B");
        ESCAPE_REPLACEMENTS.put(' ',"\u0020");
        ESCAPE_REPLACEMENTS.put('"',"\"");
        ESCAPE_REPLACEMENTS.put('\\',"\\");
        ESCAPE_REPLACEMENTS.put('N',"\u0085");
        ESCAPE_REPLACEMENTS.put('_',"\u00A0");
        ESCAPE_REPLACEMENTS.put('L',"\u2028");
        ESCAPE_REPLACEMENTS.put('P',"\u2029");

        ESCAPE_CODES.put('x', new int(2));
        ESCAPE_CODES.put('u', new int(4));
        ESCAPE_CODES.put('U', new int(8));
    }

    private var done : Boolean = false;
    private var flowLevel : int = 0;
    private var tokensTaken : int = 0;
    private var indent : int = -1;
    private var allowSimpleKey : Boolean = true;
    private var eof : Boolean = true;
    private var column : int = 0;
    private var pointer : int = 0;
    private var buffer : String;
    private var stream : StringReader;
    private var tokens : ArrayList;
    private var indents : Array;
    private var possibleSimpleKeys : Map;

    private var docStart : Boolean = false;

    public function Scanner(stream : StringReader) {
        this.stream = stream;
        this.eof = false;
        this.buffer = new String();
        this.tokens = new ArrayList();
        this.indents = new Array();
        this.possibleSimpleKeys = new HashMap();
        fetchStreamStart();
    }

    public function checkToken(choices : Array) : Boolean {
        while(needMoreTokens()) {
            fetchMoreTokens();
        }
        if(!this.tokens.isEmpty()) {
            if(choices.length == 0) {
                return true;
            }
           var first : Object = this.tokens.get(0);
            for (var i : int = 0; i < choices.length;   i++) {
                if(choices[i].isInstance(first)) {
                    return true;
                }
            }
        }
        return false;
    }

    public function peekToken() : Token {
        while(needMoreTokens()) {
            fetchMoreTokens();
        }
        return Token(this.tokens.isEmpty() ? null : this.tokens.get(0));
    }

    public function getToken() : Token {
        while(needMoreTokens()) {
            fetchMoreTokens();
        }
        if(!this.tokens.isEmpty()) {
            this.tokensTaken++;
            return this.tokens.removeAtAndReturn(0) as Token;
        }
        return null;
    }

    public function eachToken(scanner : Scanner) : Iterator  {
        return new TokenIterator(scanner);
    }

    public function iterator(scanner : Scanner) : Iterator{
        return eachToken(scanner);
    }

    private function peek(index : int = 0) : String {
        if(this.pointer + 1 > this.buffer.length) {
            update(index + 1);
        }
        return this.buffer.charAt(this.pointer + index);
    }

    private function prefix(length : int) : String {
        
        if(this.pointer+length >= this.buffer.length) update(length);
            
        if(this.pointer+length > this.buffer.length) {
            return this.buffer.substring(this.pointer,this.buffer.length);
        } else {
            return this.buffer.substring(this.pointer,this.pointer+length);
        }
    }

    private function prefixForward(length : int) : String {
        if(this.pointer + length + 1 >= this.buffer.length) {
            update(length+1);
        }
        var buff : String = null;
        if(this.pointer+length > this.buffer.length) {
            buff = this.buffer.substring(this.pointer,this.buffer.length);
        } else {
            buff = this.buffer.substring(this.pointer,this.pointer+length);
        }
        var ch : * = 0;
        for(var i:int=0,j:int=buff.length;i<j;i++) {
            ch = buff.charAt(i);
            this.pointer++;
            if(LINEBR.indexOf(ch) != -1 || (ch == '\r' && buff.charAt(i+1) != '\n')) {
                this.column = 0;
            } else if(ch != '\uFEFF') {
                this.column++;
            }
        }
        return buff;
    }

    private function forward() : void {
        if(this.pointer + 2 >= this.buffer.length) {
            update(2);
        }
        var ch1 : String = this.buffer.charAt(this.pointer);
        this.pointer++;
        if(ch1 == '\n' || ch1 == '\u0085' || (ch1 == '\r' && this.buffer.charAt(this.pointer) != '\n')) {
            this.column = 0;
        } else {
            this.column++;
        }
    }
    
    private function forwardBy(length : int) : void {
        if(this.pointer + length + 1 >= this.buffer.length) {
            update(length+1);
        }
        var ch : * = 0;
        for(var i:int=0;i<length;i++) {
            ch = this.buffer.charAt(this.pointer);
            this.pointer++;
            if(LINEBR.indexOf(ch) != -1 || (ch == '\r' && this.buffer.charAt(this.pointer) != '\n')) {
                this.possibleSimpleKeys.clear();
                this.column = 0;
            } else if(ch != '\uFEFF') {
                this.column++;
            }
        }
    }

    private function checkPrintable(data : String) : void {
        var match : Object = NON_PRINTABLE.exec(data);
        if(match) {
            var position : int = this.buffer.length - this.pointer + match.index;
            throw new YAMLException("At " + position + " we found: " + match.index + ". Special characters are not allowed");
        }
    }

    private function update(length : int) : void {
        this.buffer = this.buffer.substring(this.pointer);
        this.pointer = 0;
        while(this.buffer.length < length) {
            if(!this.eof) {
                var data : String = stream.readString();
                checkPrintable(data);
                this.buffer += data;
                this.buffer += '\x00';
                this.eof = true;
            }
           	else
           	{
           	   break;
           	}

        }
    }

    private function needMoreTokens() : Boolean {
        if(this.done) {
            return false;
        }
        return this.tokens.isEmpty() || nextPossibleSimpleKey() == this.tokensTaken;
    }

    private function fetchMoreTokens() : Token {
        scanToNextToken();
        unwindIndent(this.column);
        var ch : String =  peek();
        var colz :Boolean = this.column == 0;
        switch(ch) {
        case '\x00': return fetchStreamEnd();
        case '\'': return fetchSingle();
        case '"': return fetchDouble();
        case '?': if(this.flowLevel != 0 || NULL_OR_OTHER.indexOf(peek(1)) != -1) { return fetchKey(); } break;
        case ':': if(this.flowLevel != 0 || NULL_OR_OTHER.indexOf(peek(1)) != -1) { return fetchValue(); } break;
        case '%': if(colz) {return fetchDirective(); } break;
        case '-': 
            if((colz || docStart) && (ENDING.exec(prefix(4)))) {
                return fetchDocumentStart(); 
            } else if(NULL_OR_OTHER.indexOf(peek(1)) != -1) {
                return fetchBlockEntry(); 
            }
            break;
        case '.': 
            if(colz && START.exec(prefix(4))) {
                return fetchDocumentEnd(); 
            }
            break;
        case '[': return fetchFlowSequenceStart();
        case '{': return fetchFlowMappingStart();
        case ']': return fetchFlowSequenceEnd();
        case '}': return fetchFlowMappingEnd();
        case ',': return fetchFlowEntry();
        case '*': return fetchAlias();
        case '&': return fetchAnchor();
        case '!': return fetchTag();
        case '|': if(this.flowLevel == 0) { return fetchLiteral(); } break;
        case '>': if(this.flowLevel == 0) { return fetchFolded(); } break;
        }
        if(BEG.exec(prefix(2))) {
            return fetchPlain();
        }
        throw new ScannerException("while scanning for the next token","found character " + ch + "(" + (ch) + " that cannot start any token",null);
    }

    private function nextPossibleSimpleKey() : int {
        for(var iter : Iterator = this.possibleSimpleKeys.values().iterator();iter.hasNext();) {
            var key : SimpleKey = iter.next() as SimpleKey;
            if(key.getTokenNumber() > 0) {
                return key.getTokenNumber();
            }
        }
        return -1;
    }

    private function removePossibleSimpleKey() : void {
        var key : SimpleKey = SimpleKey(this.possibleSimpleKeys.remove(this.flowLevel));
        if(key != null) {
            if(key.isRequired()) {
                throw new ScannerException("while scanning a simple key","could not find expected ':'",null);
            }
        }
    }
    
    private function savePossibleSimpleKey() : void {
        if(this.allowSimpleKey) {
        	this.removePossibleSimpleKey();
            this.possibleSimpleKeys.put(new int(this.flowLevel),new SimpleKey(this.tokensTaken+this.tokens.size(),(this.flowLevel == 0) && this.indent == this.column,-1,-1,this.column));
        }
    }
    
    private function unwindIndent(col : int) : void {
        if(this.flowLevel != 0) {
            return;
        }

        while(this.indent > col) {
            this.indent = ((this.indents.shift()));
            this.tokens.add(Tokens.BLOCK_END);
        }
    }
    
    private function addIndent(col : int) : Boolean {
        if(this.indent < col) {
            this.indents.unshift(new int(this.indent));
            this.indent = col;
            return true;
        }
        return false;
    }

    private function fetchStreamStart() : Token {
        this.docStart = true;
        this.tokens.add(Tokens.STREAM_START);
        return Tokens.STREAM_START;
    }

    private function fetchStreamEnd() : Token {
        unwindIndent(-1);
        this.allowSimpleKey = false;
        this.possibleSimpleKeys = new HashMap();
        this.tokens.add(Tokens.STREAM_END);
        this.done = true;
        return Tokens.STREAM_END;
    }

    private function fetchDirective() : Token {
        unwindIndent(-1);
        this.allowSimpleKey = false;
        var tok : Token = scanDirective();
        this.tokens.add(tok);
        return tok;
    }
    
    private function fetchDocumentStart() : Token {
        this.docStart = false;
        return fetchDocumentIndicator(Tokens.DOCUMENT_START);
    }

    private function fetchDocumentEnd() : Token {
        return fetchDocumentIndicator(Tokens.DOCUMENT_END);
    }

    private function fetchDocumentIndicator(tok : Token) : Token {
        unwindIndent(-1);
        removePossibleSimpleKey();
        this.allowSimpleKey = false;
        forwardBy(3);
        this.tokens.add(tok);
        return tok;
    }
    
    private function fetchFlowSequenceStart() : Token {
        return fetchFlowCollectionStart(Tokens.FLOW_SEQUENCE_START);
    }

    private function fetchFlowMappingStart() : Token {
        return fetchFlowCollectionStart(Tokens.FLOW_MAPPING_START);
    }

    private function fetchFlowCollectionStart(tok : Token) : Token {
        savePossibleSimpleKey();
        this.flowLevel++;
        this.allowSimpleKey = true;
        forwardBy(1);
        this.tokens.add(tok);
        return tok;
    }

    private function fetchFlowSequenceEnd() : Token {
        return fetchFlowCollectionEnd(Tokens.FLOW_SEQUENCE_END);
    }
    
    private function fetchFlowMappingEnd() : Token {
        return fetchFlowCollectionEnd(Tokens.FLOW_MAPPING_END);
    }
    
    private function fetchFlowCollectionEnd(tok : Token) : Token {
        removePossibleSimpleKey();
        this.flowLevel--;
        this.allowSimpleKey = false;
        forwardBy(1);
        this.tokens.add(tok);
        return tok;
    }
    
    private function fetchFlowEntry() : Token {
        this.allowSimpleKey = true;
        removePossibleSimpleKey();
        forwardBy(1);
        this.tokens.add(Tokens.FLOW_ENTRY);
        return Tokens.FLOW_ENTRY;
    }

    private function fetchBlockEntry() : Token {
        if(this.flowLevel == 0) {
            if(!this.allowSimpleKey) {
                throw new ScannerException(null,"sequence entries are not allowed here",null);
            }
            if(addIndent(this.column)) {
                this.tokens.add(Tokens.BLOCK_SEQUENCE_START);
            }
        }
        this.allowSimpleKey = true;
        removePossibleSimpleKey();
        forward();
        this.tokens.add(Tokens.BLOCK_ENTRY);
        return Tokens.BLOCK_ENTRY;
    }        

    private function fetchKey() : Token {
        if(this.flowLevel == 0) {
            if(!this.allowSimpleKey) {
                throw new ScannerException(null,"mapping keys are not allowed here",null);
            }
            if(addIndent(this.column)) {
                this.tokens.add(Tokens.BLOCK_MAPPING_START);
            }
        }
        this.allowSimpleKey = this.flowLevel == 0;
        removePossibleSimpleKey();
        forward();
        this.tokens.add(Tokens.KEY);
        return Tokens.KEY;
    }

    private function fetchValue() : Token {
    	this.docStart = false;
        var key : SimpleKey = this.possibleSimpleKeys.get(this.flowLevel);
        if(null == key) {
            if(this.flowLevel == 0 && !this.allowSimpleKey) {
                throw new ScannerException(null,"mapping values are not allowed here",null);
            }
            this.allowSimpleKey = (this.flowLevel == 0);
            removePossibleSimpleKey();
        } else {
            this.possibleSimpleKeys.remove(new int(this.flowLevel));
            this.tokens.addAt(key.getTokenNumber()-this.tokensTaken,Tokens.KEY);
            if(this.flowLevel == 0 && addIndent(key.getColumn())) {
                this.tokens.addAt(key.getTokenNumber()-this.tokensTaken,Tokens.BLOCK_MAPPING_START);
            }
            this.allowSimpleKey = false;
        }
        forward();
        this.tokens.add(Tokens.VALUE);
        return Tokens.VALUE;
    }

    private function fetchAlias() : Token {
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanAnchor(new AliasToken());
        this.tokens.add(tok);
        return tok;
    }

    private function fetchAnchor() : Token {
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanAnchor(new AnchorToken());
        this.tokens.add(tok);
        return tok;
    }

    private function fetchTag() : Token {
    	this.docStart = false;
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanTag();
        this.tokens.add(tok);
        return tok;
    }
    
    private function fetchLiteral() : Token {
        return fetchBlockScalar('|');
    }
    
    private function fetchFolded() : Token {
        return fetchBlockScalar('>');
    }
    
    private function fetchBlockScalar(style : String) : Token {
        this.allowSimpleKey = true;
        this.removePossibleSimpleKey();
        var tok : Token = scanBlockScalar(style);
        this.tokens.add(tok);
        return tok;
    }
    
    private function fetchSingle() : Token {
        return fetchFlowScalar('\'');
    }
    
    private function fetchDouble() : Token {
        return fetchFlowScalar('"');
    }
    
    private function fetchFlowScalar(style : String) : Token {
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanFlowScalar(style);
        this.tokens.add(tok);
        return tok;
    }
    
    private function fetchPlain() : Token {
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanPlain();
        this.tokens.add(tok);
        return tok;
    }
    
    private function scanToNextToken() : void {
        for(;;) {
            while(peek() == ' ') {
                forward();
            }
            if(peek() == '#') {
                while(NULL_OR_LINEBR.indexOf(peek()) == -1) {
                    forward();
                }
            }
            if(scanLineBreak().length != 0 ) {
                if(this.flowLevel == 0) {
                    this.allowSimpleKey = true;
                }
            } else {
                break;
            }
        }
    }
    
    private function scanDirective() : Token {
        forward();
        var name : String = scanDirectiveName();
        var value : Array = null;
        if(name == ("YAML")) {
            value = scanYamlDirectiveValue();
        } else if(name == ("TAG")) {
            value = scanTagDirectiveValue();
        } else {
            while(NULL_OR_LINEBR.indexOf(peek()) == -1) {
                forward();
            }
        }
        scanDirectiveIgnoredLine();
        return new DirectiveToken(name,value);
    }
    
    private function scanDirectiveName() : String {
        var length : int = 0;
        var ch : String = peek(length);
        var zlen : Boolean = true;
        while(ALPHA.indexOf(ch) != -1) {
            zlen = false;
            length++;
            ch = peek(length);
        }
        if(zlen) {
            throw new ScannerException("while scanning a directive","expected alphabetic or numeric character, but found " + ch + "(" + (ch) + ")",null);
        }
        var value : String = prefixForward(length);
        //        forward(length);
        if(NULL_BL_LINEBR.indexOf(peek()) == -1) {
            throw new ScannerException("while scanning a directive","expected alphabetic or numeric character, but found " + ch + "(" + (ch) + ")",null);
        }
        return value;
    }

    private function scanYamlDirectiveValue() : Array {
        while(peek() == ' ') {
            forward();
        }
        var major : String = scanYamlDirectiveNumber();
        if(peek() != '.') {
            throw new ScannerException("while scanning a directive","expected a digit or '.', but found " + peek() + "(" + (peek()) + ")",null);
        }
        forward();
        var minor : String = scanYamlDirectiveNumber();
        if(NULL_BL_LINEBR.indexOf(peek()) == -1) {
            throw new ScannerException("while scanning a directive","expected a digit or ' ', but found " + peek() + "(" + (peek()) + ")",null);
        }
        return [major,minor];
    }

    private function scanYamlDirectiveNumber() : String {
        var ch : String = peek();
        if(!StringUtils.isDigit(ch)) {
            throw new ScannerException("while scanning a directive","expected a digit, but found " + ch + "(" + (ch) + ")",null);
        }
        var length : int = 0;
        while(StringUtils.isDigit(peek(length))) {
            length++;
        }
        var value : String = prefixForward(length);
        //        forward(length);
        return value;
    }

    private function scanTagDirectiveValue() : Array  {
        while(peek() == ' ') {
            forward();
        }
        var handle : String = scanTagDirectiveHandle();
        while(peek() == ' ') {
            forward();
        }
        var prefix : String = scanTagDirectivePrefix();
        return [handle,prefix];
    }

    private function scanTagDirectiveHandle() : String {
        var value : String = scanTagHandle("directive");
        if(peek() != ' ') {
            throw new ScannerException("while scanning a directive","expected ' ', but found " + peek() + "(" + (peek()) + ")",null);
        }
        return value;
    }
    
    private function scanTagDirectivePrefix() : String {
        var value : String = scanTagUri("directive");
        if(NULL_BL_LINEBR.indexOf(peek()) == -1) {
            throw new ScannerException("while scanning a directive","expected ' ', but found " + peek() + "(" + (peek()) + ")",null);
        }
        return value;
    }

    private function scanDirectiveIgnoredLine() : String {
        while(peek() == ' ') {
            forward();
        }
        if(peek() == '"') {
            while(NULL_OR_LINEBR.indexOf(peek()) == -1) {
                forward();
            }
        }
        var ch : String = peek();
        if(NULL_OR_LINEBR.indexOf(ch) == -1) {
            throw new ScannerException("while scanning a directive","expected a comment or a line break, but found " + peek() + "(" + (peek()) + ")",null);
        }
        return scanLineBreak();
    }

    private function scanAnchor(tok : Token) : Token {
        var indicator : String = peek();
        var name : String = indicator == '*' ? "alias" : "anchor";
        forward();
        var length : int = 0;
        var chunk_size : int = 16;
        var match : Object;
        for(;;) {
            var chunk : String = prefix(chunk_size);
            if((match = NON_ALPHA.exec(chunk))) {
                break;
            }
            chunk_size+=16;
        }
        length = match.index;
        if(length == 0) {
            throw new ScannerException("while scanning an " + name,"expected alphabetic or numeric character, but found something else...",null);
        }
        var value : String = prefixForward(length);
        //        forward(length);
        if(NON_ALPHA_OR_NUM.indexOf(peek()) == -1) {
            throw new ScannerException("while scanning an " + name,"expected alphabetic or numeric character, but found "+ peek() + "(" + (peek()) + ")",null);

        }
        tok.setValue(value);
        return tok;
    }

    private function scanTag() : Token {
        var ch : String = peek(1);
        var handle : String = null;
        var suffix : String = null;
        if(ch == '<') {
            forwardBy(2);
            suffix = scanTagUri("tag");
            if(peek() != '>') {
                throw new ScannerException("while scanning a tag","expected '>', but found "+ peek() + "(" + (peek()) + ")",null);
            }
            forward();
        } else if(NULL_BL_T_LINEBR.indexOf(ch) != -1) {
            suffix = "!";
            forward();
        } else {
            var length : int = 1;
            var useHandle : Boolean = false;
            while(NULL_BL_T_LINEBR.indexOf(ch) == -1) {
                if(ch == '!') {
                    useHandle = true;
                    break;
                }
                length++;
                ch = peek(length);
            }
            handle = "!";
            if(useHandle) {
                handle = scanTagHandle("tag");
            } else {
                handle = "!";
                forward();
            }
            suffix = scanTagUri("tag");
        }
        if(NULL_BL_LINEBR.indexOf(peek()) == -1) {
            throw new ScannerException("while scanning a tag","expected ' ', but found " + peek() + "(" + (peek()) + ")",null);
        }
        return new TagToken([handle,suffix]);
    }

    private function scanBlockScalar(style : String) : ScalarToken {
        var folded : Boolean = style == '>';
        var chunks : String = new String();
        forward();
        var chompi : Array = scanBlockScalarIndicators();
        var chomping : Boolean = Boolean(chompi[0])
        var increment : int = (int(chompi[1]));
        scanBlockScalarIgnoredLine();
        var minIndent : int = this.indent+1;
        if(minIndent < 1) {
            minIndent = 1;
        }
        var breaks : String = null;
        var maxIndent : int = 0;
        var ind : int = 0;
        if(increment == -1) {
            var brme : Array = scanBlockScalarIndentation();
            breaks = String(brme[0]);
            maxIndent = (int(brme[1]))
            if(minIndent > maxIndent) {
                ind = minIndent;
            } else {
                ind = maxIndent;
            }
        } else {
            ind = minIndent + increment - 1;
            breaks = scanBlockScalarBreaks(ind);
        }

        var lineBreak : String = "";
        while(this.column == ind && peek() != '\x00') {
            chunks += breaks;
            var leadingNonSpace : Boolean = BLANK_T.indexOf(peek()) == -1;
            var length : int = 0;
            while(NULL_OR_LINEBR.indexOf(peek(length))==-1) {
                length++;
            }
            chunks += prefixForward(length);
            //            forward(length);
            lineBreak = scanLineBreak();
            breaks = scanBlockScalarBreaks(ind);
            if(this.column == ind && peek() != '\x00') {
                if(folded && lineBreak == ("\n") && leadingNonSpace && BLANK_T.indexOf(peek()) == -1) {
                    if(breaks.length == 0) {
                        chunks += " ";
                    }
                } else {
                    chunks += lineBreak;
                }
            } else {
                break;
            }
        }

        if(chomping) {
            chunks += lineBreak;
            chunks += breaks;
        }

        return new ScalarToken(chunks,false,style);
    }

    private function scanBlockScalarIndicators() : Array {
        var chomping : Boolean = false;
        var increment : int = -1;
        var ch : String = peek();
        if(ch == '-' || ch == '+') {
            chomping = ch == '+';
            forward();
            ch = peek();
            if(StringUtils.isDigit(ch)) {
                increment = int(ch);
                if(increment == 0) {
                    throw new ScannerException("while scanning a block scalar","expected indentation indicator in the range 1-9, but found 0",null);
                }
                forward();
            }
        } else if(StringUtils.isDigit(ch)) {
            increment = int(ch);
            if(increment == 0) {
                throw new ScannerException("while scanning a block scalar","expected indentation indicator in the range 1-9, but found 0",null);
            }
            forward();
            ch = peek();
            if(ch == '-' || ch == '+') {
                chomping = ch == '+';
                forward();
            }
        }
        if(NULL_BL_LINEBR.indexOf(peek()) == -1) {
            throw new ScannerException("while scanning a block scalar","expected chomping or indentation indicators, but found " + peek() + "(" + (peek()) + ")",null);
        }
        return [chomping, increment];
}

    private function scanBlockScalarIgnoredLine() : String {
        while(peek() == ' ') {
            forward();
        }
        if(peek() == '#') {
            while(NULL_OR_LINEBR.indexOf(peek()) == -1) {
                forward();
            }
        }
        if(NULL_OR_LINEBR.indexOf(peek()) == -1) {
            throw new ScannerException("while scanning a block scalar","expected a comment or a line break, but found " + peek() + "(" + (peek()) + ")",null);
        }
        return scanLineBreak();
    }

    private function scanBlockScalarIndentation() : Array {
        var chunks : String = new String();
        var maxIndent : int = 0;
        while(BLANK_OR_LINEBR.indexOf(peek()) != -1) {
            if(peek() != ' ') {
                chunks += scanLineBreak();
            } else {
                forward();
                if(this.column > maxIndent) {
                    maxIndent = column;
                }
            }
        }
        return [chunks, maxIndent];
    }

    private function scanBlockScalarBreaks(indent : int) : String {
        var chunks : String = new String();
        while(this.column < indent && peek() == ' ') {
            forward();
        }
        while(FULL_LINEBR.indexOf(peek()) != -1) {
            chunks += scanLineBreak();
            while(this.column < indent && peek() == ' ') {
                forward();
            }
        }
        return chunks;
    }

    private function scanFlowScalar(style : String) : Token {
        var dbl : Boolean = style == '"';
        var chunks : String = new String();
        var quote : String = peek();
        forward();
        chunks += scanFlowScalarNonSpaces(dbl);
        while(peek() != quote) {
            chunks += scanFlowScalarSpaces();
            chunks += scanFlowScalarNonSpaces(dbl);
        }
        forward();
               
        return new ScalarToken(chunks,false,style);
    }

    private function scanFlowScalarNonSpaces(dbl : Boolean) : * {
        var chunks : String = new String();
        for(;;) {
            var length : int = 0;
            while(SPACES_AND_STUFF.indexOf(peek(length)) == -1) {
                length++;
            }
            if(length != 0) {
                chunks += (prefixForward(length));
                //                forward(length);
            }
            var ch : String = peek();
            if(!dbl && ch == '\'' && peek(1) == '\'') {
                chunks += ("'");
                forwardBy(2);
            } else if((dbl && ch == '\'') || (!dbl && DOUBLE_ESC.indexOf(ch) != -1)) {
                chunks += ch;
                forward();
            } else if(dbl && ch == '\\') {
                forward();
                ch = peek();
                if(ESCAPE_REPLACEMENTS.containsKey(ch)) {
                    chunks += ESCAPE_REPLACEMENTS.get(ch);
                    forward(); 
                } else if(ESCAPE_CODES.containsKey(ch)) {
                    length = (ESCAPE_CODES.get(ch));
                    forward();
                    var val : String = prefix(length);
                    if(NOT_HEXA.exec(val)) {
                        throw new ScannerException("while scanning a double-quoted scalar","expected escape sequence of " + length + " hexadecimal numbers, but found something else: " + val,null);
                    }
                    var charCode : int = parseInt(val, 16);
                    var char : String = String.fromCharCode(charCode);
                    chunks += char;
                    forwardBy(length);
                } else if(FULL_LINEBR.indexOf(ch) != -1) {
                    scanLineBreak();
                    chunks += scanFlowScalarBreaks();
                } else {
                    throw new ScannerException("while scanning a double-quoted scalar","found unknown escape character " + ch + "(" + (ch) + ")",null);
                }
            } else {
                return chunks;
            }
        }
    }

    private function scanFlowScalarSpaces() : String {
        var chunks : String = new String();
        var length : int = 1;
        while(BLANK_T.indexOf(peek(length)) != -1) {
            length++;
        }
        var whitespaces : String = prefixForward(length);
        //        forward(length);
        var ch : String = peek();
        if(ch == '\x00') {
            throw new ScannerException("while scanning a quoted scalar","found unexpected end of stream",null);
        } else if(FULL_LINEBR.indexOf(ch) != -1) {
            var lineBreak : String = scanLineBreak();
            var breaks : String = scanFlowScalarBreaks();
            if(!lineBreak == ("\n")) {
                chunks += lineBreak;
            } else if(breaks.length == 0) {
                chunks += " ";
            }
            chunks += breaks;
        } else {
            chunks += whitespaces;
        }
        return chunks;
    }

    private function scanFlowScalarBreaks() : * {
        var chunks : String = new String();
        var pre : String = null;
        for(;;) {
            pre = prefix(3);
            if((pre == ("---") || pre == ("...")) && NULL_BL_T_LINEBR.indexOf(peek(3)) != -1) {
                throw new ScannerException("while scanning a quoted scalar","found unexpected document separator",null);
            }
            while(BLANK_T.indexOf(peek()) != -1) {
                forward();
            }
            if(FULL_LINEBR.indexOf(peek()) != -1) {
                chunks += scanLineBreak();
            } else {
                return chunks;
            }            
        }
    }


    private function scanPlain() : Token {
        /*
       See the specification for details.
       We add an additional restriction for the flow context:
         plain scalars in the flow context cannot contain ',', ':' and '?'.
       We also keep track of the `allow_simple_key` flag here.
       Indentation rules are loosed for the flow context.
         */
        var chunks : String = new String();
        var ind : int = this.indent+1;
        var spaces : String = "";
        var f_nzero : Boolean = true;
        var r_check : RegExp = R_FLOWNONZERO;
        if(this.flowLevel == 0) {
            f_nzero = false;
            r_check = R_FLOWZERO;
        }
        while(peek() != '#') {
            var length : int = 0;
            var chunkSize : int = 32;
            var match : Object;
            while(!(match = r_check.exec(prefix(chunkSize)))) {
                chunkSize += 32;
            }
            length = match.index;
            var ch : String = peek(length);
            if(f_nzero && ch == ':' && S4.indexOf(peek(length+1)) == -1) {
                forwardBy(length);
                throw new ScannerException("while scanning a plain scalar","found unexpected ':'","Please check http://pyyaml.org/wiki/YAMLColonInFlowContext for details.");
            }
            if(length == 0) {
                break;
            }
            this.allowSimpleKey = false;
            chunks += spaces;
            chunks += prefixForward(length);

            spaces = scanPlainSpaces(ind);
            if(spaces == null || (this.flowLevel == 0 && this.column < ind)) {
                break;
            }
        }
        return new ScalarToken(chunks,true);
    }

    private function scanPlainSpaces(indent : int) : String {
        var chunks : String = new String();
        var length : int = 0;
        while(peek(length) == ' ') {
            length++;
        }
        var whitespaces : String = prefixForward(length);
        //        forward(length);
        var ch : String  = peek();
        if(FULL_LINEBR.indexOf(ch) != -1) {
            var lineBreak : String = scanLineBreak();
            this.allowSimpleKey = true;
            if(END_OR_START.exec(prefix(4))) {
                return "";
            }
            var breaks : String = new String();
            while(BLANK_OR_LINEBR.indexOf(peek()) != -1) {
                if(' ' == peek()) {
                    forward();
                } else {
                    breaks += scanLineBreak();
                    if(END_OR_START.exec(prefix(4))) {
                        return "";
                    }
                }
            }            
            if(!lineBreak == ("\n")) {
                chunks += lineBreak;
            } else if(breaks == null || breaks.toString() == ("")) {
                chunks += " ";
            }
            chunks += breaks;
        } else {
            chunks += whitespaces;
        }
        return chunks;
    }

    private function scanTagHandle(name : String) : String {
        var ch : String =  peek();
        if(ch != '!') {
            throw new ScannerException("while scanning a " + name,"expected '!', but found " + ch + "(" + (ch) + ")",null);
        }
        var length : int = 1;
        ch = peek(length);
        if(ch != ' ') {
            while(ALPHA.indexOf(ch) != -1) {
                length++;
                ch = peek(length);
            }
            if('!' != ch) {
                forwardBy(length);
                throw new ScannerException("while scanning a " + name,"expected '!', but found " + ch + "(" + (ch) + ")",null);
            }
            length++;
        }
        var value :String = prefixForward(length);

        return value;
    }

    private function scanTagUri(name : String) : String {
        var chunks : String = new String();
        var length : int = 0;
        var ch : String = peek(length);
        while(STRANGE_CHAR.indexOf(ch) != -1) {
            if('%' == ch) {
                chunks += prefixForward(length);
                length = 0;
                chunks += scanUriEscapes(name);
            } else {
                length++;
            }
            ch = peek(length);
        }
        if(length != 0) {
            chunks += (prefixForward(length));
        }

        if(chunks.length == 0) {
            throw new ScannerException("while scanning a " + name,"expected URI, but found " + ch + "(" + (ch) + ")",null);
        }
        return chunks;
    }

    private function scanUriEscapes(name : String) : String {
        var bytes : String = new String();
        while(peek() == '%') {
            forward();
            try {
                bytes += int(prefix(2)).toString(16);
            } catch(nfe : Error) {
                throw new ScannerException("while scanning a " + name,"expected URI escape sequence of 2 hexadecimal numbers, but found " + peek(1) + "(" + (peek(1)) + ") and "+ peek(2) + "(" + (peek(2)) + ")",null);
            }
            forwardBy(2);
        }
        return bytes
    }

    private function scanLineBreak() : String {
        // Transforms:
        //   '\r\n'      :   '\n'
        //   '\r'        :   '\n'
        //   '\n'        :   '\n'
        //   '\x85'      :   '\n'
        //   default     :   ''
        var val : String = peek();
        if(FULL_LINEBR.indexOf(val) != -1) {
            if(RN == (prefix(2))) {
                forwardBy(2);
            } else {
                forward();
            }
            return "\n";
        } else {
            return "";
        }
    }

}
}

import org.idmedia.as3commons.util.Iterator;
import org.as3yaml.Scanner;
	
internal class TokenIterator implements Iterator {
	
	private var scanner : Scanner;
	
	public function TokenIterator(scanner : Scanner) : void
	{
		this.scanner = scanner;
	}
	
    public function hasNext() : Boolean {
        return null != scanner.peekToken();
    }

    public function next() : * {
        return scanner.getToken();
    }

    public function remove() : void {
    }
}