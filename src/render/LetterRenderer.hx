package render;

import particles.TileMap;
import particles.VectorArray;

class LetterRenderer extends flash.display.Sprite, implements flash.events.IEventDispatcher , implements IRenderer {
	
	var _format : flash.text.TextFormat;
	var _letters : Hash<Letter>;
	var _maps : Hash<Letter>;
	var _chars : String;
	var _count : Int;
	
	#if debug
	public function debug()	{	
		var bmp = new flash.display.BitmapData( Std.int( width ) , Std.int( height ) , true , 0x0 );
		bmp.draw( this );
		return bmp;
	}
	#end
	
	public function new( count , chars , ?format ) {
		super();
		_chars = chars;
		_format = ( format == null ) ? new flash.text.TextFormat( "Arial" , 16 , 0x0 ) : format;
		_letters = new Hash<Letter>();
		_maps = new Hash<Letter>();
		_count = count;
	}
	
	public function createLetters() {
		// Tell them we're done
		dispatchEvent( new flash.events.Event( flash.events.Event.COMPLETE ) );
	}
	
	public inline function clear() {
		for( l in _letters )
			l.visible = false;
	}
	
	public inline function before() {
		clear();
	}
	
	public inline function render( p : particles.Particle ) {
		var l = _letters.get( Std.string( p.id ) );
		if( l == null ) {
			var char = _chars.charAt( Std.int( Math.random() * _chars.length ) );
			l = Letter.create( _format , char );
			_letters.set( Std.string( p.id ) , l );
			trace( "Assigning particle to letter: " + p.id + " " + char );
			addChild( l );
		}
		l.x = p.x;
		l.y = p.y;
		l.z = p.z;
		l.rotation += l.rotationChange;
		
		if( !p.active )
			l.dispose();
		else
			l.visible = true;
	}

	public inline function after() {
	}
	
}

class Letter extends flash.display.Sprite {
	
	static var _pool: Letter;
	static var _availableInPool : Null<Int>;
	
	public static function create( format : flash.text.TextFormat , char : String ) {
		var pooledObject : Letter;
		
		if( _availableInPool == null || _availableInPool == 0 ) {
			var poolGrowthRate = 0x10;
			trace( "Expanding pool with " + poolGrowthRate + " objects" );
			for( i in 0...poolGrowthRate ) {
				pooledObject = new Letter( format , char );
				pooledObject._nextInPool = _pool;
				_pool = pooledObject;		 
			}
			_availableInPool += poolGrowthRate;
		}
		
		pooledObject = _pool;
		_pool = pooledObject._nextInPool;
		--_availableInPool;
		
		pooledObject._tf.text = char;
		pooledObject._tf.setTextFormat( format );
		
		return pooledObject;	
	}
	
	static function release( l : Letter ) {
		l._nextInPool = _pool;
		_pool = l;
		++_availableInPool;
	}

	
	public var z(default,setZ) : Float;
	public var rotationChange : Float;
	
	var _nextInPool : Letter;
	var _tf : flash.text.TextField;
	var _blur : flash.filters.BlurFilter;
	
	private function new( format : flash.text.TextFormat , char : String ) {
		super();
		_tf = new flash.text.TextField();
		_tf.embedFonts = isEmbedded( format.font );
		_tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		_tf.defaultTextFormat = format;
		_tf.text = char.charAt( 0 ); // Just one char/letter plz (probably has issues with unicode)
		_tf.x = -_tf.textWidth / 2;
		_tf.y = -_tf.textHeight / 2;
		_tf.cacheAsBitmap = true;
		_blur = new flash.filters.BlurFilter( 0 , 0 );
		addChild( _tf );
		rotationChange = -2 + Math.random() * 4;
		trace( "Creating a Letter of: " + char.charAt( 0 ) + " size: " + _tf.width + "x" + _tf.height );
	}
	
	public function dispose() release( this )
	
	function isEmbedded( fontName ) {
		var embed = false;
		for( f in flash.text.Font.enumerateFonts() )
			if( f.fontName == fontName )
				embed = true;
		return embed;
	}
	
	function setZ( z : Float ) {
		var blur = Math.abs( z ) / 20;
		_blur.blurX = _blur.blurY = blur;
		filters = [ _blur ];
		var scale = 1 + z / 50;
		if( scale < .5 ) scale = .5;
		if( scale > 2 ) scale = 2;
		trace( "z:"+ z + ", blur:" + blur + ", scale:" + scale );
		scaleX = scaleY = scale;
		return z;
	}
}
