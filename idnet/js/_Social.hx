package idnet.js;
import haxe.Http;
import haxe.Json;
import haxe.Timer;
import idnet.common.events.IDNetEvent;
import idnet.common.events.PostStatusEvent;
import idnet.common.FeedParameters;
import js.Browser;
import js.html.Document;
import js.html.HTMLDocument;
import js.html.ScriptElement;
import openfl.Lib;

class _Social extends SocialBase {
	
	//
	// Static helper variables
	//
	private static inline var SCRIPT_ID:String = 'id-jssdk';
	private static inline var HTTP_API_PATH:String = 'http://cdn.id.net/api/sdk.js';
	private static inline var HTTPS_API_PATH:String = 'https://scdn.id.net/api/sdk.js';

	
	//
	// Constructor
	//
	
    public function new() { 
		super(); 
	
		_document = Browser.document; 
		_unsafeWindow = cast _document.defaultView;
	}

	
	//
	// Variables
	//
	
	private var _document:HTMLDocument;
	private var _unsafeWindow:Dynamic;
	private var _ID:Dynamic;
	
	
	//
	// API
	//
	/**
	 * This code will insert Into dom a loader script for id net SDK
	 * 
	 * In the same moment a callback to 'window' will be set, for idnet SDK
	 * to call when it's ready
	 */
    override public function init():Void 
	{
		if (_document.getElementById(SCRIPT_ID) != null) {
			throw 'Error: Double id.net initialization';
			return;
		}
		
		var idnetSDKloader = _document.createScriptElement();
		idnetSDKloader.id = SCRIPT_ID;
		

		idnetSDKloader.src = _document.location.protocol == 'https:' ? HTTPS_API_PATH : HTTP_API_PATH;
		_document.head.insertBefore(idnetSDKloader, _document.getElementsByTagName('script')[0]);
		
		_unsafeWindow.idAsyncInit = asyncInit;
    }
	
	/**
	 * Make register attempt to ID. If sdk finds a cookie, it will 
	 * attempt to authorize instead.
	 */
	override public function register():Void 
	{
		_ID.register(registerCallback);
	}
	
	override public function loginPopup():Void 
	{
		_ID.login(registerCallback);
	}
	
	override public function scoreboard():Void 
	{
		//_ID.scoreboard(registerCallback);
	}
	
	override function removeUserData(key:String):Void {
	
	}
	
	override public function retrieveUserData(key:String):String
	{ 
		return null;
	}
	
	override public function submitUserData(key:String, data:String):Void
	{ 
	
	}
	
	override public function submitScore(score:Int):Void
	{

	}
	
	override public function achievementsList():Void
	{
	
	}
	
	override public function achievementsSave(name:String, key:String):Void
	{

	}
	
	/**
	 * Post to you feed via ID.ui
	 */
	override public function postToFeed(params:FeedParameters):Void 
	{
		if (!authorized) {
			d.dispatchPostStatus(PostStatusEvent.FEED_POST_FAIL, null, PostStatusEvent.REASON_NOT_AUTHORIZED);
			return;
		}
		
		//todo: parameters should be validated here:
		
		_ID.ui(params.serialize(), feedPostCallback); 
	}
	
	
	//
	// ID.net sdk callbacks
	//
	/**
	 * At this poInt idnet SDK is fully loaded and ready to be called.
	 */
	private function asyncInit():Void 
	{
		_ID = _unsafeWindow.ID;
		
		_ID.Event.subscribe(IDNetEvent.ID_INITIALIZE_COMPLETE, onIDInitializeComplete);
		_ID.Event.subscribe(IDNetEvent.ID_AUTH_RESPONSE_CHANGE, onIDAuthResponseChange);
		
		_ID.init(this.params);
	}
	
	/**
	 * Notify completing/failing registration
	 */
	private function registerCallback(response:Dynamic):Void 
	{
		if (response == null) {
			d.dispatch(IDNetEvent.ID_AUTH_FAIL);
		} else {
			d.dispatch(IDNetEvent.ID_AUTH_COMPLETE);
		}
	}
	
	/**
	 * Notify completing/failing posting to feed
	 */
	private function feedPostCallback(response:Dynamic):Void
	{
		if (response == null || response.post_id == null) {
			d.dispatchPostStatus(PostStatusEvent.FEED_POST_FAIL, null, PostStatusEvent.REASON_UNKNOWN);
			
			// stub
			_document.defaultView.alert('post failed');
		} else {
			d.dispatchPostStatus(PostStatusEvent.FEED_POST_SUCCESS, response.post_id);
			
			// stub
			_document.defaultView.alert('successfully posted. check your feed.');
		}
	}
	
	
	//
	// Event listeners
	//
	private function onIDInitializeComplete():Void 
	{
		trace('ID.initializeComplete');
		d.dispatch(IDNetEvent.ID_INITIALIZE_COMPLETE);
	}
	
	private function onIDAuthResponseChange(response:Dynamic):Void 
	{
		untyped __js__('window.idnet_autologin = function(response){');
		untyped __js__('IDNetWrapper.sessionKey = response.sessionKey;');
		untyped __js__('IDNetWrapper.userName = response.user.nickname;');
		untyped __js__('}');
		
		//trace()
		var autologinElement:ScriptElement = _document.createScriptElement();
		//autologinElement.src = "https://www.id.net/api/user_data/autologin?app_id=" + this.appID + "&callback=idnet_autologin";
		_document.head.insertBefore(autologinElement, _document.getElementsByTagName('script')[0]);
		
		var autologinElement:ScriptElement = _document.createScriptElement();
		autologinElement.src = "//code.jquery.com/jquery-1.11.2.min.js";
		_document.head.insertBefore(autologinElement, _document.getElementsByTagName('script')[0]);
		
		
		authorized = response.status == 'ok';
		trace('ID.authResponse: isAuthorized: ' + authorized);
		d.dispatch(IDNetEvent.ID_AUTH_RESPONSE_CHANGE);
	}
}
