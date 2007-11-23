package org.as3yaml.test
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
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
			loader.load(new URLRequest('files/complexYamlTest1.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onComplexLoadTest1, 2000, loader));
		}
			
		public function onComplexLoadTest1(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			var yamlMap : HashMap = HashMap(yamlObj.value);
			assertEquals(yamlMap.get("ship-to").get("family"), "Dumars");
			assertEquals(yamlMap.get("product")[1].get("description"), "Super Hoop");
			assertEquals(yamlMap.get("total"), 4443.52);
		}
		
		public function testComplexLoadTest2() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/complexYamlTest2.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onComplexLoadTest2, 2000, loader));
		}
			
		public function onComplexLoadTest2(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
	        var yamlMap : HashMap = HashMap(yamlObj);
	        
			assertEquals(yamlMap.get("Stack")[0].get("code"), 'x = MoreObject("345\\n")');
		}	

		public function testComplexLoadTest3() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/railsDBConfigTest.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onComplexLoadTest3, 2000, loader));
		}
			
		public function onComplexLoadTest3(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
	        var yamlMap : HashMap = HashMap(yamlObj);
		
			assertEquals(yamlMap.get("test").get("username"), "root");
		}
	}
}