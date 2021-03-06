package render;

import particles.TileMap;
import particles.VectorArray;

class BitmapLetterRenderer extends flash.display.BitmapData, implements flash.events.IEventDispatcher , implements IRenderer {
	
	public static var FRAME_TIME = .2;
	
	var _clear : flash.display.BitmapData;
	var _format : flash.text.TextFormat;
	var _point : flash.geom.Point;
	var _zero : flash.geom.Point;
	var _chars : String;
	var _letters : Hash<RotatingLetterMap>;
	var _rot : Int;
	var _maps : Hash<RotatingLetterMap>;
	var _charPos : Int;
	var _initTime : Float;
	var _count : Int;
	var _event : flash.events.EventDispatcher;
	var _waiter : flash.display.Sprite;
	
	#if debug
	public function debug()	return debugMap.getBitmap(0)
	public var debugMap : RotatingLetterMap;
	#end
	
	public function new( count , chars , width , height , ?format ) {
		super( width, height, true, 0x0 );
		_event = new flash.events.EventDispatcher( this );
		_clear = new flash.display.BitmapData( width, height, true, 0x0 );
		_point = new flash.geom.Point();
		_zero = new flash.geom.Point();
		_rot = _charPos = 0;
		_chars = chars;
		_format = ( format == null ) ? new flash.text.TextFormat( "Arial" , 16 , 0x0 ) : format;
		_letters = new Hash<RotatingLetterMap>();
		_maps = new Hash<RotatingLetterMap>();
		_initTime = haxe.Timer.stamp();
		_count = count;
		_waiter = new flash.display.Sprite();
	}
	
	public function createLetters( ?e : flash.events.Event = null ) {
		if( e != null )
			_waiter.removeEventListener( flash.events.Event.ENTER_FRAME , createLetters );
		var t = haxe.Timer.stamp() * .001;
		for( i in _charPos..._chars.length ) {			
			var char = _chars.charAt( i );
			var effect = Combine( [ Scale( Math.random() * 1.5 ) , Rotation( 180 + Math.random() * 180 ) , Filter( new flash.filters.BlurFilter() ) ] );
			_maps.set( char , new RotatingLetterMap( new Letter( _format , char ) , effect ) );
			if( haxe.Timer.stamp() * .001 - t > FRAME_TIME ) {
				// Wait one frame and try again
				_charPos = i;
				_waiter.addEventListener( flash.events.Event.ENTER_FRAME , createLetters );
				return;
			}
		}
		#if debug
		debugMap = _maps.get( _chars.charAt(_chars.length - 1) );
		#end
		//trace( "Instantiated letter maps for " + _chars.length + " letters, took: " + ( haxe.Timer.stamp() - _initTime ) + " s" );
		
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
	
	public inline function render( p : particles.Particle ) {
		var l = _letters.get( Std.string( p.id ) );
		if( l == null ) {
			l = _maps.get( _chars.charAt( Std.int( Math.random() * _chars.length ) ) );
			_letters.set( Std.string( p.id ) , l );
		}
		// Some play backwards, some forwards
//		var frame = ( p.id & 1 == 0 ) ? p.lifetime : l.frames - p.lifetime;
		var frame = Std.int( p.z );
		var bmp = l.get( "rotation" , frame );
		_point.x = p.x - l.width;
		_point.y = p.y - l.height;
		copyPixels( bmp , l.rect , _point , null , null , true );
	}

	public inline function after() {
		unlock();
	}
	
	public function addEventListener(type : String, listener : Dynamic->Void, ?useCapture : Bool = false, ?priority : Int = 0, ?useWeakReference : Bool = false) _event.addEventListener( type , listener , useCapture , priority , useWeakReference )
	public function dispatchEvent(event : flash.events.Event) return _event.dispatchEvent( event )
	public function hasEventListener(type : String) return _event.hasEventListener( type )
	public function removeEventListener(type : String, listener : Dynamic->Void, ?useCapture : Bool = false) _event.removeEventListener( type , listener , useCapture )
	public function willTrigger(type : String) return _event.willTrigger( type )
}

class Letter extends flash.display.BitmapData {
	public static var _tf : flash.text.TextField;
	public function new( format : flash.text.TextFormat , char : String ) {
		if( _tf == null ) {
			var embed = false;
			for( f in flash.text.Font.enumerateFonts() )
				if( f.fontName == format.font )
					embed = true;
			_tf = new flash.text.TextField();
			_tf.embedFonts = embed;
			_tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
			_tf.defaultTextFormat = format;
		}
		_tf.text = char.charAt( 0 ); // Just one char/letter plz (probably has issues with unicode)
		trace( "Creating a Letter of: " + char.charAt( 0 ) + " size: " + _tf.width + "x" + _tf.height );
		super( Math.ceil( _tf.width ) , Math.ceil( _tf.height ) , true , 0x0 );
		draw( _tf , null , null , null , null , true );
	}
}

class RotatingLetterMap extends particles.TileMap {
	public var width : Float;
	public var height : Float;
	public var rotation : Int;
	public var letter : Letter;
	public var frames : Int;
	public function new( letter : Letter , effect : TileEffect , frames = 60 ) {
		rotation = 0;
		this.frames = frames;
		smoothing = true;
		this.letter = letter;
		super( letter , letter.width , letter.height );
//		add( "rotation" , Combine( [ Alpha( 0 ) , Rotation( 180 + Math.random() * 180 ) ] ) , 60 );
//		add( "rotation" , Combine( [ Tint( 0x2C1840 ) , Rotation( 180 + Math.random() * 180 ) ] ) , 60 );
//		add( "rotation" , Rotation( 180 + Math.random() * 180 ) , 60 );
//		add( "rotation" , Tint( 0xFFFFFF ) , 60 );
//		add( "rotation" , Alpha( 0 ) , 60 );
		add( "rotation" , effect , frames );
	}
	
	override function update() {
		super.update();
		width = rect.width * .5;
		height = rect.height * .5;
	}
}