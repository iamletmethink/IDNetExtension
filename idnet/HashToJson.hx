package idnet;
import haxe.ds.StringMap;

class HashToJson {
	
	public static function elementToJson(value:Dynamic):String
	{
		var data:String;
		
		if(Std.is(value, String)) {
			return '"'+value+'"';
		} else if(Std.is(value, Int) || Std.is(value, Float)) {
			return value;
		} else if(Std.is(value, Bool)) {
			return (value?'true':'false');
		} else if(Std.is(value, Array)) {
			data = '[';
			for(i in 0...value.length) {
				data += HashToJson.elementToJson(value[i])+',';
			}
			data = data.substr(0, data.length - 1) + ']';
			return data;
		} else if(Std.is(value, StringMap)) {
			data = "{";
			var value2:StringMap<Dynamic> = value;
			for(key in value2.keys())
			{
				data += '"'+key+'":'+HashToJson.elementToJson(value2.get(key))+',';
			}
			data = data.substr(0, data.length - 1) + "}";
			return data;
		}
		
		return "";
	}
	
	public static function jsonToElement(value:Dynamic):Dynamic
	{
		trace(value);
		
		if(Std.is(value, String)) {
			trace("String");
			return value;
		} else if(Std.is(value, Int) || Std.is(value, Float)) {
			trace("Int/Float");
			return value;
		} else if(Std.is(value, Bool)) {
			var boolValue:Bool = value;
			return boolValue;
		} else if(Std.is(value, Array)) {
			var array:Array<Dynamic> = value;
			return array;
		} else if(Std.is(value, Dynamic)) {
			trace("StringMap");
			var map:StringMap<Dynamic> = new StringMap();
			var fields:Array<String> = Reflect.fields(value);
			if(fields != null && fields.length > 0) {
				for(i in 0...fields.length) {
					if(Reflect.hasField(value, fields[i])) {
						map.set(fields[i], Reflect.field(value, fields[i]));
					}
				}
			}
			
			return map;
		}
		
		return null;
	}
}