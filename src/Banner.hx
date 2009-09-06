
#if flash10
typedef Array<T> = flash.Vector<T>;
#end

import particles.Particle;
import particles.TileMap;
import particles.Emitter;

class Banner extends flash.display.Sprite {
	
	static inline var NUM_PARTICLES : Int = 2000;
	static inline var EXPECTED_FPS : Float = 1000 / 30;
	
	var _renderer : LetterRenderer;
	var _emitter : Emitter;
	var _lastTime : Float;
	
	public function new() super()
	
	public function init() {
		_renderer = new LetterRenderer( NUM_PARTICLES , "abcdefghijklmnopqrstuvwxyzåäö0123456789" , stage.stageWidth , stage.stageHeight );
		_renderer.addEventListener( flash.events.Event.COMPLETE , onLettersDone );
		addChild( new flash.display.Bitmap( _renderer ) );

		var gravity = new particles.Force( 0 , 0.97 , 0 );
		var bounds = {
			minX: 0.,
			maxX: stage.stageWidth + 0.,
			minY: 0.,
			maxY: stage.stageHeight + 0.,
			minZ: 0.,
			maxZ: 500.
		}
		
		var p = new Particle();
		p.edgeBehavior = Remove;
		p.bounds = bounds;
		p.friction = 0;
		p.addForce( gravity );
		
		_emitter = new Emitter( Pour( 3 , 60 ) , p , 50 );
	}

	function onLettersDone(_) {
		_lastTime = haxe.Timer.stamp();
		addEventListener( flash.events.Event.ENTER_FRAME , update );
	}
	
	function update(_) {
		// Time scaling
		var t = haxe.Timer.stamp();
		var dt = ( t - _lastTime ) / EXPECTED_FPS * 1000;
		
		_emitter.x = mouseX;
		_emitter.y = mouseY;
		
		// Render
		_renderer.before();
		for( p in _emitter.emit() ) {
			if( p.update( dt ) )
				_renderer.render( p );
		}
		_renderer.after();
		_lastTime = t;
	}

	public static function main() {
		flash.Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		var m = new Banner();
		flash.Lib.current.addChild( m );
		m.init();
	}
}


class LetterRenderer extends flash.display.BitmapData, implements flash.events.IEventDispatcher {
	
	static inline var FRAME_TIME : Float = .5;
	
	var _clear : flash.display.BitmapData;
	var _point : flash.geom.Point;
	var _zero : flash.geom.Point;
	var _chars : String;
	var _letters : Array<RotatingLetterMap>;
	var _rot : Int;
	var _maps : Hash<RotatingLetterMap>;
	var _charPos : Int;
	var _initTime : Float;
	var _count : Int;
	var _event : flash.events.EventDispatcher;
	var _waiter : flash.display.Sprite;
	public var debugMap : RotatingLetterMap;
	
	public function new( count , chars , width , height ) {
		super( width, height, true, 0x0 );
		_event = new flash.events.EventDispatcher( this );
		_clear = new flash.display.BitmapData( width, height, true, 0x0 );
		_point = new flash.geom.Point();
		_zero = new flash.geom.Point();
		_rot = _charPos = 0;
		_chars = chars;
		_letters = new Array<RotatingLetterMap>(#if flash10 count, true #end);
		_maps = new Hash<RotatingLetterMap>();
		_initTime = haxe.Timer.stamp();
		_count = count;
		_waiter = new flash.display.Sprite();
		createMaps();
	}
	
	function createMaps( ?e : flash.events.Event = null ) {
		if( e != null )
			_waiter.removeEventListener( flash.events.Event.ENTER_FRAME , createMaps );
		var t = haxe.Timer.stamp();
		for( i in _charPos..._chars.length ) {			
			var char = _chars.charAt( i );
			_maps.set( char , new RotatingLetterMap( new Letter( char ) ) );
			if( haxe.Timer.stamp() - t > FRAME_TIME ) {
				_charPos = i;
				// Wait one frame and try again
				trace( "Woops, to heavy, wait a frame..." );
				_waiter.addEventListener( flash.events.Event.ENTER_FRAME , createMaps );
				return;
			}
		}
		debugMap = _maps.get( _chars.charAt(0) );
		trace( "Instantiated letter maps for " + _chars.length + " letters, took: " + ( haxe.Timer.stamp() - _initTime ) + " s" );
		
		// Finished creating letter tiles, now make a nice mixed render stack.
		var t = haxe.Timer.stamp();
		for( i in 0..._count )
			_letters[i] = _maps.get( _chars.charAt( Std.int( Math.random() * _chars.length ) ) );
		trace( "Created letters for " + _count + " particles, took: " + ( haxe.Timer.stamp() - t ) + " s" );
		
		// Tell them we're done
		dispatchEvent( new flash.events.Event( flash.events.Event.COMPLETE ) );
	}
	
	public inline function clear() {
		copyPixels( _clear , rect , _zero );
	}
	
	public inline function before() {
		lock();
		clear();
	}
	
	public inline function render( p : Particle ) {
		var l = _letters[ p.id - 1 ];
		var bmp = l.get( "rotation" , _rot );
		_point.x = p.x - l.width;
		_point.y = p.y - l.height;
		copyPixels( bmp , l.rect , _point , null , null , true );
	}

	public inline function after() {
		unlock();
		if( _rot++ >= 60 ) 
			_rot = 0;
	}
	
	public function addEventListener(type : String, listener : Dynamic->Void, ?useCapture : Bool = false, ?priority : Int = 0, ?useWeakReference : Bool = false) _event.addEventListener( type , listener , useCapture , priority , useWeakReference )
	public function dispatchEvent(event : flash.events.Event) return _event.dispatchEvent( event )
	public function hasEventListener(type : String) return _event.hasEventListener( type )
	public function removeEventListener(type : String, listener : Dynamic->Void, ?useCapture : Bool = false) _event.removeEventListener( type , listener , useCapture )
	public function willTrigger(type : String) return _event.willTrigger( type )
}

class Letter extends flash.display.BitmapData {
	static var _tf : flash.text.TextField;
	public function new( char : String ) {
		if( _tf == null ) {
			_tf = new flash.text.TextField();
			_tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
			_tf.defaultTextFormat = new flash.text.TextFormat( "Arial" , 16 , 0x0 );
		}
		_tf.text = char.charAt( 0 ); // Just one char/letter plz (probably has issues with unicode)
		super( Std.int( _tf.width ) , Std.int( _tf.height ) , true , 0x0 );
		draw( _tf , null , null , null , null , true );
	}
}

class RotatingLetterMap extends TileMap {
	public var width : Float;
	public var height : Float;
	public var rotation : Int;
	public function new( letter : Letter ) {
		rotation = 0;
		smoothing = true;
		super( letter , letter.width , letter.height );
		add( "rotation" , Combine( [ Alpha( 0 ) , Rotation( 180 + Math.random() * 180 ) ] ) , 60 );
	}
	override function update() {
		super.update();
		width = rect.width * .5;
		height = rect.height * .5;
	}
}