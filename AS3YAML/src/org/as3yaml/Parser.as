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

import flash.utils.Dictionary;
import flash.utils.getQualifiedClassName;

import org.as3yaml.events.*;
import org.as3yaml.tokens.*;

public class Parser {
    // Memnonics for the production table
    private const P_STREAM: int = 0;
    private const P_STREAM_START: int = 1; // TERMINAL
    private const P_STREAM_END: int = 2; // TERMINAL
    private const P_IMPLICIT_DOCUMENT: int = 3;
    private const P_EXPLICIT_DOCUMENT: int = 4;
    private const P_DOCUMENT_START: int = 5;
    private const P_DOCUMENT_START_IMPLICIT: int = 6;
    private const P_DOCUMENT_END: int = 7;
    private const P_BLOCK_NODE: int = 8;
    private const P_BLOCK_CONTENT: int = 9;
    private const P_PROPERTIES: int = 10;
    private const P_PROPERTIES_END: int = 11;
    private const P_FLOW_CONTENT: int = 12;
    private const P_BLOCK_SEQUENCE: int = 13;
    private const P_BLOCK_MAPPING: int = 14;
    private const P_FLOW_SEQUENCE: int = 15;
    private const P_FLOW_MAPPING: int = 16;
    private const P_SCALAR: int = 17;
    private const P_BLOCK_SEQUENCE_ENTRY: int = 18;
    private const P_BLOCK_MAPPING_ENTRY: int = 19;
    private const P_BLOCK_MAPPING_ENTRY_VALUE: int = 20;
    private const P_BLOCK_NODE_OR_INDENTLESS_SEQUENCE: int = 21;
    private const P_BLOCK_SEQUENCE_START: int = 22;
    private const P_BLOCK_SEQUENCE_END: int = 23;
    private const P_BLOCK_MAPPING_START: int = 24;
    private const P_BLOCK_MAPPING_END: int = 25;
    private const P_INDENTLESS_BLOCK_SEQUENCE: int = 26;
    private const P_BLOCK_INDENTLESS_SEQUENCE_START: int = 27;
    private const P_INDENTLESS_BLOCK_SEQUENCE_ENTRY: int = 28;
    private const P_BLOCK_INDENTLESS_SEQUENCE_END: int = 29;
    private const P_FLOW_SEQUENCE_START: int = 30;
    private const P_FLOW_SEQUENCE_ENTRY: int = 31;
    private const P_FLOW_SEQUENCE_END: int = 32;
    private const P_FLOW_MAPPING_START: int = 33;
    private const P_FLOW_MAPPING_ENTRY: int = 34;
    private const P_FLOW_MAPPING_END: int = 35;
    private const P_FLOW_INTERNAL_MAPPING_START: int = 36;
    private const P_FLOW_INTERNAL_CONTENT: int = 37;
    private const P_FLOW_INTERNAL_VALUE: int = 38;
    private const P_FLOW_INTERNAL_MAPPING_END: int = 39;
    private const P_FLOW_ENTRY_MARKER: int = 40;
    private const P_FLOW_NODE: int = 41;
    private const P_FLOW_MAPPING_INTERNAL_CONTENT: int = 42;
    private const P_FLOW_MAPPING_INTERNAL_VALUE: int = 43;
    private const P_ALIAS: int = 44;
    private const P_EMPTY_SCALAR: int = 45;

    private var DOCUMENT_END_TRUE: Event  = new DocumentEndEvent(true);
    private var DOCUMENT_END_FALSE: Event  = new DocumentEndEvent(false);
    private var MAPPING_END: Event  = new MappingEndEvent();
    private var SEQUENCE_END: Event  = new SequenceEndEvent();
    private var STREAM_END: Event  = new StreamEndEvent();
    private var STREAM_START: Event  = new StreamStartEvent();

    private const P_TABLE : Array = [];

    private var DEFAULT_TAGS_1_0 : Dictionary = new Dictionary();
    private var DEFAULT_TAGS_1_1 : Dictionary = new Dictionary();
	
	private var ONLY_WORD : RegExp = new RegExp("^\\w+$");

    private var tags:Array;
    private var anchors:Array;
    private var tagHandles:Object;
    private var yamlVersion:Array;
    private var defaultYamlVersion:Array;

	
   public function produce(eventId: int) : Event {
   	
   		switch (eventId)
   		{
	        case P_STREAM:
	            parseStack.unshift(P_STREAM_END);
	            parseStack.unshift(P_EXPLICIT_DOCUMENT);
	            parseStack.unshift(P_IMPLICIT_DOCUMENT);
	            parseStack.unshift(P_STREAM_START);
	            return null;
	        
	        case P_STREAM_START:
	        	scanner.getToken();
				return STREAM_START;
			
			case P_STREAM_END:
	            scanner.getToken();
	            return STREAM_END;
	            
	        case P_IMPLICIT_DOCUMENT:
	            var curr : Token = scanner.peekToken();
	            if(!(curr is DirectiveToken || curr is DocumentStartToken || curr is StreamEndToken)) {
	                parseStack.unshift(P_DOCUMENT_END);
	                parseStack.unshift(P_BLOCK_NODE);
	                parseStack.unshift(P_DOCUMENT_START_IMPLICIT);
	            }
	            return null;
	        
	        case P_EXPLICIT_DOCUMENT:
	            if(!(scanner.peekToken() is StreamEndToken)) {
	                parseStack.unshift(P_EXPLICIT_DOCUMENT);
	                parseStack.unshift(P_DOCUMENT_END);
	                parseStack.unshift(P_BLOCK_NODE);
	                parseStack.unshift(P_DOCUMENT_START);
	            }
	            return null;
	       
	       case P_DOCUMENT_START:
	            var tok : Token = scanner.peekToken();
	            var directives : Array = processDirectives(scanner);
	            if(!(scanner.peekToken() is DocumentStartToken)) {
	                throw new ParserException(null,"expected '<document start>', but found " + tok, "line number: " + scanner.productionLineNumber());
	            }
	            scanner.getToken();
	            return new DocumentStartEvent(true, directives[0], directives[1]);
	       
	       case P_DOCUMENT_START_IMPLICIT:
                var directives : Array = processDirectives(scanner);
                return new DocumentStartEvent(false,directives[0], directives[1]);	       
	       
	       case P_DOCUMENT_END:
	            var tok : Token = scanner.peekToken();
	            var explicit : Boolean = false;
	            while(scanner.peekToken() is DocumentEndToken) {
	                scanner.getToken();
	                explicit = true;
	            }
	            return explicit ? DOCUMENT_END_TRUE : DOCUMENT_END_FALSE;
	       
	       case P_BLOCK_NODE:
                var curr : Token = scanner.peekToken();
                if(curr is DirectiveToken || curr is DocumentStartToken || curr is DocumentEndToken || curr is StreamEndToken) {
                    parseStack.unshift(P_EMPTY_SCALAR);
                } else {
                    if(curr is AliasToken) {
                        parseStack.unshift(P_ALIAS);
                    } else {
                        parseStack.unshift(P_PROPERTIES_END);
                        parseStack.unshift(P_BLOCK_CONTENT);
                        parseStack.unshift(P_PROPERTIES);
                    }
                }
                return null;
           
           case P_BLOCK_CONTENT:
                var tok : Token = scanner.peekToken();
                if(tok is BlockSequenceStartToken) {
                    parseStack.unshift(P_BLOCK_SEQUENCE);
                } else if(tok is BlockMappingStartToken) {
                    parseStack.unshift(P_BLOCK_MAPPING);
                } else if(tok is FlowSequenceStartToken) {
                    parseStack.unshift(P_FLOW_SEQUENCE);
                } else if(tok is FlowMappingStartToken) {
                    parseStack.unshift(P_FLOW_MAPPING);
                } else if(tok is ScalarToken) {
                    parseStack.unshift(P_SCALAR);
                } else {
                    return new ScalarEvent(anchors[0],tags[0],[false,false],null,'\'');
                }
                return null;
           
           case P_PROPERTIES:
                var anchor : String = null;
                var tokValue : Array  = null;
                var tag: String = null;
                if(scanner.peekToken() is AnchorToken) {
                    anchor = AnchorToken(scanner.getToken()).getValue();
                    if(scanner.peekToken() is TagToken) {
                        scanner.getToken();
                    }
                } else if(scanner.peekToken() is TagToken) {
                    tokValue = TagToken(scanner.getToken()).getValue();
                    if(scanner.peekToken() is AnchorToken) {
                        anchor = AnchorToken(scanner.getToken()).getValue();
                    }
                }
                if(tokValue != null) {
                    var handle : String = tokValue[0];
                    var suffix : String = tokValue[1];
                    var ix : int = -1;
//                    if((ix = suffix.indexOf("^")) != -1) {
//                        suffix = suffix.substring(0,ix) + suffix.substring(ix+1);
//                    }
//                    if(handle != null) {
//                        if(!env.getTagHandles().containsKey(handle)) {
//                            throw new ParserException("while parsing a node","found undefined tag handle " + handle, "line number: " + scanner.productionLineNumber());
//                        }
//                        if((ix = suffix.indexOf("/")) != -1) {
//                            var before : String = suffix.substring(0,ix);
//                            var after : String = suffix.substring(ix+1);
//                            if(ONLY_WORD.exec(before)) {
//                                tag = "tag:" + before + ".yaml.org,2002:" + after;
//                            } else {
//                                if(StringUtils.startsWith(before, "tag:")) {
//                                    tag = before + ":" + after;
//                                } else {
//                                    tag = "tag:" + before + ":" + after;
//                                }
//                            }
//                        } else {
                            tag = (tagHandles[handle]) + suffix;
//                        }
                        
                    } else {
                        tag = suffix;
                    }

                anchors.unshift(anchor);
                tags.unshift(tag);
                return null;           
           
	        case P_PROPERTIES_END:
            	anchors.shift();
                tags.shift();
                return null;
	            
	        case P_FLOW_CONTENT:
                var tok : Token = scanner.peekToken();
                if(tok is FlowSequenceStartToken) {
                    parseStack.unshift(P_FLOW_SEQUENCE);
                } else if(tok is FlowMappingStartToken) {
                    parseStack.unshift(P_FLOW_MAPPING);
                } else if(tok is ScalarToken) {
                    parseStack.unshift(P_SCALAR);
                } else {
                    throw new ParserException("while scanning a flow node","expected the node content, but found " + tok, "line number: " + scanner.productionLineNumber());
                }
                return null;
	            
	       case P_BLOCK_SEQUENCE:
                parseStack.unshift(P_BLOCK_SEQUENCE_END);
                parseStack.unshift(P_BLOCK_SEQUENCE_ENTRY);
                parseStack.unshift(P_BLOCK_SEQUENCE_START);
                return null;
	            
	       case P_BLOCK_MAPPING:
                parseStack.unshift(P_BLOCK_MAPPING_END);
                parseStack.unshift(P_BLOCK_MAPPING_ENTRY);
                parseStack.unshift(P_BLOCK_MAPPING_START);
                return null;
	            
	       case P_FLOW_SEQUENCE:
                parseStack.unshift(P_FLOW_SEQUENCE_END);
                parseStack.unshift(P_FLOW_SEQUENCE_ENTRY);
                parseStack.unshift(P_FLOW_SEQUENCE_START);
                return null;
	            
	       case P_FLOW_MAPPING:
                parseStack.unshift(P_FLOW_MAPPING_END);
                parseStack.unshift(P_FLOW_MAPPING_ENTRY);
                parseStack.unshift(P_FLOW_MAPPING_START);
                return null;
	            
	       case P_SCALAR:
                var token : ScalarToken = scanner.getToken() as ScalarToken;
                var implicit : Array = null;
                if((token.getPlain() && tags[0] == null) || "!" == (tags[0])) {
                    implicit = [true,false];
                } else if(tags[0] == null) {
                    implicit = [false,true];
                } else {
                    implicit = [false,false];
                }
                return new ScalarEvent(anchors[0],tags[0],implicit,token.getValue(),token.getStyle());
	            
	       case P_BLOCK_SEQUENCE_ENTRY:
                if(scanner.peekToken() is BlockEntryToken) {
                    scanner.getToken();
                    var curr: Token = scanner.peekToken();
                    if(!(curr is BlockEntryToken || curr is BlockEndToken)) {
                        parseStack.unshift(P_BLOCK_SEQUENCE_ENTRY);
                        parseStack.unshift(P_BLOCK_NODE);
                    } else {
                        parseStack.unshift(P_BLOCK_SEQUENCE_ENTRY);
                        parseStack.unshift(P_EMPTY_SCALAR);
                    }
                }
                return null;
	            
	       case P_BLOCK_MAPPING_ENTRY:
                var last : Token = scanner.peekToken();
                if(last is KeyToken || last is ValueToken) {
                    if(last is KeyToken) {
                        scanner.getToken();
                        var curr : Token = scanner.peekToken();
                        if(!(curr is KeyToken || curr is ValueToken || curr is BlockEndToken)) {
                            parseStack.unshift(P_BLOCK_MAPPING_ENTRY);
                            parseStack.unshift(P_BLOCK_MAPPING_ENTRY_VALUE);
                            parseStack.unshift(P_BLOCK_NODE_OR_INDENTLESS_SEQUENCE);
                        } else {
                            parseStack.unshift(P_BLOCK_MAPPING_ENTRY);
                            parseStack.unshift(P_BLOCK_MAPPING_ENTRY_VALUE);
                            parseStack.unshift(P_EMPTY_SCALAR);
                        }
                    } else {
                        parseStack.unshift(P_BLOCK_MAPPING_ENTRY);
                        parseStack.unshift(P_BLOCK_MAPPING_ENTRY_VALUE);
                        parseStack.unshift(P_EMPTY_SCALAR);
                    }
                }
                return null;
	            
	       case P_BLOCK_MAPPING_ENTRY_VALUE:
                var last: Token = scanner.peekToken();
                if (last is KeyToken || last is ValueToken) {
                    if(last is ValueToken) {
                        scanner.getToken();
                        var curr : Token = scanner.peekToken();
                        if(!(curr is KeyToken || curr is ValueToken || curr is BlockEndToken)) {
                            parseStack.unshift(P_BLOCK_NODE_OR_INDENTLESS_SEQUENCE);
                        } else {
                            parseStack.unshift(P_EMPTY_SCALAR);
                        }
                    } else {
                        parseStack.unshift(P_EMPTY_SCALAR);
                    }
                }

                return null;
	            
	       case P_BLOCK_NODE_OR_INDENTLESS_SEQUENCE:
                var last: Token = scanner.peekToken();
                if(last is AliasToken) {
                    parseStack.unshift(P_ALIAS);
                } else {
                    if(last is BlockEntryToken) {
                        parseStack.unshift(P_INDENTLESS_BLOCK_SEQUENCE);
                        parseStack.unshift(P_PROPERTIES);
                    } else {
                        parseStack.unshift(P_BLOCK_CONTENT);
                        parseStack.unshift(P_PROPERTIES);
                    }
                }
                return null;
	            
	       case P_BLOCK_SEQUENCE_START:
                var impl : Boolean = tags[0] == null || tags[0] == "!";
                scanner.getToken();
                return new SequenceStartEvent(anchors[0], tags[0], impl,false);
	            
	       case P_BLOCK_SEQUENCE_END:
                var tok : Token = null;
                if(!(scanner.peekToken() is BlockEndToken)) {
                    tok = scanner.peekToken();
                    throw new ParserException("while scanning a block collection","expected <block end>, but found " + tok, "line number: " + scanner.productionLineNumber());
                }
                scanner.getToken();
                return SEQUENCE_END;
	            
	       case P_BLOCK_MAPPING_START:
                var impl : Boolean = tags[0] == null || tags[0] == "!";
                scanner.getToken();
                return new MappingStartEvent(anchors[0], tags[0], impl,false);
	            
	       case P_BLOCK_MAPPING_END:
                var tok : Token = scanner.peekToken();
                if(!(tok is BlockEndToken)) {
                    throw new ParserException("while scanning a block mapping","expected <block end>, but found " + tok, "line number: " + scanner.productionLineNumber());
                }
                scanner.getToken();
                return MAPPING_END;
	            
	       case P_INDENTLESS_BLOCK_SEQUENCE:
                parseStack.unshift(P_BLOCK_INDENTLESS_SEQUENCE_END);
                parseStack.unshift(P_INDENTLESS_BLOCK_SEQUENCE_ENTRY);
                parseStack.unshift(P_BLOCK_INDENTLESS_SEQUENCE_START);
                return null;
	            
	       case P_BLOCK_INDENTLESS_SEQUENCE_START:
                var impl : Boolean = tags[0] == null || tags[0] == "!";
                return new SequenceStartEvent(anchors[0], tags[0], impl, false);
	            
	       case P_INDENTLESS_BLOCK_SEQUENCE_ENTRY:
                if(scanner.peekToken() is BlockEntryToken) {
                    scanner.getToken();
                    var curr : Token = scanner.peekToken();
                    if(!(curr is BlockEntryToken || curr is KeyToken || curr is ValueToken || curr is BlockEndToken)) {
                        parseStack.unshift(P_INDENTLESS_BLOCK_SEQUENCE_ENTRY);
                        parseStack.unshift(P_BLOCK_NODE);
                    } else {
                        parseStack.unshift(P_INDENTLESS_BLOCK_SEQUENCE_ENTRY);
                        parseStack.unshift(P_EMPTY_SCALAR);
                    }
                }
                return null;
	            
	       case P_BLOCK_INDENTLESS_SEQUENCE_END:
                return SEQUENCE_END;
	            
	       case P_FLOW_SEQUENCE_START:
                var impl : Boolean = tags[0] == null || tags[0] == "!";
                scanner.getToken();
                return new SequenceStartEvent(anchors[0], tags[0], impl,true);
	            
	       case P_FLOW_SEQUENCE_ENTRY:
                if(!(scanner.peekToken() is FlowSequenceEndToken)) {
                    if(scanner.peekToken() is KeyToken) {
                        parseStack.unshift(P_FLOW_SEQUENCE_ENTRY);
                        parseStack.unshift(P_FLOW_ENTRY_MARKER);
                        parseStack.unshift(P_FLOW_INTERNAL_MAPPING_END);
                        parseStack.unshift(P_FLOW_INTERNAL_VALUE);
                        parseStack.unshift(P_FLOW_INTERNAL_CONTENT);
                        parseStack.unshift(P_FLOW_INTERNAL_MAPPING_START);
                    } else {
                        parseStack.unshift(P_FLOW_SEQUENCE_ENTRY);
                        parseStack.unshift(P_FLOW_NODE);
                        parseStack.unshift(P_FLOW_ENTRY_MARKER);
                    }
                }
                return null;
	            
	       case P_FLOW_SEQUENCE_END:
                scanner.getToken();
                return SEQUENCE_END;
	            
	       case P_FLOW_MAPPING_START:
                var impl : Boolean = tags[0] == null || tags[0] == "!";
                scanner.getToken();
                return new MappingStartEvent(anchors[0], tags[0], impl,true);
	            
	       case P_FLOW_MAPPING_ENTRY:
                if(!(scanner.peekToken() is FlowMappingEndToken)) {
                    if(scanner.peekToken() is KeyToken) {
                        parseStack.unshift(P_FLOW_MAPPING_ENTRY);
                        parseStack.unshift(P_FLOW_ENTRY_MARKER);
                        parseStack.unshift(P_FLOW_MAPPING_INTERNAL_VALUE);
                        parseStack.unshift(P_FLOW_MAPPING_INTERNAL_CONTENT);
                    } else {
                        parseStack.unshift(P_FLOW_MAPPING_ENTRY);
                        parseStack.unshift(P_FLOW_NODE);
                        parseStack.unshift(P_FLOW_ENTRY_MARKER);
                    }
                }
                return null;
	            
	       case P_FLOW_MAPPING_END:
                scanner.getToken();
                return MAPPING_END;
	            
	       case P_FLOW_INTERNAL_MAPPING_START:
                scanner.getToken();
                return new MappingStartEvent(null,null,true,true);
	            
	       case P_FLOW_INTERNAL_CONTENT:
                var curr : Token = scanner.peekToken();
                if(!(curr is ValueToken || curr is FlowEntryToken || curr is FlowSequenceEndToken)) {
                    parseStack.unshift(P_FLOW_NODE);
                } else {
                    parseStack.unshift(P_EMPTY_SCALAR);
                }
                return null;
	            
	       case P_FLOW_INTERNAL_VALUE:
                if(scanner.peekToken() is ValueToken) {
                    scanner.getToken();
                    if(!((scanner.peekToken() is FlowEntryToken) || (scanner.peekToken() is FlowSequenceEndToken))) {
                        parseStack.unshift(P_FLOW_NODE);
                    } else {
                        parseStack.unshift(P_EMPTY_SCALAR);
                    }
                } else {
                    parseStack.unshift(P_EMPTY_SCALAR);
                }
                return null;
	            
	       case P_FLOW_INTERNAL_MAPPING_END:
                return MAPPING_END;
	            
	       case P_FLOW_ENTRY_MARKER:
                if(scanner.peekToken() is FlowEntryToken) {
                    scanner.getToken();
                }
                return null;
	            
	       case P_FLOW_NODE:
                if(scanner.peekToken() is AliasToken) {
                    parseStack.unshift(P_ALIAS);
                } else {
                    parseStack.unshift(P_PROPERTIES_END);
                    parseStack.unshift(P_FLOW_CONTENT);
                    parseStack.unshift(P_PROPERTIES);
                }
                return null;
	            
	       case P_FLOW_MAPPING_INTERNAL_CONTENT:
                var curr : Token = scanner.peekToken();
                if(!(curr is ValueToken || curr is FlowEntryToken || curr is FlowMappingEndToken)) {
                    scanner.getToken();
                    parseStack.unshift(P_FLOW_NODE);
                } else {
                    parseStack.unshift(P_EMPTY_SCALAR);
                }
                return null;
	            
	       case P_FLOW_MAPPING_INTERNAL_VALUE:
                if(scanner.peekToken() is ValueToken) {
                    scanner.getToken();
                    if(!(scanner.peekToken() is FlowEntryToken || scanner.peekToken() is FlowMappingEndToken)) {
                        parseStack.unshift(P_FLOW_NODE);
                    } else {
                        parseStack.unshift(P_EMPTY_SCALAR);
                    }
                } else {
                    parseStack.unshift(P_EMPTY_SCALAR);
                }
                return null;
	            
	       case P_ALIAS:
                var aTok : AliasToken = scanner.getToken() as AliasToken;
                return new AliasEvent(aTok.getValue());
	            
	       case P_EMPTY_SCALAR:
	            return processEmptyScalar();
            
   			}
   			
   		return null;
                      	       	          	        			
   	}

 

    internal static function processEmptyScalar() : Event {
        return new ScalarEvent(null,null,[true,false],"", '0');
    }

    private function processDirectives(scanner: Scanner) : Array {
        while(scanner.peekToken() is DirectiveToken) {
            var tok : DirectiveToken = DirectiveToken(scanner.getToken());
            if(tok.getName() == ("YAML")) {
                if(yamlVersion != null) {
                    throw new ParserException(null,"found duplicate YAML directive", "line number: " + scanner.productionLineNumber());
                }
                var major : int = int(tok.getValue()[0]);
                var minor : int = int(tok.getValue()[1]);
                if(major != 1) {
                    throw new ParserException(null,"found incompatible YAML document (version 1.* is required)", "line number: " + scanner.productionLineNumber());
                }
                yamlVersion = [major,minor];
            } else if(tok.getName() == ("TAG")) {
                var handle : String = tok.getValue()[0];
                var prefix : String = tok.getValue()[1];
                if(tagHandles[handle]) {
                   trace("duplicate tag handle", handle);
                }
                tagHandles[handle] = prefix;
            }
        }
        var value : Array = [];
        value[0] = getFinalYamlVersion();
		

		var value1: Dictionary = new Dictionary();
		var tagHandlesIsEmpty: Boolean = true;
        for(var thKey : Object in tagHandles) {
			value1[thKey] = tagHandles[thKey];
			tagHandlesIsEmpty = false;
        }
        
        if (!tagHandlesIsEmpty) value[1] = value1;       

        var baseTags : Dictionary = value[0][1] == 0 ? DEFAULT_TAGS_1_0 : DEFAULT_TAGS_1_1;
        for(var btKey : Object in baseTags) {
            if(!tagHandles[btKey]) {
                tagHandles[btKey] = baseTags[btKey];
            }
        }
        return value;
    }

    private var scanner : Scanner = null;
    private var cfg : YAMLConfig = null;

    public function Parser(scanner : Scanner, cfg : YAMLConfig) {

        DEFAULT_TAGS_1_0["!"] = "tag:yaml.org,2002:";
		DEFAULT_TAGS_1_0["!!"] = "";

        DEFAULT_TAGS_1_1["!"] = "!";
        DEFAULT_TAGS_1_1["!!"] = "tag:yaml.org,2002:";        
        
        this.scanner = scanner;
        this.tags = [];
        this.anchors = [];
        this.tagHandles = cfg.getTags() || new Dictionary();
        this.yamlVersion = null;
        this.defaultYamlVersion = [];
        this.defaultYamlVersion[0] = int(cfg.getVersion().substring(0,cfg.getVersion().indexOf('.')));
        this.defaultYamlVersion[1] = int(cfg.getVersion().substring(cfg.getVersion().indexOf('.')+1));
    }

    public function getFinalYamlVersion() : Array {
        if(null == this.yamlVersion) {
            return this.defaultYamlVersion;
        }
        return this.yamlVersion;
    }

    private var currentEvent : Event = null;

    public function checkEvent(choices : Array) : Boolean {
        parseStream();
        if(this.currentEvent == null) {
            this.currentEvent = parseStreamNext();
        }
        if(this.currentEvent != null) {
            if(choices.length == 0) {
                return true;
            }
            for(var i : int = 0; i < choices.length; i++) {
                if(choices[i] == this.currentEvent) {
                    return true;
                }
            }
        }
        return false;
    }

    public function peekEvent() : Event {
        if (!parseStack) parseStream();
        if(this.currentEvent == null) {
            this.currentEvent = parseStreamNext();
        }
        		
        return this.currentEvent;
    }

    public function getEvent() : Event {
        parseStream();
        if(this.currentEvent == null) {
            this.currentEvent = parseStreamNext();
        }
        var value : Event = this.currentEvent;
        this.currentEvent = null;
        return value;
    }


    private var parseStack : Array = null;

    public function parseStream() : void {
        if(null == parseStack) {
            this.parseStack = [];
            this.parseStack.push(P_STREAM);
        }
    }

    public function parseStreamNext() : Event {
        while(parseStack.length > 0) {
        	var eventId : int = parseStack.shift() as int;
            var value : Event = this.produce(eventId) as Event;
           
            if(value) {
                return value;
            }
        }

        return null;
    }

}
}
