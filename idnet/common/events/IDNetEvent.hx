package idnet.common.events;

class IDNetEvent
{
	
	public static inline var ID_INITIALIZE_COMPLETE:String = 'id.init';
	public static inline var ID_INITIALIZE_FAILED:String = 'id.init.fail';
	public static inline var ID_AUTH_RESPONSE_CHANGE:String = 'auth.authResponseChange';
	
	public static inline var ID_AUTH_FAIL:String = 'auth.fail'; // user closed auth window
	public static inline var ID_AUTH_COMPLETE:String = 'auth.complete'; // authorize was a success
	public static inline var ID_LOGOUT:String = 'logout.complete'; // logout was a success

	public function new() { }
}