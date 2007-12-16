package org.as3yaml.test
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import flexunit.framework.TestCase;
	
	import mx.containers.TitleWindow;
	import mx.controls.*;
	import mx.core.Application;
	import mx.managers.PopUpManager;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import org.as3yaml.YAML;
	import org.idmedia.as3commons.util.HashMap;
	import org.idmedia.as3commons.util.Map;

	public class YamlLoadTest extends TestCase
	{
		public function YamlLoadTest (method : String = null) : void
		{
			super(method);
		}

		public function testBasicStringScalarLoad() : void 
		{
		    assertEquals("str",YAML.decode("--- str"));
 		    assertEquals("str",YAML.decode("---\nstr"));
		    assertEquals("str",YAML.decode("--- \nstr"));
		    assertEquals("str",YAML.decode("--- \n str"));
		    assertEquals("str",YAML.decode("str"));
		    assertEquals("str",YAML.decode(" str"));
		    assertEquals("str",YAML.decode("\nstr"));
		    assertEquals("str",YAML.decode("\n str"));
		    assertEquals("str",YAML.decode("\"str\""));
		    assertEquals("str",YAML.decode("'str'")); 
		}
		
		public function testBasicIntegerScalarLoad() : void 
		{
		    assertEquals(47,YAML.decode("47"));
		    assertEquals(0,YAML.decode("0")); 
		    assertEquals(-1,YAML.decode("-1"));
		}
		
		public function testBasicListLoad() : void 
		{	
	        var ex : Array = new Array("a", "b", "c");
	        var y : Object = YAML.decode("--- \n- a\n- b\n- c\n");
	        assertEquals(ex[0], y[0]);
	        assertEquals(ex[1], y[1]);
	        assertEquals(ex[2], y[2]);			
		}
		
		public function testBlockMappingLoad() : void 
		{
		    var expected : Map = new HashMap();
		    expected.put("a","b");
		    expected.put("c","d");
		    assertEquals("b", HashMap(YAML.decode("a: b\nc: d")).get("a"));
		    assertEquals("d" , HashMap(YAML.decode("c: d\na: b\n")).get("c"));
		}
		
		public function testFlowMappingLoad() : void 
		{
		    var expected : Map = new HashMap();
		    expected.put("a","b");
		    expected.put("c","d");
		    assertEquals("b", HashMap(YAML.decode("{a: b, c: d}")).get("a"));
		    assertEquals("d" , HashMap(YAML.decode("{c: d,\na: b}")).get("c"));
		}
		
		public function testBuiltinTag() : void 
		{
		    assertEquals("str",YAML.decode("!!str str"));
		    assertEquals("str",YAML.decode("%YAML 1.1\n---\n!!str str"));
		    assertEquals("str",YAML.decode("%YAML 1.0\n---\n!str str"));
		}
		
		public function testDirectives() : void 
		{
		    assertEquals("str",YAML.decode("%YAML 1.1\n--- !!str str"));
		    assertEquals("str",YAML.decode("%YAML 1.1\n%TAG !yaml! tag:yaml.org,2002:\n--- !yaml!str str"));
		    try {
		        YAML.decode("%YAML 1.1\n%YAML 1.1\n--- !!str str");
		        fail("should throw exception when repeating directive");
		    } catch(e : Error) {
		        assertTrue(true);
		    }
		}
		
	    public function testActionScriptObjectLoad() : void {
	        var date : Date =  new Date(1979, 11, 25);
	        var testObj : TestActionScriptObject =  new TestActionScriptObject();
	        testObj.firstname = "Derek";
	        testObj.lastname = "Wischusen";
	        testObj.birthday = date;
	        
	        var yamlObj : Object = YAML.decode("--- !actionscript/object:org.as3yaml.test.TestActionScriptObject\nfirstname: Derek\nlastname: Wischusen\nbirthday: 1979-12-25\n")
	        
	        assertTrue(yamlObj is TestActionScriptObject);
	        var yamlASObj : TestActionScriptObject = yamlObj as TestActionScriptObject;
	        assertEquals(testObj.firstname, yamlASObj.firstname);
	        assertEquals(testObj.lastname, yamlASObj.lastname);
	        assertEquals(testObj.birthday.getTime(), yamlASObj.birthday.getTime());
	    }
	   
		public function testSequenceOfScalars() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/sequenceOfScalars.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onSequenceOfScalars, 2000, loader));
		}
			
		public function onSequenceOfScalars(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);		
			assertEquals(yamlObj[1], "Sammy Sosa");
		}
		
		public function testMappingScalarsToScalars() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/mappingScalarsToScalars.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onMappingScalarsToScalars, 2000, loader));
		}
			
		public function onMappingScalarsToScalars(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertEquals(HashMap(yamlObj).get("rbi"), 147);
		} 		 

		public function testSequenceOfMappings() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/sequenceOfMappings.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onSequenceOfMappings, 2000, loader));
		}
			
		public function onSequenceOfMappings(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertTrue(yamlObj[0] is HashMap);
			var yamlHash : HashMap = yamlObj[0] as HashMap;
			assertEquals(yamlHash.get("avg"), 0.278);
		}

		public function testMappingOfMappings() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/mappingOfMappings.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onMappingOfMappings, 2000, loader));
		}
			
		public function onMappingOfMappings(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertTrue(HashMap(yamlObj).get("Sammy Sosa") is HashMap);
			var yamlHash : HashMap = HashMap(yamlObj).get("Sammy Sosa") as HashMap;
			assertEquals(yamlHash.get("hr"), 63);
		} 		 	    		

		public function testMappingBetweenSequences() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/mappingBetweenSequences.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onMappingBetweenSequences, 2000, loader));
		}
			
		public function onMappingBetweenSequences(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);		
			var keys : Array = HashMap(yamlObj).keySet().toArray();
			
			var val1 : Date = yamlObj.get(keys[0])[0];
			var val2 : Date = yamlObj.get(keys[1])[1];
					
			assertEquals(val1.date, 23);
			assertEquals(val1.month, 6);
			assertEquals(val2.date, 12);
		} 		 	    		


		public function testSingleDocTwoComments() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/singleDocTwoComments.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onSingleDocTwoComments, 2000, loader));
		}
			
		public function onSingleDocTwoComments(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertTrue(HashMap(yamlObj).get("rbi") is Array);
			var yamlList : Array = HashMap(yamlObj).get("rbi") as Array;			
			assertTrue(yamlList.length == 2);
			assertEquals(yamlList[1], "Ken Griffey")
		} 	

		public function testAlias() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/alias.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onAlias, 2000, loader));
		}
			
		public function onAlias(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertTrue(HashMap(yamlObj).get("rbi") is Array);
			var yamlList : Array = HashMap(yamlObj).get("rbi") as Array;
			assertEquals(yamlList[0], "Sammy Sosa");
		} 

		public function testSequenceOfMaps() : void 
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/sequenceOfMaps.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onSequenceOfMaps, 2000, loader));
		}
			
		public function onSequenceOfMaps(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			
			var map1 : HashMap = yamlObj[0] as HashMap;
			var map2 : HashMap = yamlObj[1] as HashMap;
			
			assertEquals(map1.get("also"), "inner");
			assertEquals(map2.get("last"), "entry");
		} 
		
		public function testInLineNestedMapping() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/inLineNestedMapping.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onInLineNestedMapping, 2000, loader));
		}
			
		public function onInLineNestedMapping(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);

			var map1 : HashMap = yamlObj[0] as HashMap;
			var map2 : HashMap = yamlObj[1] as HashMap;
			var map3 : HashMap = yamlObj[2] as HashMap;
			
			assertEquals(map1.get("item"), "Super Hoop");
			assertEquals(map2.get("quantity"), 4);
			assertEquals(map3.get("item"), "Big Shoes");
		} 		
	
		public function testLiterals() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/literals.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onLiterals, 2000, loader));
		}
			
		public function onLiterals(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertEquals(yamlObj, "\\//||\\/||\n// ||  ||__");
		}

		public function testSequenceOfSequences() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/sequenceOfSequences.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onSequenceOfSequences, 2000, loader));
		}
			
		public function onSequenceOfSequences(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertEquals(yamlObj[2][2], 0.288);
		} 
		
		public function testPlainScalars() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/plainScalars.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onPlainScalars, 2000, loader));
		}
			
		public function onPlainScalars(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertEquals(yamlObj, "Mark McGwire's\nyear was crippled\nby a knee injury.");
		} 
		
		public function testFoldedNewline() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/foldedNewline.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onFoldedNewline, 2000, loader));
		}
			
		public function onFoldedNewline(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertTrue(yamlObj is String);
		} 
		
		public function testIndentationScope() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/indentationScope.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onIndentationScope, 2000, loader));
		}
			
		public function onIndentationScope(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertEquals(yamlObj.get("name"), "Mark McGwire");
		} 
		
		public function testQuotedScalars() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/quotedScalars.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onQuotedScalars, 2000, loader));
		}
			
		public function onQuotedScalars(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);

			assertEquals(yamlObj.get("unicode"), "Sosa did fine.\u263a");
			assertEquals(yamlObj.get("hexesc"), "\r\n");
			assertEquals(yamlObj.get("control"), "\b1998\t1999\t2000\n");
			assertEquals(yamlObj.get("single"), '"Howdy!" he cried.');
			assertEquals(yamlObj.get("quoted"), " # not a 'comment'.");
			assertEquals(yamlObj.get("tie-fighter"), '|\\-*-/|');
		} 

		public function testMultilineFlowScalars() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/multilineFlowScalars.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onMultilineFlowScalars, 2000, loader));
		}
			
		public function onMultilineFlowScalars(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertTrue(yamlObj.get("plain") is String);
			assertTrue(yamlObj.get("quoted") is String);
			
		} 
		
		public function testIntegerTags() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/integerTags.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onIntegerTags, 2000, loader));
		}
			
		public function onIntegerTags(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertEquals(yamlObj.get("sexagecimal"), 12345);
			assertEquals(yamlObj.get("sexagecimal"), yamlObj.get("canonical"));
			assertEquals(yamlObj.get("octal"), yamlObj.get("hexadecimal"));
			assertEquals(yamlObj.get("decimal"), yamlObj.get("canonical"));
		} 
		
		public function testFloatingPointTags() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/floatingPointTags.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onFloatingPointTags, 2000, loader));
		}
			
		public function onFloatingPointTags(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertEquals(yamlObj.get("canonical"), 1230.15);
			assertEquals(yamlObj.get("canonical"), yamlObj.get("exponential"));
			assertEquals(yamlObj.get("exponential"), yamlObj.get("sexagecimal"));
			assertEquals(yamlObj.get("negative infinity"), Number.NEGATIVE_INFINITY);
			assertTrue(isNaN(yamlObj.get("not a number")));
		} 
		
		public function testMiscellaneousTags() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/miscellaneousTags.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onMiscellaneousTags, 2000, loader));
		}
			
		public function onMiscellaneousTags(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			assertEquals(yamlObj.get("string"), "12345");
		} 
		
		public function testTimestampTags() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/timestampTags.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onTimestampTags, 2000, loader));
		}
			
		public function onTimestampTags(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
		
			var iso : Date = yamlObj.get("iso8601") as Date;
			var date : Date = yamlObj.get("date") as Date;
			var canonical : Date = yamlObj.get("canonical") as Date;
			var spaced : Date = yamlObj.get("spaced") as Date;
			assertEquals(iso.getMonth(), 11);
			assertEquals(date.getFullYear(), 2002);
			assertEquals(canonical.getDate(), 15);
			assertEquals(canonical.getDay(), 6);
			assertEquals(spaced.getHours(), 21);
		} 
		
		public function testExplicitTags() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/explicitTags.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onExplicitTags, 2000, loader));
		}
	
		public function onExplicitTags(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			var pictBytes : ByteArray = yamlObj.get("picture");
			var img : Image =  new Image();	
			var win : TitleWindow = new TitleWindow();
			win.width = 200;
			win.height = 200;			
			win.addChild(img);
			var loader : flash.display.Loader = new flash.display.Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBytesLoaded);
			loader.loadBytes(pictBytes);
			function onBytesLoaded (event : Event) : void
			{
				var content : DisplayObject = LoaderInfo( event.target ).content;
				var bitmapData : BitmapData = new BitmapData( content.width, content.height );
				bitmapData.draw( content );
				img.source = new Bitmap(bitmapData);				
				PopUpManager.addPopUp(win, DisplayObject(Application.application));
			}					
			assertTrue(yamlObj.get("not-date") is String);
		} 
	
		
		public function testGlobalTags() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/globalTags.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onGlobalTags, 2000, loader));
		}
			
		public function onGlobalTags(event : Event, ldr : URLLoader) : void
		{
			try{
				var yamlObj : Object = YAML.decode(ldr.data);
				var btn : Button = yamlObj[0] as Button;
				var lbl : Label = yamlObj[1] as Label;
				var ta : TextArea = yamlObj[2] as TextArea;
				var win : TitleWindow = yamlObj[3] as TitleWindow;
				win.addChild(btn);
				win.addChild(lbl);
				win.addChild(ta);
				
				PopUpManager.addPopUp(win, DisplayObject(Application.application));
				assertTrue(true);				
			}catch(e : Error) {
				assertTrue(false);
			}

			
		} 

		public function testOrderedMap() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/orderedMap.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onOrderedMap, 2000, loader));
		}
		
		public function onOrderedMap(event : Event, ldr : URLLoader) : void
		{
			var yamlList : Array = YAML.decode(ldr.data) as Array
			
			//there are four entries in the file, but one is a duplicate so it should get removed.
			assertEquals(yamlList.length, 3);
			
			assertEquals(yamlList[1].get("Sammy Sosa"), 63);
			assertEquals(yamlList[2].get("Ken Griffy"), 58);
		}
		
		public function testMerge() : void
		{
			var loader : URLLoader =  new URLLoader();
			loader.load(new URLRequest('files/mergeKey.yaml'));
			loader.addEventListener(Event.COMPLETE, addAsync(onTestMerge, 2000, loader));
		}
		
		public function onTestMerge(event : Event, ldr : URLLoader) : void
		{
			var yamlObj : Object = YAML.decode(ldr.data);
			

			var map1 : HashMap = yamlObj[4];
			var map2 : HashMap = yamlObj[5];			
			var map3 : HashMap = yamlObj[6];
			var map4 : HashMap = yamlObj[7];
			assertEquals(map1.get("x"),map2.get("x"));
			assertEquals(map2.get("x"), map3.get("x"));
			assertEquals(map3.get("x"), map4.get("x"));
			assertEquals(map4.get("y"), map1.get("y"));
			assertEquals(map2.get("r"), 10);
			assertEquals(map2.get("r"), map3.get("r"));
		}
		
		   	
	}
}