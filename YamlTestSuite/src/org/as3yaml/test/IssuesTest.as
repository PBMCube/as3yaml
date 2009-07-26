package org.as3yaml.test
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import flexunit.framework.TestCase;
	
	import org.as3yaml.YAML;
	import org.as3yaml.YamlDecoder;

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
			loader.addEventListener(Event.COMPLETE, addAsync(onTestIssueFour, 2000, loader));
		}
			
		public function onTestIssueFour(event : Event, ldr : URLLoader) : void
		{
			var data: String = ldr.data;
			var start: Number = flash.utils.getTimer();
			var yaml : Dictionary  = new YamlDecoder(data).decode() as Dictionary;
			trace(flash.utils.getTimer() - start);
	        assertTrue((flash.utils.getTimer() - start) < 350);			
		}
		
		public function testIssueFive() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('org/as3yaml/test/files/issue5.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onTestIssueFive, 2000, loader));
		}
			
		public function onTestIssueFive(event : Event, ldr : URLLoader) : void
		{
			var yaml : Array  = YAML.decode(ldr.data) as Array;
			var nov: Date = yaml[0].consumed_at as Date;
			var feb: Date = yaml[1].consumed_at_tz as Date;
			
			assertEquals(nov.month, 10);
			assertEquals(nov.toDateString(), "Mon Nov 12 2007");
			assertEquals(feb.month, 1);
			assertEquals(feb.toDateString(), "Mon Feb 4 2008")
		}
		
		public function testIssueTen() : void
		{
			var s:String = '';
			for (var i:uint = 0;i<184000;i++) {s +='x';}
			var ystr:String = "---\n field1 : value1\n field2 : " + s + "\n";
			var start: Number = flash.utils.getTimer();   
			var d:Dictionary = YAML.decode(ystr) as Dictionary;
			assertTrue((flash.utils.getTimer() - start) < 1000);			
			
		}				

		public function testIssueTwelve() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('org/as3yaml/test/files/issue12.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onTestIssueTwelve, 2000, loader));
		}
			
		public function onTestIssueTwelve(event : Event, ldr : URLLoader) : void
		{
			var data: String = ldr.data;
			var y: Object = YAML.decode(data);
			var foos : Array  = y.Foos as Array;
			var stages : Array = y.stages as Array;
	        assertTrue(foos[0].id, 4);	
	        assertTrue(foos[2].name, 3004359912);		
	        assertTrue(stages.length, 6)
		}
			
	}
}