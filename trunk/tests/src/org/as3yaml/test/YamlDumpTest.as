package org.as3yaml.test
{
	import flash.utils.ByteArray;
	
	import flexunit.framework.TestCase;
	
	import org.as3yaml.YAML;
	import org.idmedia.as3commons.util.HashMap;
	import org.idmedia.as3commons.util.Map;
	
	
	public class YamlDumpTest extends TestCase
	{
		public function YamlDumpTest(methodName:String=null)
		{
			super(methodName);
		}
		
	    public function testBasicStringDump() : void  
	    {
	        assertEquals("--- str\n", YAML.encode("str"));
	    }
	    
	    public function testBasicHashDump() : void
	    {
	        var ex : Map = new HashMap();
	        ex.put("a","b");
	        assertEquals("--- \na: b\n", YAML.encode(ex));
    	}
    	
	    public function testNestedHashDump() : void
	    {
	        var customers : Map = new HashMap();
	        var customer : Map = new HashMap();
	        customers.put("customer", customer);
	        customer.put("firstname", "Derek");
	        customer.put("lastname", "Wischusen");
	        customer.put("items", ["skis", "boots", "jacket"]);
	        assertEquals("--- \ncustomer: \n  firstname: Derek\n  lastname: Wischusen\n  items: \n    - skis\n    - boots\n    - jacket\n", YAML.encode(customers));
    	}    	

	    public function testBasicListDump() : void
	    {
	        var ex : Array = new Array("a","b","c");
	        assertEquals("--- \n- a\n- b\n- c\n", YAML.encode(ex));
	    }
	    
	    public function testMoreScalars() : void  
	    {
	        assertEquals("--- !!str 1.0\n", YAML.encode("1.0"));
	    }
	    
		public function testDumpActionScriptObject() : void {
		    var testObj : TestActionScriptObject =  new TestActionScriptObject();
		    testObj.firstname = "Derek";
		    testObj.lastname = "Wischusen";
		    testObj.birthday = new Date(1979, 11, 25);
		    assertEquals("--- !actionscript/object:org.as3yaml.test.TestActionScriptObject\nbirthday: 1979-12-25 24:00:00 -05:00\nfirstname: Derek\nlastname: Wischusen\n", YAML.encode(testObj));
		   
		}
		
		import mx.utils.Base64Decoder;
		public function testDumpBinary() : void {
			
			var decoder : Base64Decoder = new Base64Decoder();
			decoder.decode("R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLCAgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=");
			
			var ba : ByteArray = decoder.flush();
			var map : Map = new HashMap();
			map.put("arrow", ba)
		    var res : String = YAML.encode(map)
	   		assertEquals(res, "--- \narrow: !!binary |\n  R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5OTk6enp56enmlp\n  aWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++f/++SH+Dk1h\n  ZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLCAgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYN\n  G84BwwEeECcgggoBADs=\n");
		}		
	}
}