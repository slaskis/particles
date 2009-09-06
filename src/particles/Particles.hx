package particles;

#if flash10
typedef Array<T> = flash.Vector<T>;
#end

import particles.EffectPoint;
import particles.Particle;
import particles.TileMap;
import particles.Emitter;

class Particles extends flash.display.Sprite {
	
	static inline var NUM_PARTICLES : Int = 2000;
	static inline var EXPECTED_FPS : Float = 1000 / 30;
	
	var _particles : Array<Particle>;
	var _dots : Array<Dot>;
	var _mouseEffect : EffectPoint;
	var _renderer : IRenderer;
	var _tileRenderer : TileRenderer;
	var _simpleRenderer : SimpleBitmapRenderer;
	var _shapeRenderer : ShapeRenderer;
	var _letterRenderer : LetterRenderer;
	var _nullRenderer : NullRenderer;
	var _tileMap : flash.display.DisplayObject;
	var _lastTime : Float;
	var _activeParticles : Bool;
	var _radioSimple : minimalcomps.RadioButton;
	var _radioTileMap : minimalcomps.RadioButton;
	var _radioShape : minimalcomps.RadioButton;
	var _radioLetter : minimalcomps.RadioButton;
	var _radioNull : minimalcomps.RadioButton;
	var _emitter : Emitter;
	
	public function new() {
		super();
		_particles = new Array<Particle>( #if flash10 NUM_PARTICLES , true #end );
		_dots = new Array<Dot>( #if flash10 NUM_PARTICLES , true #end );
		_activeParticles = true;
	}
	
	public function init() {
		
		var r = new Rect();
		var t = new TileMap( r , Std.int( r.width ) , Std.int( r.height ) );
	//	t.add( "rotation" , Rotation( 180 ) , 60 );
	//	t.add( "red" , Tint( 0xFF0000 ) , 60 );
	//	t.add( "fade" , Alpha( 0.5 ) , 60 );
	//	t.add( "scale" , Scale( 4 , 4 ) , 24 );
	//	t.add( "combo" , Combine( [ Scale( 4 , 4 ) , Tint( 0xFF0000 ) ] ) , 24 );
		

		_tileRenderer = new TileRenderer( t , stage.stageWidth , stage.stageHeight );
		addChild( new flash.display.Bitmap( _tileRenderer ) );
		
		_simpleRenderer = new SimpleBitmapRenderer( r , stage.stageWidth , stage.stageHeight );
		addChild( new flash.display.Bitmap( _simpleRenderer ) );
		
		_shapeRenderer = new ShapeRenderer( NUM_PARTICLES );
		addChild( _shapeRenderer );
		
		_letterRenderer = new LetterRenderer( NUM_PARTICLES , "abcdefghijklmnopqrstuvwxyzåäö0123456789" , stage.stageWidth , stage.stageHeight );
		addChild( new flash.display.Bitmap( _letterRenderer ) );
		_letterRenderer.addEventListener( flash.events.Event.COMPLETE , onLettersDone );
		
		_nullRenderer = new NullRenderer();
		
		_mouseEffect = new EffectPoint( Repel( .1 , 100 ) , mouseX , mouseY , 0 );
		var gravity = new Force( 0 , 0.97 , 0 );
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
			
		/*
		p.addPoint( _mouseEffect );
		var pool = new ParticlePool( p );
		for( i in 0...NUM_PARTICLES ) {
			var p = pool.retrieve();
			p.x = Math.random() * stage.stageWidth;
			p.y = Math.random() * stage.stageHeight;
			_particles[i] = p;
		}
		*/
		_emitter = new Emitter( Pour( 3 , 60 ) , p , 50 );
		
		
		addTextBoxOverlay();
		
		// Add renderer toggle
		_radioSimple = new minimalcomps.RadioButton( this , 0 , 0 , "Simple" , false );
		_radioTileMap = new minimalcomps.RadioButton( this , 0 , 20 , "TileMap" , false );
		_radioShape = new minimalcomps.RadioButton( this , 0 , 40 , "Shape" , false );
		_radioLetter = new minimalcomps.RadioButton( this , 0 , 60 , "Letter" , true );
		_radioNull = new minimalcomps.RadioButton( this , 0 , 80 , "Null" , false );
		
		var o = this;
		// Add toggler for the tile
		new minimalcomps.PushButton( this , 100 , 0 , "Toggle TileMap" , function(_) {
			o._tileMap.visible = !o._tileMap.visible;
		} );
		
		// Add toggler for the particle update
		new minimalcomps.PushButton( this , 100 , 20 , "Toggle Particle Updates" , function(_) {
			o._activeParticles = !o._activeParticles;
		} );
		
		// Toggle Mouse Behavior
		new minimalcomps.PushButton( this , 100 , 40 , "Toggle Mouse behavior" , function(_) {
			o._mouseEffect.type = switch( Type.enumConstructor( o._mouseEffect.type ) ) {
				case "Repel": Spring( .1 );
				case "Spring": Attract( 100. );
				case "Attract": Repel( .1 , 100. );
			}
		} );
	}
	
	function onLettersDone(_) {
		_lastTime = haxe.Timer.stamp();
		addEventListener( flash.events.Event.ENTER_FRAME , update );
		_tileMap = addChild( new flash.display.Bitmap( _letterRenderer.debugMap.getBitmap( 0 ) ) );
		_tileMap.visible = false;
	}
	
	inline function checkRenderer() {
		var old = _renderer;
		if( _radioSimple.selected )
			_renderer = _simpleRenderer;
		else if( _radioTileMap.selected )
			_renderer = _tileRenderer;
		else if( _radioShape.selected )
			_renderer = _shapeRenderer;
		else if( _radioLetter.selected )
			_renderer = _letterRenderer;
		else 
			_renderer = _nullRenderer;
		if( old != null && old != _renderer )
			old.clear();
	}
	
	var fps : Int;
	var fdisplay : flash.text.TextField;
	inline function update(_) {
		// Time scaling
		var t = haxe.Timer.stamp();
		var dt = ( t - _lastTime ) / EXPECTED_FPS * 1000;
		
		_mouseEffect.x = mouseX;
		_mouseEffect.y = mouseY;
		_emitter.x = mouseX;
		_emitter.y = mouseY;
		
		// Render
		checkRenderer();
		_renderer.before();
		for( p in _emitter.emit() ) {
			if( _activeParticles )
				p.update( dt );
			_renderer.render( p );
		}
		_renderer.after();
		
		var tot = Std.int( ( haxe.Timer.stamp() - t ) * 1000 );
	    var curFPS = 1000 / ( t - _lastTime );
	    fps = Std.int( ( fps * 10 + curFPS ) * .000909 ); // = / 11 * 1000
	    fdisplay.text = fps + " fps" + " " + tot + " ms" + " " + Std.int( flash.system.System.totalMemory / 1024 ) + " Kb";
		_lastTime = t;
	}
	
	
    function addTextBoxOverlay() : Void {
        var tf = new flash.text.TextFormat();
        tf.font = 'Arial';
        tf.size = 10;
        tf.color = 0xFFFFFF;

        fdisplay = new flash.text.TextField();
        fdisplay.autoSize = flash.text.TextFieldAutoSize.RIGHT;
        fdisplay.defaultTextFormat = tf;
        fdisplay.selectable = false;
        fdisplay.text = 'Waiting...';
        fdisplay.y = 600 - fdisplay.height;
        fdisplay.x = 800 - fdisplay.width;
        fdisplay.opaqueBackground = 0x000000;
        addChild( fdisplay );
    }

	public static function main() {
		flash.Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Trazzle.setRedirection();
		var m = new Particles();
		flash.Lib.current.addChild( m );
		m.init();
	}
}

interface IRenderer {
	public function clear() : Void;
	public function before() : Void;
	public function after() : Void;
	public function render( p : Particle ) : Void;
}

class SimpleBitmapRenderer extends flash.display.BitmapData, implements IRenderer {
	
	var _source : flash.display.BitmapData;
	var _point : flash.geom.Point;
	var _zero : flash.geom.Point;
	
	public function new( source : Dynamic , width , height ) {
		super( width , height , true , 0x0 );
		_zero = new flash.geom.Point();
		_source = new flash.display.BitmapData( Std.int( source.width ) , Std.int( source.height ) , true , 0x0 );
		_source.draw( source );
		_point = new flash.geom.Point();
	}
	
	public inline function clear() {
		fillRect( rect , 0x0 );
	}
	
	public inline function before() {
		lock();
		clear();
	}
	
	public inline function render( p : Particle ) {
		_point.x = p.x - _source.width * .5;
		_point.y = p.y - _source.height * .5;
		copyPixels( _source , _source.rect , _point , null , _zero , true );
	}
	
	public inline function after() {
		unlock();
	}
	
}

class TileRenderer extends flash.display.BitmapData , implements IRenderer {
	var _clear : flash.display.BitmapData;
	var _map : TileMap;
	var _point : flash.geom.Point;
	var _zero : flash.geom.Point;
	var _rot : Int;
	var _w : Float;
	var _h : Float;
	
	public function new( map : TileMap , width , height ) {
		super( width , height , true , 0x0 );
		_clear = new flash.display.BitmapData( width, height, true, 0x0 );
		_point = new flash.geom.Point();
		_zero = new flash.geom.Point();
		_map = map;
		_rot = 0;
		_w = _map.rect.width * .5;
		_h = _map.rect.height * .5;
	}
	
	public inline function clear() {
		//fillRect( rect , 0x0 );
		copyPixels( _clear , rect , _zero );
	}
	
	public inline function before() {
		lock();
		clear();
	}
	
	public inline function render( p : Particle ) {
		_point.x = p.x - _w;
		_point.y = p.y - _h;
		var bmp = _map.get( "rotation" , _rot );
		copyPixels( bmp , _map.rect , _point , null , null , true );
		if( ++_rot >= 60 ) _rot = 0;
	}
	
	public inline function after() {
		unlock();
	}
}

class ShapeRenderer extends flash.display.Sprite, implements IRenderer {
	
	var _shapes : Array<flash.display.Shape>;
	
	public function new( count ) {
		super();
		_shapes = new Array<flash.display.Shape>(#if flash10 count , true #end);
		for( i in 0...count ) {
			var s = new Rect();
			// MAD! Totally kills the other renderers
			s.cacheAsBitmap = true;
			s.visible = false;
			addChild( s );
			_shapes[i] = s;
		}
	}
	
	public inline function clear() {
		for( s in _shapes )
			s.visible = false;
	}
	
	public inline function before();
	
	public inline function render( p : Particle ) {
		var s = _shapes[ p.id - 1 ];
		if( !s.visible ) s.visible = true;
		s.x = p.x;
		s.y = p.y;
		s.z = p.z;
	}
	
	public inline function after();
}

class LetterRenderer extends flash.display.BitmapData, implements IRenderer, implements flash.events.IEventDispatcher {
	
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


class NullRenderer implements IRenderer {
	public function new();
	public inline function clear();
	public inline function before();
	public inline function render( p : Particle );
	public inline function after();
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

class Dot extends flash.display.Shape {
	public function new() {
		super();
		graphics.beginFill( 0xFF0000 , 1 );
		graphics.drawCircle( 5 , 5 , 5 );
	}
}


class Rect extends flash.display.Shape {
	public function new() {
		super();
		var color : UInt = Std.int( Math.random() * 0xFFFFFF );
		graphics.beginFill( color , 1 );
		graphics.drawRect( 0 , 0 , 10 , 10 );
	}
}