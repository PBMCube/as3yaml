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

import flash.utils.getQualifiedClassName;

import mx.logging.LogLogger;

import org.as3yaml.nodes.*;
import org.idmedia.as3commons.util.*;

public class BaseConstructor implements Constructor {
    private static var yamlConstructors : Map = new HashMap();
    private static var yamlMultiConstructors : Map = new HashMap();
    private static var yamlMultiRegexps : Map = new HashMap();
   
    public function getYamlConstructor(key : Object) : YamlConstructor {
        var yamlCtor : YamlConstructorImpl = null;
        var ctor : Function = yamlConstructors.get(key)
        
        if (ctor != null){
	         yamlCtor =  new YamlConstructorImpl();
	         yamlCtor.callFunc = ctor       	
        }
        

        return yamlCtor;
    }

    public function getYamlMultiConstructor(key : Object) : YamlMultiConstructor {
        var yamlCtor : YamlMultiConstructorImpl = null;
        var ctor : Function = yamlMultiConstructors.get(key)
        
        if (ctor != null){
	         yamlCtor =  new YamlMultiConstructorImpl();
	         yamlCtor.callFunc = ctor       	
        }
        return yamlCtor;
    }

    public function getYamlMultiRegexp(key : Object) : RegExp {
        return yamlMultiRegexps.get(key) as RegExp;
    }

    public function getYamlMultiRegexps() : Map {
        return yamlMultiRegexps;
    }

    public static function addConstructor(tag : String, ctor : Function) : void {
        yamlConstructors.put(tag,ctor);
    }

    public static function addMultiConstructor(tagPrefix : String, ctor : Function) : void {
        yamlMultiConstructors.put(tagPrefix,ctor);
        yamlMultiRegexps.put(tagPrefix, new RegExp("^"+tagPrefix));
    }

    private var composer : Composer;
    private var constructedObjects : Map = new HashMap();
    private var recursiveObjects : Map = new HashMap();

    public function BaseConstructor(composer : Composer) {
        this.composer = composer;
    }

    public function checkData() : Boolean {
        return composer.checkNode();
    }

    public function getData() : Object {
        if(composer.checkNode()) {
            var node : Node = composer.getNode();
            if(null != node) {
                return constructDocument(node);
            }
        }
        return null;
    }

    
    public function eachDocument(ctor : Constructor) : Iterator {
        return new DocumentIterator(ctor);
    }

    public function iterator() : Iterator {
        return eachDocument(this);
    }
    
    public function constructDocument(node : Node) : Object {
        var data : Object = constructObject(node);
        constructedObjects.clear();
        recursiveObjects.clear();
        return data;
    }

    public function constructObject(node : Node) : Object {
        if(constructedObjects.containsKey(node)) {
            return constructedObjects.get(node);
        }
        if(recursiveObjects.containsKey(node)) {
            throw new ConstructorException(null,"found recursive node",null);
        }
        recursiveObjects.put(node,null);
        var ctor : YamlConstructor = getYamlConstructor(node.getTag());
        if(ctor == null) {
            var through : Boolean = true;
            var yamlMultiRegExps : Array = getYamlMultiRegexps().keySet().toArray();
            
            for each(var tagPrefix : String in yamlMultiRegExps) {
                var reg : RegExp = getYamlMultiRegexp(tagPrefix);
                if(reg.exec(node.getTag())) {
                    var tagSuffix : String = node.getTag().substring(tagPrefix.length);
                    ctor = new YamlMultiAdapter(getYamlMultiConstructor(tagPrefix),tagSuffix);
                    through = false;
                    break;
                }
            }
            if(through) {
                var xctor : YamlMultiConstructor = getYamlMultiConstructor(null);
                if(null != xctor) {
                    ctor = new YamlMultiAdapter(xctor,node.getTag());
                } else {
                    ctor = getYamlConstructor(null);
                    if(ctor == null) {
                        //ctor = CONSTRUCT_PRIMITIVE;
                    }
                }
            }
        }
        var data : Object = ctor.call(this,node);
        constructedObjects.put(node,data);
        recursiveObjects.remove(node);
        return data;
    }

    public function constructPrimitive(node : Node) : Object {
        if(node is ScalarNode) {
            return constructScalar(node);
        } else if(node is SequenceNode) {
            return constructSequence(node);
        } else if(node is MappingNode) {
            return constructMapping(node);
        } else {
            new LogLogger('error').error(node.getTag());
        }
        return null;
    }

    public function constructScalar(node : Node) : Object {
        if(!(node is ScalarNode)) {
            if(node is MappingNode) {
                var vals : Map = node.getValue() as Map;
                for(var iter : Iterator = vals.keySet().iterator();iter.hasNext();) {
                    var key : Node = iter.next() as Node;
                    if("tag:yaml.org,2002:value" == (key.getTag())) {
                        return constructScalar(Node(vals.get(key)));
                    }
                }
            }
            throw new ConstructorException(null,"expected a scalar node, but found " + getQualifiedClassName(node),null);
        }
        return node.getValue();
    }

    public function constructPrivateType(node : Node) : Object {
        var val : Object = null;
        if(node.getValue() is Map) {
            val = constructMapping(node);
        } else if(node.getValue() is List) {
            val = constructSequence(node);
        } else {
            val = node.getValue().toString();
        }
        return new PrivateType(node.getTag(),val);
    } 
    
    public function constructSequence(node : Node) : Object {
        if(!(node is SequenceNode)) {
            throw new ConstructorException(null,"expected a sequence node, but found " + getQualifiedClassName(node),null);
        }
        var internal : List = node.getValue() as List;
        var val : Array = new Array();
        for(var iter : Iterator = internal.iterator();iter.hasNext();) {
            val.push(constructObject(iter.next()));
        }
        return val;
    }

    public function constructMapping(node : Node) : Object {
        if(!(node is MappingNode)) {
            throw new ConstructorException(null,"expected a mapping node, but found " + getQualifiedClassName(node),null);
        }
        var mapping : Map = new HashMap();
        var merge : Array;
        var val : Map = node.getValue() as Map;
        for(var iter : Iterator = val.keySet().iterator();iter.hasNext();) {
            var key_v : Node = iter.next();
            var value_v : Node = val.get(key_v);
            if(key_v.getTag() == ("tag:yaml.org,2002:merge")) {
                if(merge != null) {
                    throw new ConstructorException("while constructing a mapping", "found duplicate merge key",null);
                }
                if(value_v is MappingNode) {
                    merge = new Array();
                    merge.push(constructMapping(value_v));
                } else if(value_v is SequenceNode) {
                    merge = new Array();
                    var vals : List = value_v.getValue() as List;
                    for(var sub : Iterator = vals.iterator();sub.hasNext();) {
                        var subnode : Node = sub.next();
                        if(!(subnode is MappingNode)) {
                            throw new ConstructorException("while constructing a mapping","expected a mapping for merging, but found " + getQualifiedClassName(subnode),null);
                        }
                        merge.unshift(constructMapping(subnode));
                    }
                } else {
                    throw new ConstructorException("while constructing a mapping","expected a mapping or list of mappings for merging, but found " + getQualifiedClassName(value_v),null);
                }
            } else if(key_v.getTag() == ("tag:yaml.org,2002:value")) {
                if(mapping.containsKey("=")) {
                    throw new ConstructorException("while construction a mapping", "found duplicate value key", null);
                }
                mapping.put("=",constructObject(value_v));
            } else {
                mapping.put(constructObject(key_v),constructObject(value_v));
            }
        }
        if(null != merge) {
            merge.push(mapping);
            mapping = new HashMap();
            for each(var item : Map in merge) {
                mapping.putAll(item);
            }
        }
        return mapping;
    }

    public function constructPairs(node : Node) : Object {
        if(!(node is MappingNode)) {
            throw new ConstructorException(null,"expected a mapping node, but found " + getQualifiedClassName(node), null);
        }
        var value : Array = new Array();
        var vals : Map = node.getValue() as Map;
        for(var iter : Iterator = vals.keySet().iterator();iter.hasNext();) {
            var key : Node = iter.next() as Node;
            var val : Node = vals.get(key) as Node;
            value.push([constructObject(key),constructObject(val)]);
        }
        return value;
    }
    
    
    public function constructOmap (node : Node) : Object {
        if(!(node is SequenceNode)) {
            throw new ConstructorException(null,"expected a sequence node, but found " + getQualifiedClassName(node), null);
        }
        var value : Array = new Array();
        var vals : List = node.getValue() as List;
		var addedKeyValHash : Object = new Object();
		
        for(var iter : Iterator = vals.iterator();iter.hasNext();) {  
            var val : Node = iter.next() as Node;
            var hash : Map = constructObject(val) as Map;
            
            if (hash.size() > 1)
            	throw new YAMLException("Each Map in an Ordered Map (!omap) is permitted to have only one key");
          
            var hashKey : Object = hash.keySet().toArray()[0];
            var hashValue : Object = hash.get(hashKey);
            
            if(!(addedKeyValHash[hashKey] && (addedKeyValHash[hashKey] == hashValue)))
            {
            	value.push(hash);
            	addedKeyValHash[hashKey] = hashValue;
            }
           
        }
        
        return value;    	
    }

    public static function CONSTRUCT_PRIMITIVE(self : Constructor, node : Node) : Object {
                return self.constructPrimitive(node);
            }
    public static function CONSTRUCT_SCALAR(self : Constructor, node : Node) : Object {
                return self.constructScalar(node);
            }
    public static function CONSTRUCT_PRIVATE(self : Constructor, node : Node) : Object {
                return self.constructPrivateType(node);
            }
    public static function CONSTRUCT_SEQUENCE(self : Constructor, node : Node) : Object {
                return self.constructSequence(node);
            }
    public static function CONSTRUCT_MAPPING(self : Constructor, node : Node) : Object {
                return self.constructMapping(node);
            }
}// BaseConstructorImpl
}
	
	import org.as3yaml.Constructor;
	import org.as3yaml.nodes.Node

	import org.idmedia.as3commons.util.Iterator;	

internal class DocumentIterator implements Iterator {
	
	private var _constructor : Constructor;
	
	public function DocumentIterator(ctor : Constructor) : void
	{
		_constructor = ctor;
	}
    public function hasNext() : Boolean {return _constructor.checkData();}
    public function next() : * {return _constructor.getData();}
    public function remove() : void {}
}
