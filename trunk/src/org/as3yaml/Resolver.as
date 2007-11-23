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

import org.rxr.actionscript.io.StringReader;

import org.as3yaml.nodes.*;
import org.idmedia.as3commons.util.*;

public class Resolver {
    private static var yamlImplicitResolvers : Map = new HashMap();
    private static var yamlPathResolvers : Map = new HashMap();

    private var resolverExactPaths : List = new ArrayList();
    private var resolverPrefixPaths : List = new ArrayList();

    public static function addImplicitResolver(tag : String, regexp : RegExp, first : String) : void {
        var firstVal : String = (null == first)?"":first;
        var reader : StringReader = new StringReader(firstVal);
        var chrs : Array = reader.readArray(0, firstVal.length);
        for(var i:int=0,j:int=chrs.length;i<j;i++) {
            var theC : String = new String(chrs[i]);
            var curr : List = List(yamlImplicitResolvers.get(theC));
            if(curr == null) {
                curr = new ArrayList();
                yamlImplicitResolvers.put(theC,curr);
            }
            curr.add([tag,regexp]);
        }
    }

    public static function addPathResolver(tag : String, path : List, kind : Class) : void {
        var newPath : List = new ArrayList();
        var nodeCheck : Object = null;
        var indexCheck : Object = null;
        for(var iter : Iterator = path.iterator();iter.hasNext();) {
            var element : Object = iter.next();
            if(element is List) {
                var eList : List = element as List;
                if(eList.size() == 2) {
                    nodeCheck = eList.get(0);
                    indexCheck = eList.get(1);
                } else if(eList.size() == 1) {
                    nodeCheck = eList.get(0);
                    indexCheck = true;
                } else {
                    throw new ResolverException("Invalid path element: " + element);
                }
            } else {
                nodeCheck = null;
                indexCheck = element;
            }

            if(nodeCheck is String) {
                nodeCheck = ScalarNode;
            } else if(nodeCheck is List) {
                nodeCheck = SequenceNode;
            } else if(nodeCheck is Map) {
                nodeCheck = MappingNode;
            } else if(null != nodeCheck && !ScalarNode == (nodeCheck) && !SequenceNode == (nodeCheck) && !MappingNode == (nodeCheck)) {
                throw new ResolverException("Invalid node checker: " + nodeCheck);
            }
            if(!(indexCheck is String || indexCheck is int) && null != indexCheck) {
                throw new ResolverException("Invalid index checker: " + indexCheck);
            }
            newPath.add([nodeCheck,indexCheck]);
        }
        var newKind : Class = null;
        if(String == kind) {
            newKind = ScalarNode;
        } else if(List == kind) {
            newKind = SequenceNode;
        } else if(Map == kind) {
            newKind = MappingNode;
        } else if(kind != null && !ScalarNode == kind && !SequenceNode == kind && !MappingNode == kind) {
            throw new ResolverException("Invalid node kind: " + kind);
        } else {
            newKind = kind;
        }
        var x : List = new ArrayList();
        x.add(newPath);
        var y : List = new ArrayList();
        y.add(x);
        y.add(kind);
        yamlPathResolvers.put(y,tag);
    }

    public function descendResolver(currentNode : Node, currentIndex : Object) : void {
        var exactPaths : Map = new HashMap();
        var prefixPaths : List = new ArrayList();
        if(null != currentNode) {
            var depth : int = resolverPrefixPaths.size();
            for(var iter : Iterator = (resolverPrefixPaths.get(0)).iterator();iter.hasNext();) {
                var obj : Array = iter.next() as Array;
                var path : List = obj[0] as List;
                if(checkResolverPrefix(depth,path, obj[1],currentNode,currentIndex)) {
                    if(path.size() > depth) {
                        prefixPaths.add([path,obj[1]]);
                    } else {
                        var resPath : List = new ArrayList();
                        resPath.add(path);
                        resPath.add(obj[1]);
                        exactPaths.put(obj[1],yamlPathResolvers.get(resPath));
                    }
                }
            }
        } else {
            for(var iter : Iterator = yamlPathResolvers.keySet().iterator();iter.hasNext();) {
                var key : List = iter.next() as List;
                var path : List = key.get(0) as List;
                var kind : Class = key.get(1) as Class;
                if(null == path) {
                    exactPaths.put(kind,yamlPathResolvers.get(key));
                } else {
                    prefixPaths.add(key);
                }
            }
        }
        resolverExactPaths.addAt(0,exactPaths);
        resolverPrefixPaths.addAt(0,prefixPaths);
    }

    public function ascendResolver() : void {
        resolverExactPaths.remove(0);
        resolverPrefixPaths.remove(0);
    }

    public function checkResolverPrefix(depth : int, path : List, kind : Class, currentNode : Node, currentIndex : Object) : Boolean {
        var check : Array = path.get(depth-1);
        var nodeCheck : Object = check[0];
        var indexCheck : Object = check[1];
        if(nodeCheck is String) {
            if(!currentNode.getTag() == (nodeCheck)) {
                return false;
            }
        } else if(null != nodeCheck) {
            if(!(nodeCheck).isInstance(currentNode)) {
                return false;
            }
        }
        if(indexCheck == true && currentIndex != null) {
            return false;
        }
        if(indexCheck == true && currentIndex == null) {
            return false;
        }
        if(indexCheck is String) {
            if(!(currentIndex is ScalarNode && indexCheck == ((ScalarNode(currentIndex)).getValue()))) {
                return false;
            }
        } else if(indexCheck is int) {
            if(!currentIndex == (indexCheck)) {
                return false;
            }
        }
        return true;
    }
    
    public function resolve(kind : Class, value : String, implicit : Array) : String {
        var resolvers : List = null;
        if(kind == ScalarNode && implicit[0]) {
            if("" == (value)) {
                resolvers = yamlImplicitResolvers.get("") as List;
            } else {
                resolvers = yamlImplicitResolvers.get(new String(value.charAt(0))) as List;
            }
            if(resolvers == null) {
                resolvers = new ArrayList();
            }
            if(yamlImplicitResolvers.containsKey(null)) {
                resolvers.addAll(yamlImplicitResolvers.get(null));
            }
            for(var iter : Iterator = resolvers.iterator();iter.hasNext();) {
                var val : Array = iter.next();
                if((RegExp(val[1])).exec(value)) {
                    return val[0] as String;
                }
            }
        }
        var exactPaths : Map = resolverExactPaths.get(0) as Map;
        if(exactPaths.containsKey(kind)) {
            return exactPaths.get(kind) as String;
        }
        if(exactPaths.containsKey(null)) {
            return exactPaths.get(null) as String;
        }
        if(kind == ScalarNode) {
            return YAML.DEFAULT_SCALAR_TAG;
        } else if(kind == SequenceNode) {
            return YAML.DEFAULT_SEQUENCE_TAG;
        } else if(kind == MappingNode) {
            return YAML.DEFAULT_MAPPING_TAG;
        }
        return null;
    } 

    static: {
        addImplicitResolver("tag:yaml.org,2002:bool",new RegExp("^(?:yes|Yes|YES|no|No|NO|true|True|TRUE|false|False|FALSE|on|On|ON|off|Off|OFF)$"),"yYnNtTfFoO");
        addImplicitResolver("tag:yaml.org,2002:float",new RegExp("^(?:[-+]?(?:[0-9][0-9_]*)\\.[0-9_]*(?:[eE][-+][0-9]+)?|[-+]?(?:[0-9][0-9_]*)?\\.[0-9_]+(?:[eE][-+][0-9]+)?|[-+]?[0-9][0-9_]*(?::[0-5]?[0-9])+\\.[0-9_]*|[-+]?\\.(?:inf|Inf|INF)|\\.(?:nan|NaN|NAN))$"),"-+0123456789.");
        addImplicitResolver("tag:yaml.org,2002:int",new RegExp("^(?:[-+]?0b[0-1_]+|[-+]?0[0-7_]+|[-+]?(?:0|[1-9][0-9_]*)|[-+]?0x[0-9a-fA-F_]+|[-+]?[1-9][0-9_]*(?::[0-5]?[0-9])+)$"),"-+0123456789");
        addImplicitResolver("tag:yaml.org,2002:merge",new RegExp("^(?:<<)$"),"<");
        addImplicitResolver("tag:yaml.org,2002:null",new RegExp("^(?:~|null|Null|NULL| )$"),"~nN\x00");
        addImplicitResolver("tag:yaml.org,2002:timestamp",new RegExp("^(?:[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]|[0-9][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?(?:[Tt]|[ \t]+)[0-9][0-9]?:[0-9][0-9]:[0-9][0-9](?:\\.[0-9]*)?(?:[ \t]*(?:Z|[-+][0-9][0-9]?(?::[0-9][0-9])?))?)$"),"0123456789");
        addImplicitResolver("tag:yaml.org,2002:value",new RegExp("^(?:=)$"),"=");
      // The following implicit resolver is only for documentation purposes. It cannot work
      // because plain scalars cannot start with '!', '&', or '*'.
        addImplicitResolver("tag:yaml.org,2002:yaml",new RegExp("^(?:!|&|\\*)$"),"!&*");
    }
}
}