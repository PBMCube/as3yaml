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

import flash.utils.getQualifiedClassName;

import org.as3yaml.events.*;
import org.as3yaml.tokens.*;
import org.idmedia.as3commons.util.*;

public class Parser {
    // Memnonics for the production table
    private static const P_STREAM: int = 0;
    private static const P_STREAM_START: int = 1; // TERMINAL
    private static const P_STREAM_END: int = 2; // TERMINAL
    private static const P_IMPLICIT_DOCUMENT: int = 3;
    private static const P_EXPLICIT_DOCUMENT: int = 4;
    private static const P_DOCUMENT_START: int = 5;
    private static const P_DOCUMENT_START_IMPLICIT: int = 6;
    private static const P_DOCUMENT_END: int = 7;
    private static const P_BLOCK_NODE: int = 8;
    private static const P_BLOCK_CONTENT: int = 9;
    private static const P_PROPERTIES: int = 10;
    private static const P_PROPERTIES_END: int = 11;
    private static const P_FLOW_CONTENT: int = 12;
    private static const P_BLOCK_SEQUENCE: int = 13;
    private static const P_BLOCK_MAPPING: int = 14;
    private static const P_FLOW_SEQUENCE: int = 15;
    private static const P_FLOW_MAPPING: int = 16;
    private static const P_SCALAR: int = 17;
    private static const P_BLOCK_SEQUENCE_ENTRY: int = 18;
    private static const P_BLOCK_MAPPING_ENTRY: int = 19;
    private static const P_BLOCK_MAPPING_ENTRY_VALUE: int = 20;
    private static const P_BLOCK_NODE_OR_INDENTLESS_SEQUENCE: int = 21;
    private static const P_BLOCK_SEQUENCE_START: int = 22;
    private static const P_BLOCK_SEQUENCE_END: int = 23;
    private static const P_BLOCK_MAPPING_START: int = 24;
    private static const P_BLOCK_MAPPING_END: int = 25;
    private static const P_INDENTLESS_BLOCK_SEQUENCE: int = 26;
    private static const P_BLOCK_INDENTLESS_SEQUENCE_START: int = 27;
    private static const P_INDENTLESS_BLOCK_SEQUENCE_ENTRY: int = 28;
    private static const P_BLOCK_INDENTLESS_SEQUENCE_END: int = 29;
    private static const P_FLOW_SEQUENCE_START: int = 30;
    private static const P_FLOW_SEQUENCE_ENTRY: int = 31;
    private static const P_FLOW_SEQUENCE_END: int = 32;
    private static const P_FLOW_MAPPING_START: int = 33;
    private static const P_FLOW_MAPPING_ENTRY: int = 34;
    private static const P_FLOW_MAPPING_END: int = 35;
    private static const P_FLOW_INTERNAL_MAPPING_START: int = 36;
    private static const P_FLOW_INTERNAL_CONTENT: int = 37;
    private static const P_FLOW_INTERNAL_VALUE: int = 38;
    private static const P_FLOW_INTERNAL_MAPPING_END: int = 39;
    private static const P_FLOW_ENTRY_MARKER: int = 40;
    private static const P_FLOW_NODE: int = 41;
    private static const P_FLOW_MAPPING_INTERNAL_CONTENT: int = 42;
    private static const P_FLOW_MAPPING_INTERNAL_VALUE: int = 43;
    private static const P_ALIAS: int = 44;
    private static const P_EMPTY_SCALAR: int = 45;

    private static var DOCUMENT_END_TRUE: Event  = new DocumentEndEvent(true);
    private static var DOCUMENT_END_FALSE: Event  = new DocumentEndEvent(false);
    private static var MAPPING_END: Event  = new MappingEndEvent();
    private static var SEQUENCE_END: Event  = new SequenceEndEvent();
    private static var STREAM_END: Event  = new StreamEndEvent();
    private static var STREAM_START: Event  = new StreamStartEvent();

    private static const P_TABLE : Array = [];

    private static var DEFAULT_TAGS_1_0 : Map = new HashMap();
    private static var DEFAULT_TAGS_1_1 : Map = new HashMap();
    /*static*/ {
        DEFAULT_TAGS_1_0.put("!","tag:yaml.org,2002:");
		DEFAULT_TAGS_1_0.put("!!","");

        DEFAULT_TAGS_1_1.put("!","!");
        DEFAULT_TAGS_1_1.put("!!","tag:yaml.org,2002:");
    }

	private static var ONLY_WORD : RegExp = new RegExp("^\\w+$");
	
    /*static*/ {
        P_TABLE[P_STREAM] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
			                    parseStack.addAt(0,P_TABLE[P_STREAM_END]);
			                    parseStack.addAt(0,P_TABLE[P_EXPLICIT_DOCUMENT]);
			                    parseStack.addAt(0,P_TABLE[P_IMPLICIT_DOCUMENT]);
			                    parseStack.addAt(0,P_TABLE[P_STREAM_START]);
			                    return null;
                			};

        P_TABLE[P_STREAM_START] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
			                    	scanner.getToken();
			                    	return STREAM_START;
                			};

        P_TABLE[P_STREAM_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
			                    scanner.getToken();
			                    return STREAM_END;
                			};

        P_TABLE[P_IMPLICIT_DOCUMENT] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var curr : Token = scanner.peekToken();
                    if(!(curr is DirectiveToken || curr is DocumentStartToken || curr is StreamEndToken)) {
                        parseStack.addAt(0,P_TABLE[P_DOCUMENT_END]);
                        parseStack.addAt(0,P_TABLE[P_BLOCK_NODE]);
                        parseStack.addAt(0,P_TABLE[P_DOCUMENT_START_IMPLICIT]);
                    }
                    return null;
                }
            };
        P_TABLE[P_EXPLICIT_DOCUMENT] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(!(scanner.peekToken() is StreamEndToken)) {
                        parseStack.addAt(0,P_TABLE[P_EXPLICIT_DOCUMENT]);
                        parseStack.addAt(0,P_TABLE[P_DOCUMENT_END]);
                        parseStack.addAt(0,P_TABLE[P_BLOCK_NODE]);
                        parseStack.addAt(0,P_TABLE[P_DOCUMENT_START]);
                    }
                    return null;
            };
        P_TABLE[P_DOCUMENT_START] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var tok : Token = scanner.peekToken();
                    var directives : Array = processDirectives(env,scanner);
                    if(!(scanner.peekToken() is DocumentStartToken)) {
                        throw new ParserException(null,"expected '<document start>', but found " + getQualifiedClassName(tok),null);
                    }
                    scanner.getToken();
                    return new DocumentStartEvent(true, directives[0], directives[1]);
                
            };
        P_TABLE[P_DOCUMENT_START_IMPLICIT] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var directives : Array = processDirectives(env,scanner);
                    return new DocumentStartEvent(false,directives[0], directives[1]);
              
            };
        P_TABLE[P_DOCUMENT_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var tok : Token = scanner.peekToken();
                    var explicit : Boolean = false;
                    while(scanner.peekToken() is DocumentEndToken) {
                        scanner.getToken();
                        explicit = true;
                    }
                    return explicit ? DOCUMENT_END_TRUE : DOCUMENT_END_FALSE;
            };
        P_TABLE[P_BLOCK_NODE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var curr : Token = scanner.peekToken();
                    if(curr is DirectiveToken || curr is DocumentStartToken || curr is DocumentEndToken || curr is StreamEndToken) {
                        parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                    } else {
                        if(curr is AliasToken) {
                            parseStack.addAt(0,P_TABLE[P_ALIAS]);
                        } else {
                            parseStack.addAt(0,P_TABLE[P_PROPERTIES_END]);
                            parseStack.addAt(0,P_TABLE[P_BLOCK_CONTENT]);
                            parseStack.addAt(0,P_TABLE[P_PROPERTIES]);
                        }
                    }
                    return null;
            };
        P_TABLE[P_BLOCK_CONTENT] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var tok : Token = scanner.peekToken();
                    if(tok is BlockSequenceStartToken) {
                        parseStack.addAt(0,P_TABLE[P_BLOCK_SEQUENCE]);
                    } else if(tok is BlockMappingStartToken) {
                        parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING]);
                    } else if(tok is FlowSequenceStartToken) {
                        parseStack.addAt(0,P_TABLE[P_FLOW_SEQUENCE]);
                    } else if(tok is FlowMappingStartToken) {
                        parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING]);
                    } else if(tok is ScalarToken) {
                        parseStack.addAt(0,P_TABLE[P_SCALAR]);
                    } else {
                        return new ScalarEvent(this.getAnchors().get(0),this.getTags().get(0),[false,false],null,'\'');
                    }
                    return null;
            };
        P_TABLE[P_PROPERTIES] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var anchor : String = null;
                    var tag : * = null;
                    if(scanner.peekToken() is AnchorToken) {
                        anchor = AnchorToken(scanner.getToken()).getValue();
                        if(scanner.peekToken() is TagToken) {
                            scanner.getToken();
                        }
                    } else if(scanner.peekToken() is TagToken) {
                        tag = TagToken(scanner.getToken()).getValue();
                        if(scanner.peekToken() is AnchorToken) {
                            anchor = AnchorToken(scanner.getToken()).getValue();
                        }
                    }
                    if(tag != null && tag != "!") {
                        var handle : String = tag[0];
                        var suffix : String = tag[1];
	                    var ix : int = -1;
//	                    if((ix = suffix.indexOf("^")) != -1) {
//	                        suffix = suffix.substring(0,ix) + suffix.substring(ix+1);
//	                    }
                        if(handle != null) {
                            if(!env.getTagHandles().containsKey(handle)) {
                                throw new ParserException("while parsing a node","found undefined tag handle " + handle,null);
                            }
//	                        if((ix = suffix.indexOf("/")) != -1) {
//	                            var before : String = suffix.substring(0,ix);
//	                            var after : String = suffix.substring(ix+1);
//	                            if(ONLY_WORD.exec(before)) {
//	                                tag = "tag:" + before + ".yaml.org,2002:" + after;
//	                            } else {
//	                                if(StringUtils.startsWith(before, "tag:")) {
//	                                    tag = before + ":" + after;
//	                                } else {
//	                                    tag = "tag:" + before + ":" + after;
//	                                }
//	                            }
//	                        } else {
	                            tag = (env.getTagHandles().get(handle)) + suffix;
	                        //}
                            
                        } else {
                            tag = suffix;
                        }
                    }
                    env.getAnchors().addAt(0,anchor);
                    env.getTags().addAt(0,tag);
                    return null;
            };
        P_TABLE[P_PROPERTIES_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    env.getAnchors().remove(0);
                    env.getTags().remove(0);
                    return null;
            };
        P_TABLE[P_FLOW_CONTENT] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var tok : Token = scanner.peekToken();
                    if(tok is FlowSequenceStartToken) {
                        parseStack.addAt(0,P_TABLE[P_FLOW_SEQUENCE]);
                    } else if(tok is FlowMappingStartToken) {
                        parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING]);
                    } else if(tok is ScalarToken) {
                        parseStack.addAt(0,P_TABLE[P_SCALAR]);
                    } else {
                        throw new ParserException("while scanning a flow node","expected the node content, but found " + getQualifiedClassName(tok),null);
                    }
                    return null;
            };
        P_TABLE[P_BLOCK_SEQUENCE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    parseStack.addAt(0,P_TABLE[P_BLOCK_SEQUENCE_END]);
                    parseStack.addAt(0,P_TABLE[P_BLOCK_SEQUENCE_ENTRY]);
                    parseStack.addAt(0,P_TABLE[P_BLOCK_SEQUENCE_START]);
                    return null;
            };
        P_TABLE[P_BLOCK_MAPPING] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_END]);
                    parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_ENTRY]);
                    parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_START]);
                    return null;
            };
        P_TABLE[P_FLOW_SEQUENCE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    parseStack.addAt(0,P_TABLE[P_FLOW_SEQUENCE_END]);
                    parseStack.addAt(0,P_TABLE[P_FLOW_SEQUENCE_ENTRY]);
                    parseStack.addAt(0,P_TABLE[P_FLOW_SEQUENCE_START]);
                    return null;
            };
        P_TABLE[P_FLOW_MAPPING] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING_END]);
                    parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING_ENTRY]);
                    parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING_START]);
                    return null;
            };
        P_TABLE[P_SCALAR] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var tok : ScalarToken = scanner.getToken() as ScalarToken;
                    var implicit : Array = null;
                    if((tok.getPlain() && env.getTags().get(0) == null) || "!" == (env.getTags().get(0))) {
                        implicit = [true,false];
                    } else if(env.getTags().get(0) == null) {
                        implicit = [false,true];
                    } else {
                        implicit = [false,false];
                    }
                    return new ScalarEvent(env.getAnchors().get(0),env.getTags().get(0),implicit,tok.getValue(),tok.getStyle());
            };
        P_TABLE[P_BLOCK_SEQUENCE_ENTRY] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is BlockEntryToken) {
                        scanner.getToken();
                        if(!(scanner.peekToken() is BlockEntryToken || scanner.peekToken() is BlockEndToken)) {
                            parseStack.addAt(0,P_TABLE[P_BLOCK_SEQUENCE_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_BLOCK_NODE]);
                        } else {
                            parseStack.addAt(0,P_TABLE[P_BLOCK_SEQUENCE_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                        }
                    }
                    return null;
            };
        P_TABLE[P_BLOCK_MAPPING_ENTRY] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is KeyToken || scanner.peekToken() is ValueToken) {
                        if(scanner.peekToken() is KeyToken) {
                            scanner.getToken();
                            var curr : Token = scanner.peekToken();
                            if(!(curr is KeyToken || curr is ValueToken || curr is BlockEndToken)) {
                                parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_ENTRY]);
                                parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_ENTRY_VALUE]);
                                parseStack.addAt(0,P_TABLE[P_BLOCK_NODE_OR_INDENTLESS_SEQUENCE]);
                            } else {
                                parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_ENTRY]);
                                parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_ENTRY_VALUE]);
                                parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                            }
                        } else {
                            parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_BLOCK_MAPPING_ENTRY_VALUE]);
                            parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                        }
                    }
                    return null;
            };
        P_TABLE[P_BLOCK_MAPPING_ENTRY_VALUE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is KeyToken || scanner.peekToken() is ValueToken) {
                        if(scanner.peekToken() is ValueToken) {
                            scanner.getToken();
                            var curr : Token = scanner.peekToken();
                            if(!(curr is KeyToken || curr is ValueToken || curr is BlockEndToken)) {
                                parseStack.addAt(0,P_TABLE[P_BLOCK_NODE_OR_INDENTLESS_SEQUENCE]);
                            } else {
                                parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                            }
                        } else {
                            parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                        }
                    }
                    return null;
            };
        P_TABLE[P_BLOCK_NODE_OR_INDENTLESS_SEQUENCE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is AliasToken) {
                        parseStack.addAt(0,P_TABLE[P_ALIAS]);
                    } else {
                        if(scanner.peekToken() is BlockEntryToken) {
                            parseStack.addAt(0,P_TABLE[P_INDENTLESS_BLOCK_SEQUENCE]);
                            parseStack.addAt(0,P_TABLE[P_PROPERTIES]);
                        } else {
                            parseStack.addAt(0,P_TABLE[P_BLOCK_CONTENT]);
                            parseStack.addAt(0,P_TABLE[P_PROPERTIES]);
                        }
                    }
                    return null;
            };
        P_TABLE[P_BLOCK_SEQUENCE_START] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var implicit : Boolean = env.getTags().get(0) == null || env.getTags().get(0) == "!";
                    scanner.getToken();
                    return new SequenceStartEvent(env.getAnchors().get(0), env.getTags().get(0), implicit,false);
            };
        P_TABLE[P_BLOCK_SEQUENCE_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var tok : Token = null;
                    if(!(scanner.peekToken() is BlockEndToken)) {
                        tok = scanner.peekToken();
                        throw new ParserException("while scanning a block collection","expected <block end>, but found " + getQualifiedClassName(tok),null);
                    }
                    scanner.getToken();
                    return SEQUENCE_END;
            };
        P_TABLE[P_BLOCK_MAPPING_START] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var implicit : Boolean = env.getTags().get(0) == null || env.getTags().get(0) == "!";
                    scanner.getToken();
                    return new MappingStartEvent(env.getAnchors().get(0), env.getTags().get(0), implicit,false);
            };
        P_TABLE[P_BLOCK_MAPPING_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var tok : Token = null;
                    if(!(scanner.peekToken() is BlockEndToken)) {
                        tok = scanner.peekToken();
                        throw new ParserException("while scanning a block mapping","expected <block end>, but found " + getQualifiedClassName(tok),null);
                    }
                    scanner.getToken();
                    return MAPPING_END;
            };
        P_TABLE[P_INDENTLESS_BLOCK_SEQUENCE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    parseStack.addAt(0,P_TABLE[P_BLOCK_INDENTLESS_SEQUENCE_END]);
                    parseStack.addAt(0,P_TABLE[P_INDENTLESS_BLOCK_SEQUENCE_ENTRY]);
                    parseStack.addAt(0,P_TABLE[P_BLOCK_INDENTLESS_SEQUENCE_START]);
                    return null;
            };
        P_TABLE[P_BLOCK_INDENTLESS_SEQUENCE_START] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var implicit : Boolean = env.getTags().get(0) == null || env.getTags().get(0) == "!";
                    return new SequenceStartEvent(env.getAnchors().get(0), env.getTags().get(0), implicit, false);
            };
        P_TABLE[P_INDENTLESS_BLOCK_SEQUENCE_ENTRY] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is BlockEntryToken) {
                        scanner.getToken();
                        var curr : Token = scanner.peekToken();
                        if(!(curr is BlockEntryToken || curr is KeyToken || curr is ValueToken || curr is BlockEndToken)) {
                            parseStack.addAt(0,P_TABLE[P_INDENTLESS_BLOCK_SEQUENCE_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_BLOCK_NODE]);
                        } else {
                            parseStack.addAt(0,P_TABLE[P_INDENTLESS_BLOCK_SEQUENCE_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                        }
                    }
                    return null;
            };
        P_TABLE[P_BLOCK_INDENTLESS_SEQUENCE_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    return SEQUENCE_END;
            };
        P_TABLE[P_FLOW_SEQUENCE_START] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var implicit : Boolean = env.getTags().get(0) == null || env.getTags().get(0) == "!";
                    scanner.getToken();
                    return new SequenceStartEvent(env.getAnchors().get(0), env.getTags().get(0), implicit,true);
            };
        P_TABLE[P_FLOW_SEQUENCE_ENTRY] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(!(scanner.peekToken() is FlowSequenceEndToken)) {
                        if(scanner.peekToken() is KeyToken) {
                            parseStack.addAt(0,P_TABLE[P_FLOW_SEQUENCE_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_ENTRY_MARKER]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_INTERNAL_MAPPING_END]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_INTERNAL_VALUE]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_INTERNAL_CONTENT]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_INTERNAL_MAPPING_START]);
                        } else {
                            parseStack.addAt(0,P_TABLE[P_FLOW_SEQUENCE_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_NODE]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_ENTRY_MARKER]);
                        }
                    }
                    return null;
            };
        P_TABLE[P_FLOW_SEQUENCE_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    scanner.getToken();
                    return SEQUENCE_END;
            };
        P_TABLE[P_FLOW_MAPPING_START] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var implicit : Boolean = env.getTags().get(0) == null || env.getTags().get(0) == "!";
                    scanner.getToken();
                    return new MappingStartEvent(env.getAnchors().get(0), env.getTags().get(0), implicit,true);
            };
        P_TABLE[P_FLOW_MAPPING_ENTRY] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(!(scanner.peekToken() is FlowMappingEndToken)) {
                        if(scanner.peekToken() is KeyToken) {
                            parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_ENTRY_MARKER]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING_INTERNAL_VALUE]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING_INTERNAL_CONTENT]);
                        } else {
                            parseStack.addAt(0,P_TABLE[P_FLOW_MAPPING_ENTRY]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_NODE]);
                            parseStack.addAt(0,P_TABLE[P_FLOW_ENTRY_MARKER]);
                        }
                    }
                    return null;
            };
        P_TABLE[P_FLOW_MAPPING_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    scanner.getToken();
                    return MAPPING_END;
            };
        P_TABLE[P_FLOW_INTERNAL_MAPPING_START] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    scanner.getToken();
                    return new MappingStartEvent(null,null,true,true);
            };
        P_TABLE[P_FLOW_INTERNAL_CONTENT] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var curr : Token = scanner.peekToken();
                    if(!(curr is ValueToken || curr is FlowEntryToken || curr is FlowSequenceEndToken)) {
                        parseStack.addAt(0,P_TABLE[P_FLOW_NODE]);
                    } else {
                        parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                    }
                    return null;
            };
        P_TABLE[P_FLOW_INTERNAL_VALUE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is ValueToken) {
                        scanner.getToken();
                        if(!((scanner.peekToken() is FlowEntryToken) || (scanner.peekToken() is FlowSequenceEndToken))) {
                            parseStack.addAt(0,P_TABLE[P_FLOW_NODE]);
                        } else {
                            parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                        }
                    } else {
                        parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                    }
                    return null;
            };
        P_TABLE[P_FLOW_INTERNAL_MAPPING_END] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    return MAPPING_END;
            };
        P_TABLE[P_FLOW_ENTRY_MARKER] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is FlowEntryToken) {
                        scanner.getToken();
                    }
                    return null;
            };
        P_TABLE[P_FLOW_NODE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is AliasToken) {
                        parseStack.addAt(0,P_TABLE[P_ALIAS]);
                    } else {
                        parseStack.addAt(0,P_TABLE[P_PROPERTIES_END]);
                        parseStack.addAt(0,P_TABLE[P_FLOW_CONTENT]);
                        parseStack.addAt(0,P_TABLE[P_PROPERTIES]);
                    }
                    return null;
            };
        P_TABLE[P_FLOW_MAPPING_INTERNAL_CONTENT] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var curr : Token = scanner.peekToken();
                    if(!(curr is ValueToken || curr is FlowEntryToken || curr is FlowMappingEndToken)) {
                        scanner.getToken();
                        parseStack.addAt(0,P_TABLE[P_FLOW_NODE]);
                    } else {
                        parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                    }
                    return null;
            };
        P_TABLE[P_FLOW_MAPPING_INTERNAL_VALUE] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    if(scanner.peekToken() is ValueToken) {
                        scanner.getToken();
                        if(!(scanner.peekToken() is FlowEntryToken || scanner.peekToken() is FlowMappingEndToken)) {
                            parseStack.addAt(0,P_TABLE[P_FLOW_NODE]);
                        } else {
                            parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                        }
                    } else {
                        parseStack.addAt(0,P_TABLE[P_EMPTY_SCALAR]);
                    }
                    return null;
            };
        P_TABLE[P_ALIAS] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    var tok : AliasToken = scanner.getToken() as AliasToken;
                    return new AliasEvent(tok.getValue());
            };
        P_TABLE[P_EMPTY_SCALAR] = function produce(parseStack : List, env : ProductionEnvironment, scanner : Scanner) : Event {
                    return processEmptyScalar();
            };


    internal static function processEmptyScalar() : Event {
        return new ScalarEvent(null,null,[true,false],"", '0');
    }

    private static function processDirectives(env : ProductionEnvironment, scanner : Scanner) : Array {
        while(scanner.peekToken() is DirectiveToken) {
            var tok : DirectiveToken = DirectiveToken(scanner.getToken());
            if(tok.getName() == ("YAML")) {
                if(env.getYamlVersion() != null) {
                    throw new ParserException(null,"found duplicate YAML directive",null);
                }
                var major : int = int(tok.getValue()[0]);
                var minor : int = int(tok.getValue()[1]);
                if(major != 1) {
                    throw new ParserException(null,"found incompatible YAML document (version 1.* is required)",null);
                }
                env.setYamlVersion([major,minor]);
            } else if(tok.getName() == ("TAG")) {
                var handle : String = tok.getValue()[0];
                var prefix : String = tok.getValue()[1];
                if(env.getTagHandles().containsKey(handle)) {
                    throw new ParserException(null,"duplicate tag handle " + handle,null);
                }
                env.getTagHandles().put(handle,prefix);
            }
        }
        var value : Array = new Array();
        value[0] = env.getFinalYamlVersion();

        if(!env.getTagHandles().isEmpty()) {
            value[1] = new HashMap().putAll(env.getTagHandles());
        }

        var baseTags : Map = value[0][1] == 0 ? DEFAULT_TAGS_1_0 : DEFAULT_TAGS_1_1;
        for(var iter : Iterator = baseTags.keySet().iterator(); iter.hasNext();) {
            var key : Object = iter.next();
            if(!env.getTagHandles().containsKey(key)) {
                env.getTagHandles().put(key,baseTags.get(key));
            }
        }
        return value;
    }

    private var scanner : Scanner = null;
    private var cfg : YAMLConfig = null;

    public function Parser(scanner : Scanner, cfg : YAMLConfig) {
        this.scanner = scanner;
        this.cfg = cfg;
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
        parseStream();
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

    public function eachEvent(parser : Parser) : Iterator {
        return new EventIterator(parser);
    }

    public function iterator() : Iterator {
        return eachEvent(this);
    }

    private var parseStack : ArrayList = null;
    private var pEnv : ProductionEnvironment = null;

    public function parseStream() : void {
        if(null == parseStack) {
            this.parseStack = new ArrayList();
            this.parseStack.addAt(0,P_TABLE[P_STREAM]);
            this.pEnv = new ProductionEnvironment(cfg);
        }
    }

    public function parseStreamNext() : Event {
        while(!parseStack.isEmpty()) {
        	var func : Function = parseStack.removeAtAndReturn(0) as Function;
            var value : Event = func.call(null,this.parseStack,this.pEnv,this.scanner);
            if(null != value) {
                return value;
            }
        }
        this.pEnv = null;
        return null;
    }

}
}
	import org.idmedia.as3commons.util.Iterator;
	import org.idmedia.as3commons.util.List;
	import org.idmedia.as3commons.util.Map;
	import org.as3yaml.YAMLConfig;
	import org.idmedia.as3commons.util.HashMap;
	import org.as3yaml.Parser;
	

internal class EventIterator implements Iterator {
   
   private var parser : Parser;
   public function EventIterator (parser : Parser) : void{
   	this.parser = parser;
   }
   
    public function hasNext() : Boolean {
        return null != parser.peekEvent();
    }

    public function next() : * {
        return parser.getEvent();
    }

    public function remove() : void {
    }
}

import org.as3yaml.YAMLConfig;
import org.as3yaml.DefaultYAMLConfig;
import org.idmedia.as3commons.util.ArrayList;
internal class ProductionEnvironment {
    private var tags:List;
    private var anchors:List;
    private var tagHandles:Map;
    private var yamlVersion:Array;
    private var defaultYamlVersion:Array;

    public function ProductionEnvironment(cfg : YAMLConfig): void{
        this.tags = new ArrayList();
        this.anchors = new ArrayList();
        this.tagHandles = new HashMap();
        this.yamlVersion = null;
        this.defaultYamlVersion = [];
        this.defaultYamlVersion[0] = int(cfg.getVersion().substring(0,cfg.getVersion().indexOf('.')));
        this.defaultYamlVersion[1] = int(cfg.getVersion().substring(cfg.getVersion().indexOf('.')+1));
    }

    public function getTags() : List{
        return this.tags;
    }

    public function getAnchors():List{
        return this.anchors;
    }

    public function getTagHandles() : Map{
        return this.tagHandles;
    }

    public function getYamlVersion() : Array {
        return this.yamlVersion;
    }

    public function getFinalYamlVersion() : Array {
        if(null == this.yamlVersion) {
            return this.defaultYamlVersion;
        }
        return this.yamlVersion;
    }

    public function setYamlVersion(yamlVersion:Array):void{
        this.yamlVersion = yamlVersion;
    }
}