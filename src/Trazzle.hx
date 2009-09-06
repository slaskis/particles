typedef Log = { message : Dynamic , pos : haxe.PosInfos , time: Int };

typedef Socket = flash.net.XMLSocket;

class Trazzle {
	
	var _sock : Socket;
	var _conn : haxe.remoting.SocketConnection;
	var _buffer : Array<Log>;
	var _signatureSent : Bool;
	
	static var _trazzle : Trazzle;
	static var _standardTrace : Dynamic;
	
	public static function setRedirection( ?host : String = "localhost" , ?port : UInt = 3456 ) {
	  var tr = new Trazzle( host , port );
	  _standardTrace = haxe.Log.trace;
	  haxe.Log.trace = tr.log;
	  // TODO If there's an error with the socket connection, use the default trace again. (flash.Boot.__trace in flash9)
	}
	
	public function new( ?host : String = "localhost" , ?port : UInt = 3456 ) {
	  try {
	    flash.system.Security.loadPolicyFile( "xmlsocket://" + host + ":" + port );
	  } catch( e : Dynamic ) {
	    onError();
	  }
		_sock = new Socket();
		_sock.addEventListener( flash.events.Event.CONNECT, onConnect );
		_sock.addEventListener( flash.events.SecurityErrorEvent.SECURITY_ERROR, onError );
		_sock.addEventListener( flash.events.IOErrorEvent.IO_ERROR, onError );
		_sock.connect( host , port );
		_buffer = new Array<Log>();
		_signatureSent = false;
	}
	
	function onConnect( event : flash.events.Event ) {
	  trace( "Connected, buffered msgs: " + _buffer.length );
		while( _buffer.length > 0 )
			send( _buffer.shift() );
		trace( "Buffer cleared. " );
	}
	
	function onError( ?event : flash.events.ErrorEvent = null ) {
	  haxe.Log.trace = _standardTrace;
  	trace( "Could not access Trazzle: " + event );
		while( _buffer.length > 0 ) {
		  var l = _buffer.shift();
			trace( l.message , l.pos );
		}
	}
	
	public function log( v : Dynamic , ?pos : haxe.PosInfos ) {
	  switch( pos.fileName ) {
	    case "Trazzle.hx": return;
	  }
		var log = { message: v , pos: pos , time: flash.Lib.getTimer() };
		if( _sock.connected ) {
			send( log );
		} else {
			_buffer.push( log );
		}
	}
	
	function send( log : Log ) {
		if( !_signatureSent ) 
			sendSignature();
		// TODO Implement the stack trace... <stacktrace language="haxe" index="0" ignoreToIndex="0"><![CDATA[Stack info here... formatted like in as3?]></stacktrace>
		// TODO Allow different debug levels (like "w:" as the first two chars in the message for warn?) or ERROR: or ERR: or ERR etc
		// TODO Use the customParams in haxe.PosInfos, add them to the message like the as3 trace (and also format the output nicely)
		var xml = '<log level="debug" line="' + log.pos.lineNumber + '" ts="' + log.time + '" class="' + log.pos.className + '" method="'+ log.pos.methodName +'" file="' + log.pos.fileName + '" encodehtml="false"><message><![CDATA[' + log.message + ']]></message></log>';
		_sock.send( xml + "\n" );
	}
	
	function sendSignature() {
		_sock.send( '<signature language="haxe" starttime="' + (Date.now().getTime() - flash.Lib.getTimer( )) + '" />' );
		_signatureSent = true;
	}
	
}