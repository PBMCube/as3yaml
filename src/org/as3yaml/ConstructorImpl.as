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

    import org.idmedia.as3commons.util.HashMap;
    import org.idmedia.as3commons.util.HashSet;
    import org.idmedia.as3commons.util.Map;
    import org.idmedia.as3commons.util.Set;;
	
	public class ConstructorImpl extends SafeConstructor 
	{
	    private static var yamlConstructors : HashMap = new HashMap();
	    private static var yamlMultiConstructors : HashMap = new HashMap();
	    private static var yamlMultiRegexps : HashMap = new HashMap();
	    
	    override public function getYamlConstructor(key : Object) : YamlConstructor
	    {
	        var mine : YamlConstructor = YamlConstructor(yamlConstructors.get(key));
	        if(mine == null) {
	            mine = super.getYamlConstructor(key);
	        }
	        return mine;
	    }
	
	   override public function getYamlMultiConstructor(key : Object) : YamlMultiConstructor {
	        var mine : YamlMultiConstructor = yamlMultiConstructors.get(key) as YamlMultiConstructor;
	        if(mine == null) {
	            mine = super.getYamlMultiConstructor(key);
	        }
	        return mine;
	    }
	
	    override public function getYamlMultiRegexp(key : Object) : RegExp {
	        var mine : RegExp =  yamlMultiRegexps.get(key);
	        if(mine == null) {
	            mine = super.getYamlMultiRegexp(key);
	        }
	        return mine;
	    }
	
	    override public function getYamlMultiRegexps() : Map {
	        var all : Map = new HashMap();
	        all.putAll(super.getYamlMultiRegexps());
	        all.putAll(yamlMultiRegexps);
	        return all;
	    }
	
	    public static function addConstructor(tag : String, ctor : YamlConstructor) : void {
	        yamlConstructors.put(tag,ctor);
	    }
	
	    public static function addMultiConstructor(tagPrefix : String, ctor : YamlMultiConstructor) : void {
	        yamlMultiConstructors.put(tagPrefix,ctor);
	        yamlMultiRegexps.put(tagPrefix,new RegExp("^"+tagPrefix));
	    }
	
	    public function ConstructorImpl( composer : Composer) {
	        super(composer);
	    }
	
	}
}