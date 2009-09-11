
import particles.EffectPoint;
import particles.Particle;
import particles.TileMap;
import particles.Emitter;
import particles.VectorArray;
import render.ShapeRenderer;

class Particles extends flash.display.Sprite {
	
	static inline var NUM_PARTICLES : Int = 2000;
	static inline var EXPECTED_FPS : Float = 1000 / 30;
	
	var _particles : Array<particles.Particle>;
	var _mouseEffect : particles.EffectPoint;
	var _renderer : render.IRenderer;
	var _tileRenderer : render.TileRenderer;
	var _simpleRenderer : render.SimpleBitmapRenderer;
	var _shapeRenderer : render.ShapeRenderer;
	var _letterRenderer : render.LetterRenderer;
	var _nullRenderer : render.NullRenderer;
	var _tileMap : flash.display.DisplayObject;
	var _lastTime : Float;
	var _activeParticles : Bool;
	var _radioSimple : minimalcomps.RadioButton;
	var _radioTileMap : minimalcomps.RadioButton;
	var _radioShape : minimalcomps.RadioButton;
	var _radioLetter : minimalcomps.RadioButton;
	var _radioNull : minimalcomps.RadioButton;
	var _emitter : particles.Emitter;
	
	public function new() {
		super();
		_particles = new Array<particles.Particle>( #if flash10 NUM_PARTICLES , true #end );
		_activeParticles = true;
	}
	
	public function init() {
		
		var r = new render.Rect();
		var t = new particles.TileMap( r , Std.int( r.width ) , Std.int( r.height ) );
	//	t.add( "rotation" , Rotation( 180 ) , 60 );
		t.add( "rotation" , Combine( [ Alpha( 0 ) , Rotation( 180 + Math.random() * 180 ) ] ) , 60 );
	//	t.add( "red" , Tint( 0xFF0000 ) , 60 );
	//	t.add( "fade" , Alpha( 0.5 ) , 60 );
	//	t.add( "scale" , Scale( 4 , 4 ) , 24 );
	//	t.add( "combo" , Combine( [ Scale( 4 , 4 ) , Tint( 0xFF0000 ) ] ) , 24 );
		

		_tileRenderer = new render.TileRenderer( t , stage.stageWidth , stage.stageHeight );
		addChild( new flash.display.Bitmap( _tileRenderer ) );
		
		_simpleRenderer = new render.SimpleBitmapRenderer( r , stage.stageWidth , stage.stageHeight );
		addChild( new flash.display.Bitmap( _simpleRenderer ) );
		
		_shapeRenderer = new render.ShapeRenderer( NUM_PARTICLES );
		addChild( _shapeRenderer );
		
		_letterRenderer = new render.LetterRenderer( NUM_PARTICLES , "abcdefghijklmnopqrstuvwxyzåäö0123456789" , stage.stageWidth , stage.stageHeight );
		_letterRenderer.addEventListener( flash.events.Event.COMPLETE , onLettersDone );
		_letterRenderer.createLetters();
		addChild( new flash.display.Bitmap( _letterRenderer ) );
		
		_nullRenderer = new render.NullRenderer();
		
		_mouseEffect = new particles.EffectPoint( Repel( .1 , 100 ) , mouseX , mouseY , 0 );
		var gravity = new particles.Force( 0 , 0.97 , 0 );
		var bounds = {
			minX: 0.,
			maxX: stage.stageWidth + 0.,
			minY: 0.,
			maxY: stage.stageHeight + 0.,
			minZ: 0.,
			maxZ: 500.
		}
		var p = new particles.Particle();
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
		_emitter = new particles.Emitter( Pour( 2 ) , [p] , 60 , 80 );
		
		
		addTextBoxOverlay();
		
		// Add renderer toggle
		_radioSimple = new minimalcomps.RadioButton( this , 0 , 0 , "Simple" , true );
		_radioTileMap = new minimalcomps.RadioButton( this , 0 , 20 , "TileMap" , false );
		_radioShape = new minimalcomps.RadioButton( this , 0 , 40 , "Shape" , false );
		_radioLetter = new minimalcomps.RadioButton( this , 0 , 60 , "Letter" , false );
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
		
		#if debug
		_tileMap = addChild( new flash.display.Bitmap( _renderer.debug() ) );
		_tileMap.visible = false;
		#end
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
		_tileMap = addChild( new flash.display.Bitmap( _renderer.debug() ) );
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
		var i = 0;
		for( p in _emitter.emit() ) {
			if( _activeParticles )
				p.update( dt );
			_renderer.render( p );
			i++;
		}
		_renderer.after();
		
		var tot = Std.int( ( haxe.Timer.stamp() - t ) * 1000 );
	    var curFPS = 1000 / ( t - _lastTime );
	    fps = Std.int( ( fps * 10 + curFPS ) * .000909 ); // = / 11 * 1000
	    fdisplay.text = fps + " fps" + " " + tot + " ms" + " " + Std.int( flash.system.System.totalMemory / 1024 ) + " Kb" + " " + i + " particles";
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
