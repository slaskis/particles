import particles.Particle;
import particles.TileMap;
import particles.Emitter;
import particles.EffectPoint;
import render.LetterRenderer;

class Banner extends flash.display.Sprite {
	
	static inline var NUM_PARTICLES : Int = 2000;
	static inline var EXPECTED_FPS : Float = 1000 / 30;
	
	var _renderer : LetterRenderer;
	var _emitter : Emitter;
	var _lastTime : Float;
	var _repeller : EffectPoint;
	
	public function new() super()
	
	public function init() {
		_renderer = new LetterRenderer( NUM_PARTICLES , "abcdefghijklmnopqrstuvwxyzåäö0123456789" , 800 , 600 , new flash.text.TextFormat( "RockwellExtraBold" , 36 , 0xF4BE1D ) );
		_renderer.addEventListener( flash.events.Event.COMPLETE , onLettersDone );
		_renderer.createLetters();
		
		addChild( new flash.display.Bitmap( _renderer ) );

		var gravity = new particles.Force( 0 , 0.97 , 0 );
		_repeller = new EffectPoint( Repel( .5 , 100 ) , 305 , 650 , 0 );
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
		p.friction = 0.03;
		p.addForce( gravity );
		p.addPoint( _repeller );
		
		_emitter = new Emitter( Pour( 1 ) , p , 160 , NUM_PARTICLES );
		_emitter.x = 300;
		_emitter.y = 200;
	}

	function onLettersDone(_) {
		_lastTime = haxe.Timer.stamp();
		addEventListener( flash.events.Event.ENTER_FRAME , update );
		#if debug
		addChild( new flash.display.Bitmap( _renderer.debug() ) );
		addChild( new flash.display.Bitmap( _renderer.debugMap.letter ) ).x = 20;
		addChild( render.Letter._tf );
		addTextBoxOverlay();
		#end
	}
	
	function update(_) {
		// Time scaling
		var t = haxe.Timer.stamp();
		var dt = ( t - _lastTime ) / EXPECTED_FPS * 1000;
		
		// Render
		var i = 0;
		_renderer.before();
		for( p in _emitter.emit() ) {
			if( p.update( dt ) )
				_renderer.render( p );
			i++;
		}
		_renderer.after();
		
		#if debug
		addChild( _repeller.debug() );
		var tot = Std.int( ( haxe.Timer.stamp() - t ) * 1000 );
	    var curFPS = 1000 / ( t - _lastTime );
	    fps = Std.int( ( fps * 10 + curFPS ) * .000909 ); // = / 11 * 1000
	    fdisplay.text = fps + " fps" + " " + tot + " ms" + " " + Std.int( flash.system.System.totalMemory / 1024 ) + " Kb" + " " + i + " particles";
		#end
		
		_lastTime = t;
	}
	
	#if debug
	var fps : Int;
	var fdisplay : flash.text.TextField;
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
	#end

	public static function main() {
		flash.Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		#if debug
		Trazzle.setRedirection();
		#end
		var m = new Banner();
		flash.Lib.current.addChild( m );
		m.init();
	}
}

class RockwellExtraBold extends flash.text.Font {}