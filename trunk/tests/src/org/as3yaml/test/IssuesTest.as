package org.as3yaml.test
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
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
			loader.load(new URLRequest('org/as3yaml/test/files/issue1.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onTestIssueOne, 2000, loader));
		}
			
		public function onTestIssueOne(event : Event, ldr : URLLoader) : void
		{
			var yamlArray : Array  = YAML.decode(ldr.data) as Array;
			
			assertEquals(yamlArray.length, 7);
			assertEquals(yamlArray[0].tableName, "building");
			assertEquals(yamlArray[0].name, "Здания");
			assertEquals(yamlArray[3].name, "Речки и озеры, моря");
			assertEquals(yamlArray[6].styleId, 6);
		}
		
		public function testIssueFour() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('org/as3yaml/test/files/issue4.yaml'));
			loader.addEventListener(Event.COMPLETE, onTestIssueFour);
		}
			
		public function onTestIssueFour(event : Event) : void
		{
			var start: Number = flash.utils.getTimer();
			var yaml : Dictionary  = YAML.decode(event.currentTarget.data) as Dictionary;
	        assertTrue((flash.utils.getTimer() - start) < 300);			
			
		}
			
	}
}