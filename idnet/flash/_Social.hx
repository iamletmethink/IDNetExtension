package idnet.flash;

import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.Stage;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.Security;
import flash.system.SecurityDomain;
import idnet.common.events.IDNetEvent;

typedef Idnet = {
	>DisplayObject,
	
	//
	// Public properties
	//
	var data(default, default):Dynamic;		// data from last response
	var isLoggedIn(default, null):Bool;		// is user logged in
	var type(default, default):String;		// last type of response
	var userdata(default, null):Dynamic;	// last saved user data w/o connecting
	var _protection(default, null):Dynamic;
	
	//
	// Public methods
	//
	function getPlayersScore():Void;
	function init(stageRef:Stage, appId:String, appSecret:String, debug:Bool, preload:Bool, protection:Bool):Void;
	function InterfaceOpen():Bool;								// if Interface is visible
	function removeUserData(key:String):Dynamic;				// 
	function retrieveUserData(key:String):Dynamic;				// 
//	function sessionTestResponse(_data:Dynamic):Dynamic;		// GR:TODO:some debug function i guess
	function submitScore(score:Int):Void;						// submit user score to scoreboard
	function submitUserData(key:String, data:Dynamic):Dynamic;	// submit user data
	function toggleInterface(type:String):Void;					// 'login', 'registration', 'scoreboard', or null
	function achievementsSave(achName:String, achKey:String, playerName:String, overwrite:Bool, allowDuplicates:Bool):Void;
	function logout():Void;										// 
}


class _Social extends SocialBase {
    
	//
	// Static helper variables
	//
	private static inline var EVENT:String = 'IDNET';
	private static inline var EVENT_LOGIN:String = 'login';
	private static inline var EVENT_SUBMIT:String = 'submit';
	private static inline var EVENT_RETRIEVE:String = 'retrieve';
	
	
	//
	// Constructor
	//
	public function new() {
		super();
    }

	
	//
	// Variables
	//
	private var _idnet:Idnet;
	
	
	//
	// API
	//
	override public function init():Void 
	{
		//super.init();
		Security.allowInsecureDomain('*');
		Security.allowDomain('*');
		
		var context:LoaderContext = new LoaderContext();
		context.applicationDomain = ApplicationDomain.currentDomain;
		if (Security.sandboxType != 'localTrusted') {
			trace('happens');
			context.securityDomain = SecurityDomain.currentDomain;
		}
		
		var sdkUrl:String = "https://www.id.net/swf/idnet-client.swc?=" + Date.now();
		var request:URLRequest = new URLRequest(sdkUrl);
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSWCLoaded);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onSWCLoadingFailed);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, onSWCLoadingFailed);
		loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSWCLoadingFailed);
		//loader.load(request, context);
		trace('try');
		try{
			loader.load(request, context);
		}catch(unknown:Dynamic){
			trace('hello');
			trace(Std.string(unknown));
			loader.load(request);
		}
	}
	
	//
	// ID.net sdk callbacks
	//
	
	private function onSWCLoaded(e:Event):Void 
	{
		var loader = e.target.loader;
		loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSWCLoaded);
		loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onSWCLoadingFailed);
		loader.contentLoaderInfo.removeEventListener(IOErrorEvent.NETWORK_ERROR, onSWCLoadingFailed);
		loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSWCLoadingFailed);
		
		//flash.system.Security.allowDomain('https://www.id.net/');
		trace(haxe.Json.stringify(e.target.loader));
		
		if (e.target.content == null) 
		{
			d.dispatch(IDNetEvent.ID_INITIALIZE_FAILED);
			return;
		}
		
		_idnet = e.target.content;
		_idnet.addEventListener(EVENT, handleIDnetEvents);
		
		params.stageRef.addChild(_idnet);
		_idnet.init(
			params.stageRef, 
			params.appId, 
			params.appSecret, 
			params.debug,
			params.preload,
			true
		);
		
		IDNetWrapper.isLoaded = true;
		d.dispatch(IDNetEvent.ID_INITIALIZE_COMPLETE);
	}
	
	private function onSWCLoadingFailed(e:Event):Void 
	{
		d.dispatch(IDNetEvent.ID_INITIALIZE_FAILED);
		
		//stub
		throw e;
	}
	
	private function handleIDnetEvents(e:Event):Void
	{
		if(_idnet.type == 'protection') {
			if(_idnet._protection != null && _idnet._protection.isBlacklisted()){
				IDNetWrapper.inBlackList = true;
			}
			return;
		} else if (_idnet.type == 'login') {
			if (isError()) {
				if (_idnet.data.error == 'Key not found' ) {
					//stub
					return;
				}
				this.authorized = false;
				d.dispatch(IDNetEvent.ID_AUTH_FAIL);
				trace('Error: ' + _idnet.data.error);
			} else {
				IDNetWrapper.userName = _idnet.data.user.nickname;
				IDNetWrapper.sessionKey = _idnet.data.sessionKey;
				trace('logged in');
				this.authorized = true;
				d.dispatch(IDNetEvent.ID_AUTH_COMPLETE);
			}
		} else 
		if (_idnet.type == 'submit') {
			if (isError()) {
				trace('Error: '+_idnet.data.error);
			} else {
				trace('Status: ' + _idnet.data.status);
			}
		} else 
		if (_idnet.type == 'retrieve') {
			if (isError()) {
				trace('Error: '+_idnet.data.error);
			} else {
				trace('Key '+_idnet.data.key);
				trace('Data: '+_idnet.data.jsondata);
				IDNetWrapper.loadData(_idnet.data.jsondata);
			}
		} else 
		if (_idnet.type == 'score') {
			/*if (isError()) {
				trace('Error: '+_idnet.data.error);
			} else {
				trace(_idnet.data.error);
			}*/
		} else
		{
			trace('unhandled event type: ' + _idnet.type);
		}
	}
	
	private function isError():Bool { return _idnet.data.error != null && _idnet.data.error.length != 0; }
	
	override public function register():Void 
	{
		if (_idnet.isLoggedIn) {
			d.dispatch(IDNetEvent.ID_AUTH_COMPLETE);
		} else {
			_idnet.toggleInterface('registration');
		}
	}
	
	override public function loginPopup():Void 
	{
		if (_idnet.isLoggedIn) {
			d.dispatch(IDNetEvent.ID_AUTH_COMPLETE);
		} else {
			_idnet.toggleInterface('login');
		}
	}
	
	override public function scoreboard():Void 
	{
		if (_idnet.isLoggedIn) {
			_idnet.toggleInterface('scoreboard');
		} else {
			_idnet.toggleInterface('login');
		}
	}
	
	override public function removeUserData(key:String):Void { 
		if (_idnet.isLoggedIn) {
			_idnet.removeUserData(key);
		} else {
			_idnet.toggleInterface('login');
		}
	}
	
	override public function retrieveUserData(key:String):String { 
		if (_idnet.isLoggedIn) {
			return _idnet.retrieveUserData(key);
		} else {
			_idnet.toggleInterface('login');
			return null;
		}
	}
	
	override public function submitUserData(key:String, data:String):Void { 
		if (_idnet.isLoggedIn) {
			_idnet.submitUserData(key, data);
		} else {
			_idnet.toggleInterface('login');
		}
	}
	
	override public function submitScore(score:Int):Void
	{
		if (_idnet.isLoggedIn) {
			_idnet.submitScore(score);
		} else {
			_idnet.toggleInterface('login');
		}
	}
	
	override public function achievementsList():Void
	{
		if (_idnet.isLoggedIn) {
			_idnet.toggleInterface('achievements');
		} else {
			_idnet.toggleInterface('login');
		}
	}
	
	override public function achievementsSave(name:String, key:String):Void
	{
		if (_idnet.isLoggedIn) {
			_idnet.achievementsSave(name, key, IDNetWrapper.userName, false, false);
		} else {
			_idnet.toggleInterface('login');
		}
	}
	override public function InterfaceOpen():Bool
	{
		return _idnet.InterfaceOpen();
	}
	
	override public function logout() 
	{
		if (_idnet.isLoggedIn) {
			this.authorized = false;
			_idnet.logout();
			d.dispatch(IDNetEvent.ID_LOGOUT);
		} else {
			//trace('already logged out');
		}
	}
}
