package;
import idnet.Social;
import idnet.SocialBase;
import idnet.HashToJson;
import com.stencyl.Engine;
import haxe.Json;

class IDNetWrapper {
	public static var instance:Social;
	public static var isLoaded:Bool;
	public static var inBlackList:Bool;
	public static var userName:String;
	public static var sessionKey:String;
	public static var retrieveUserDataCallback:Void->Void;

    public static function initialize(appId:String, appSecret:String, debug:Int = 0, preload:Int = 0):Void
    {
		trace("appId: "+appId+" appSecret:"+appSecret);
		
		IDNetWrapper.inBlackList = false;
		IDNetWrapper.instance = new Social();
		trace('social created');
		IDNetWrapper.instance.init(appId, appSecret, (debug==0?false:true), (preload==0?false:true));
		trace('complete');
    }
	
	public static function showPopup(name:Int):Void
    {
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			switch(name) {
				case 0: IDNetWrapper.instance.register();
				case 1: IDNetWrapper.instance.loginPopup();
				case 2: IDNetWrapper.instance.scoreboard();
				case 3: IDNetWrapper.instance.achievementsList();
			}
		}
	}
	
	public static function removeUserData(key:String):Void {
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			IDNetWrapper.instance.removeUserData(key);
		}
	}
	
	public static function retrieveUserData(key:String, onComplete:Void->Void=null):Void
	{ 
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			IDNetWrapper.instance.retrieveUserData(key);
			
			IDNetWrapper.retrieveUserDataCallback = onComplete;
		}
	}
	
	public static function loadData(dataString:String):Void
	{
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			var data:Array<Dynamic> = Json.parse(dataString);
			if(data != null && Engine.engine.gameAttributes != null) {
				for(i in 0...data.length) {
					Engine.engine.gameAttributes.set(data[i].key, HashToJson.jsonToElement(data[i].value));
				}
			}
			
			if(IDNetWrapper.IDNetWrapper.retrieveUserDataCallback != null) {
				Reflect.callMethod(IDNetWrapper, IDNetWrapper.retrieveUserDataCallback, []);
			}
		}
	} 
	
	public static function submitUserData(key:String):Void
	{ 
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			var data:String = "";
			if(Engine.engine.gameAttributes != null) {
				data += "[";
				for(key in Engine.engine.gameAttributes.keys())
				{
					data += '{"key":"'+key+'","value":'+HashToJson.elementToJson(Engine.engine.gameAttributes.get(key))+'},';
				}
				data = data.substr(0, data.length - 1) + "]";
			}
			
			IDNetWrapper.instance.submitUserData(key, data);
		}
	}
	
	public static function submitScore(score:Int):Void
	{
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			IDNetWrapper.instance.submitScore(score);
		}
	}
	
	public static function achievementsSave(name:String, key:String):Void
	{
		IDNetWrapper.instance.achievementsSave(name, key);
	}
	
	public static function isAuthorized():Bool
	{ 
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			return IDNetWrapper.instance.isAuthorized(); 
		} else {
			return false;
		}
	}
	
	public static function InterfaceOpen():Bool
	{ 
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			return IDNetWrapper.instance.InterfaceOpen();
		} else {
			return false;
		}
	}
	
	public static function isInit():Bool
	{
		return IDNetWrapper.isLoaded;
	}
	
	public static function logout():Void
	{ 
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			IDNetWrapper.instance.logout();  
		}
	}
	
	public static function getName():String
	{
		if(IDNetWrapper.instance != null && IDNetWrapper.isLoaded) {
			return IDNetWrapper.userName;
		} else {
			return "";
		}
	}
	
	public static function domainInBlackList():Bool
	{
		return IDNetWrapper.inBlackList;
	}
}