import particles.Particle;
import particles.TileMap;
import particles.Emitter;
import particles.EffectPoint;
import render.LetterRenderer;

class Banner extends flash.display.Sprite {
	
	static inline var NUM_PARTICLES : Int = 300;
	static inline var EXPECTED_FPS : Float = 1000 / 30;
	static var TEXT_FORMAT : flash.text.TextFormat = new flash.text.TextFormat( "RockwellExtraBold" , 36 , 0xF4BE1D );
	
	var _tf : flash.text.TextField;
	var _text : String;
	var _renderer : LetterRenderer;
	var _emitter : Emitter;
	var _lastTime : Float;
	var _repeller : EffectPoint;
	var _tweens : Array<Dynamic>;
	
	public function new() super()
	
	public function init() {
		
		_text = "Café Opera 
har bytt till 
en godare 
irish coffee. 
Boka drink- 
bord här.  ";
		
		var chars = "abcdefghijklmnopqrstuvwxyzåäö0123456789";
		_renderer = new LetterRenderer( NUM_PARTICLES , chars , 800 , 600 , TEXT_FORMAT );
		_renderer.addEventListener( flash.events.Event.COMPLETE , onLettersDone );
		_renderer.createLetters();
		
		addChild( new flash.display.Bitmap( _renderer ) );

		var gravity = new particles.Force( 0 , 0.97 , 0 );
		_repeller = new EffectPoint( Repel( .5 , 100 ) , ( stage.stageWidth / 2 ) + 5 , stage.stageHeight + 50 , 0 );
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
		
		_emitter = new Emitter( Pour( 1 ) , p , 60 , NUM_PARTICLES );
		_emitter.x = stage.stageWidth / 2;
		_emitter.y = 50;
	}

	function onLettersDone(_) {
		_lastTime = haxe.Timer.stamp();
		addEventListener( flash.events.Event.ENTER_FRAME , update );
		haxe.Timer.delay( showText , 3000 );
		#if debug
		addChild( new flash.display.Bitmap( _renderer.debug() ) );
		addChild( new flash.display.Bitmap( _renderer.debugMap.letter ) ).x = 20;
		addChild( render.Letter._tf );
		addTextBoxOverlay();
		#end
	}
	
	function showText() {
		// Instantiate the original
		_tf = new flash.text.TextField();
		_tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		_tf.selectable = false;
		_tf.embedFonts = true;
		_tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		_tf.defaultTextFormat = TEXT_FORMAT;
		_tf.htmlText = _text;
		_tf.x = stage.stageWidth / 2 - _tf.width / 2;
		_tf.y = stage.stageHeight / 2 - _tf.height / 2;
		//addChild( _tf );
		
		// Create alot of tweening copies
		_tweens = new Array<Dynamic>();
		for( i in 0..._tf.text.length ) {
			if( !StringTools.isSpace( _tf.text , i ) ) {
				var char = _tf.text.charAt( i );
				var ctf = createTextField( char );
				ctf.x = stage.stageWidth / 2;
				ctf.y = stage.stageHeight;
				ctf.alpha = 0;
				ctf.rotation = -180 + Math.random() * 360;
				var pos = _tf.getCharBoundaries( i );
				var targetX = _tf.x + pos.x - 2;
				var targetY = _tf.y + pos.y - 2;
				_tweens.push( function() {
					var dx = targetX - ctf.x;
					var dy = targetY - ctf.y;
					ctf.x += dx / 5;
					ctf.y += dy / 4;
					ctf.rotation += ( 0 - ctf.rotation ) / 4;
					ctf.alpha += ( 1 - ctf.alpha ) / 10;
					if( ctf.alpha > .9 )
						ctf.alpha = 1;
					return ( Math.abs( dx ) < 1 && Math.abs( dy ) < 1 );
				} );
			}
		}
		
		var lastCharPosition = _tf.getCharBoundaries( _text.length - 1 );
		var arr = flash.Lib.attach( "Arrow" );
		var targetX = _tf.x + lastCharPosition.x + lastCharPosition.width;
		var targetY = _tf.y + lastCharPosition.y + 9;
		arr.x = stage.stageWidth / 2;
		arr.y = stage.stageHeight;
		arr.alpha = 0;
		_tweens.push( function() {
			arr.x += ( targetX - arr.x ) / 2;
			arr.y += ( targetY - arr.y ) / 2;
			arr.alpha += ( 1 - arr.alpha ) / 10;
			if( arr.alpha > .9 )
				arr.alpha = 1;
			return arr.alpha == 1;
		} );
		addChild( arr );
		
		
		_emitter.maxParticles = 0;
	}
	
	function createTextField( str ) {
		var tf = new flash.text.TextField();
		tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		tf.selectable = false;
		tf.embedFonts = true;
		tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		tf.defaultTextFormat = TEXT_FORMAT;
		tf.htmlText = str;
		return addChild( tf );
	}
	
	function extractCharacters( str ) {
		var chars = "";
		for( i in 0...str.length ) {
			var char = str.charAt( i );
			if( chars.indexOf( char ) == -1 )
				chars += char;
		}
		return chars;
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
		
		var i = 0;
		if( _tweens != null ) {
			for( t in _tweens ) {
				var done = Reflect.callMethod( this , t , [] );
				if( done ) {
					_tweens.splice( i , 1 );
					if( _tweens.length == 0 ) {
						// Done, need to do something here?
					}
				}
				i++;
			}
		}
		
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