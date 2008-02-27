package org.as3yaml.test
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import flexunit.framework.TestCase;
	
	import org.as3yaml.YAML;
	import org.idmedia.as3commons.util.HashMap;

	public class YamlComplexLoadTest extends TestCase
	{		
		public function YamlComplexLoadTest(methodName:String=null)
		{
			super(methodName);
		}
		
		public function testComplexLoadTest1() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('org/as3yaml/test/files/complexYamlTest1.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onComplexLoadTest1, 2000, loader));
		}
			
		public function onComplexLoadTest1(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			var yamlMap : Dictionary = Dictionary(yamlObj.value);
			assertEquals(yamlMap["ship-to"].family, "Dumars");
			assertEquals(yamlMap.product[1].description, "Super Hoop");
			assertEquals(yamlMap.total, 4443.52);
		}
		
		public function testComplexLoadTest2() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('org/as3yaml/test/files/complexYamlTest2.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onComplexLoadTest2, 2000, loader));
		}
			
		public function onComplexLoadTest2(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
	        var yamlMap : Dictionary = Dictionary(yamlObj);    
	        
			assertEquals(yamlMap.Stack[0].code, 'x = MoreObject("345\\n")');
		}	

		public function testComplexLoadTest3() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('org/as3yaml/test/files/railsDBConfigTest.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onComplexLoadTest3, 2000, loader));
		}
			
		public function onComplexLoadTest3(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
	        var yamlMap : Dictionary = Dictionary(yamlObj);
		
			assertEquals(yamlMap.test.username, "root");
		}
	}
}