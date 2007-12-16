package org.as3yaml.test
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import flexunit.framework.TestCase;
	
	import org.as3yaml.YAML;

	public class IssuesTest extends TestCase
	{
		
		
		public function IssuesTest (method : String = null) : void
		{
			super(method);
		}
		
		public function testIssueOne() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/issue1.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onTestIssueOne, 2000, loader));
		}
			
		public function onTestIssueOne(event : Event, ldr : URLLoader) : void
		{
			var yamlArray : Array  = YAML.decode(ldr.data) as Array;
			
			assertEquals(yamlArray.length, 7);
			assertEquals(yamlArray[0].get("tableName"), "building");
			assertEquals(yamlArray[0].get("name"), "Здания");
			assertEquals(yamlArray[3].get("name"), "Речки и озеры, моря");
			assertEquals(yamlArray[6].get("styleId"), 6);
		} 	
	}
}