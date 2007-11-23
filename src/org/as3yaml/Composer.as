/* Copyright (c) 2007 Derek Wischusen
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

import org.as3yaml.events.*;
import org.as3yaml.nodes.*;
import org.idmedia.as3commons.util.*;

public class Composer {
    private var parser : Parser;
    private var resolver : Resolver;
    private var anchors : Map;

    public function Composer(parser : Parser, resolver : Resolver) : void {
        this.parser = parser;
        this.resolver = resolver;
        this.anchors = new HashMap();
    }

    public function checkNode() : Boolean {
        return !(parser.peekEvent() is StreamEndEvent);
    }
    
    public function getNode() : Node {
        return checkNode() ? composeDocument() : Node(null);
    }

    public function eachNode(composer : Composer) : Iterator {
        return new NodeIterator(composer);
    }

    public function iterator() : Iterator {
        return eachNode(this);
    }

    public function composeDocument() : Node {
        if(parser.peekEvent() is StreamStartEvent) {
            //Drop STREAM-START event
            parser.getEvent();
        }
        //Drop DOCUMENT-START event
        parser.getEvent();
        var node : Node = composeNode(null,null);
        //Drop DOCUMENT-END event
        parser.getEvent();
        this.anchors.clear();
        return node;
    }

    private static var FALS : Array = [false];
    private static var TRU : Array = [true];

    public function composeNode(parent : Node, index : Object) : Node {
        if(parser.peekEvent() is AliasEvent) {
            var eve : AliasEvent = parser.getEvent() as AliasEvent;
            var anchor : String = eve.getAnchor();
            if(!anchors.containsKey(anchor)) {
                
                throw new ComposerException(null,"found undefined alias " + anchor,null);
            }
            return anchors.get(anchor) as Node;
        }
        var event : Event = parser.peekEvent();
        var anchor : String = null;
        if(event is NodeEvent) {
            anchor = NodeEvent(event).getAnchor();
        }
        if(null != anchor) {
            if(anchors.containsKey(anchor)) {
                throw new ComposerException("found duplicate anchor "+anchor+"; first occurence",null,null);
            }
        }
        resolver.descendResolver(parent,index);
        var node : Node = null;
        if(event is ScalarEvent) {
            var ev : ScalarEvent = parser.getEvent() as ScalarEvent;
            var tag : String = ev.getTag();
            if(tag == null || tag == ("!")) {
                tag = resolver.resolve(ScalarNode,ev.getValue(),ev.getImplicit());
            }
            node = new ScalarNode(tag,ev.getValue(),ev.getStyle());
            if(null != anchor) {
                anchors.put(anchor,node);
            }
        } else if(event is SequenceStartEvent) {
            var start : SequenceStartEvent = parser.getEvent() as SequenceStartEvent;
            var tag : String = start.getTag();
            if(tag == null || tag == ("!")) {
                tag = resolver.resolve(SequenceNode,null,start.getImplicit()  ? TRU : FALS);
            }
            node = new SequenceNode(tag,new ArrayList(),start.getFlowStyle());
            if(null != anchor) {
                anchors.put(anchor,node);
            }
            var ix : int = 0;
            while(!(parser.peekEvent() is SequenceEndEvent)) {
                (node.getValue()).add(composeNode(node,new int(ix++)));
            }
            parser.getEvent();
        } else if(event is MappingStartEvent) {
            var st : MappingStartEvent = parser.getEvent() as MappingStartEvent;
            var tag : String = st.getTag();
            if(tag == null || tag == ("!")) {
                tag = resolver.resolve(MappingNode,null, st.getImplicit() ? TRU : FALS);
            }
            node = new MappingNode(tag, new HashMap(), st.getFlowStyle());
            if(null != anchor) {
                anchors.put(anchor,node);
            }
            while(!(parser.peekEvent() is MappingEndEvent)) {
                var key : Event = parser.peekEvent();
                var itemKey : Node = composeNode(node,null);
                if((node.getValue()).containsKey(itemKey)) {
                    composeNode(node,itemKey);
                } else {
                    (node.getValue()).put(itemKey,composeNode(node,itemKey));
                }
            }
            parser.getEvent();
        }
        resolver.ascendResolver();
        return node;
    }
    
}
}

import org.idmedia.as3commons.util.Iterator;
import org.as3yaml.Composer;
	

internal class NodeIterator implements Iterator {
	private var composer : Composer;
	public function NodeIterator(composer : Composer) : void { this.composer = composer; }
    public function hasNext() : Boolean {return composer.checkNode();}
    public function next() : * {return composer.getNode();}
    public function remove() : void {}
}
