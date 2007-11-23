package org.rxr.actionscript.io {


	/**
	 * 
	 * Very simple class for reading a string character by character.
	 * 
	 * @author wischusen
	 * 
	 */	
	public class StringReader  {
		
		private var _content:String;
		private var _index:uint = 0;
		
		public function StringReader(content:String) {
			_content = content;
		}
		
		public function read():String {
			return _content.charAt(_index++);
		}
		
		public function readArray(offset:uint = 0, length:uint = 0):Array {
			if(length == 0) {
				length = _content.length - offset;
			}
			
			
			var array:Array = new Array();
			for(var i:uint = offset; i < length; i++) {
				array.push(_content.charAt(_index++));
			}
			return array;
		}
		
		public function readFor(offset:uint, length:uint) : Array
		{
			var start : uint = _index + offset;	 
			var charsRead : uint = (start + length) < _content.length ? length : _content.length - start;		 
			var str : String = _content.substr(start, charsRead);
			 _index += charsRead;
			return [charsRead, str];
		}
		
		public function readString():String {
			return _content;
		}
		
		public function hasNext():Boolean {
			return _index < _content.length;
		}
		
	}
}