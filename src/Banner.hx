import particles.Particle;
import particles.TileMap;
import particles.Emitter;
import particles.EffectPoint;
import render.LetterRenderer;

class Banner extends flash.display.Sprite {
	
	static inline var NUM_PARTICLES : Int = 30;
	#if slow
	static inline var EXPECTED_FPS : Float = 1000 / 18;
	#else
	static inline var EXPECTED_FPS : Float = 1000 / 30;
	#end
	public static var TEXT_FORMAT = new flash.text.TextFormat( "RockwellExtraBold" , 36 , 0xF4BE1D );
	
	var _tf : flash.text.TextField;
	var _text : String;
	var _renderer : LetterRenderer;
	var _emitter : Emitter;
	var _lastTime : Float;
	var _repeller : EffectPoint;
	var _tweens : Array<Dynamic>;
	var _width : Int;
	var _height : Int;
	var _timeout : Int;
	
	public function new() super()
	
	public function init() {
		var size = ( root.loaderInfo.parameters.size != null ) ? root.loaderInfo.parameters.size.split( "x" ) : [ Std.string( stage.stageWidth ) , Std.string( stage.stageHeight ) ];
		_width = Std.parseInt( size[0] );
		_height = Std.parseInt( size[1] );
		
		_timeout = ( root.loaderInfo.parameters.timeout != null ) ? Std.parseInt( root.loaderInfo.parameters.timeout ) : 3000; // ms
		_text = ( root.loaderInfo.parameters.text != null ) ? root.loaderInfo.parameters.text : "Café Opera 
har bytt till 
en godare 
irish coffee. 
Boka drink- 
bord här.  ";
		if( root.loaderInfo.parameters.textSize != null )
			TEXT_FORMAT.size = Std.parseFloat( root.loaderInfo.parameters.textSize );
		
		
		var chars = "abcdefghijklmnopqrstuvwxyzåäö0123456789";
		_renderer = new LetterRenderer( NUM_PARTICLES , chars , _width , _height , TEXT_FORMAT );
		_renderer.addEventListener( flash.events.Event.COMPLETE , onLettersDone );
		_renderer.createLetters();
		
		addChild( new flash.display.Bitmap( _renderer ) );

		#if slow
		var gravity = new particles.Force( 0 , 1.97 , 0 );
		#else
		var gravity = new particles.Force( 0 , 0.97 , 0 );
		#end
		_repeller = new EffectPoint( Repel( .5 , 100 ) , ( _width / 2 ) + 5 , _height + 50 , 0 );
		var bounds = {
			minX: 0.,
			maxX: _width + 0.,
			minY: 0.,
			maxY: _height + 0.,
			minZ: 0.,
			maxZ: 500.
		}
		
		var p1 = new Particle();
		p1.edgeBehavior = Remove;
		p1.bounds = bounds;
		p1.friction = 0.03;
		p1.addForce( gravity );
		p1.addPoint( _repeller );
		
		var p2 = new Particle();
		p2.edgeBehavior = Remove;
		p2.bounds = bounds;
		p2.friction = 0.03;
		p2.addForce( gravity );
		
//		_emitter = new Emitter( Pour( 2 ) , [ p1 , p2 ] , 60 , NUM_PARTICLES , .3 );
		_emitter = new Emitter( Custom( -.5 , .5 , 0 , 0 , -3 , 3 ) , [ p1 , p2 ] , 60 , NUM_PARTICLES , .3 );
		_emitter.x = _width / 2;
		_emitter.y = _height / 15;
	}

	function onLettersDone(_) {
		_lastTime = haxe.Timer.stamp();
		addEventListener( flash.events.Event.ENTER_FRAME , update );
		haxe.Timer.delay( showText , _timeout );
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
		_tf.x = _width / 2 - _tf.width / 2;
		_tf.y = _height / 2 - _tf.height / 2;
		//addChild( _tf );
		
		// Create alot of tweening copies
		_tweens = new Array<Dynamic>();
		for( i in 0..._tf.text.length ) {
			if( !StringTools.isSpace( _tf.text , i ) ) {
				var l = new Letter( _tf.text.charAt( i ) );
				l.x = _width / 2;
				l.y = _height;
				l.alpha = 0;
				l.rotation = -360 + Math.random() * 720;
				var pos = _tf.getCharBoundaries( i );
				l.targetX = _tf.x + pos.x - 2;
				l.targetY = _tf.y + pos.y - 2;
				l.delay = Std.int( Math.random() * 20 );
				_tweens.push( l.tween );
				addChild( l );
			}
		}
		
		var lastCharPosition = _tf.getCharBoundaries( _text.length - 1 );
		var arr = flash.Lib.attach( "Arrow" );
		arr.x = _tf.x + lastCharPosition.x + lastCharPosition.width;
		arr.y = _tf.y + lastCharPosition.y + 9;
		arr.alpha = 0;
		var delay = 40;
		_tweens.push( function() {
			if( --delay > 0 ) 
				return false;
			arr.alpha += ( 1 - arr.alpha ) / 10;
			if( arr.alpha > .9 )
				arr.alpha = 1;
			return arr.alpha == 1;
		} );
		addChild( arr );
		
		
		_emitter.maxParticles = 0;
	}
	
	function update(_) {
		// Time scaling
		var t = haxe.Timer.stamp();
		var dt = ( t - _lastTime ) / EXPECTED_FPS * 1000;
		
		// Render
		var i = 0;
		_renderer.before();
		for( p in _emitter.emit() ) {
			if( p.update() )
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
        fdisplay.x = _width - fdisplay.width;
        fdisplay.y = _height - fdisplay.height;
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

class Letter extends flash.text.TextField {
	
	static inline var DIFF_PI : Float = Math.PI - Math.PI * 2;
	static inline var FIX_PI : Float = 1 / Math.sin( Math.PI );
	static var ID = 0;
	
	public var targetX : Float;
	public var targetY : Float;
	public var wave : Float;
	public var delay : Int;
	
	var _start : Float;
	var _id : Int;
	var _blur : Float;
	
	public function new( char ) {
		super();
		_id = ID++;
		antiAliasType = flash.text.AntiAliasType.ADVANCED;
		selectable = false;
		embedFonts = true;
		autoSize = flash.text.TextFieldAutoSize.LEFT;
		defaultTextFormat = Banner.TEXT_FORMAT;
		htmlText = char;
		cacheAsBitmap = true;
		wave = -100 + Math.random() * 200;
		_blur = 20;
	}
	
	public inline function tween() {
		if( Math.isNaN( _start ) )
			_start = y;
			
		if( --delay > 0 ) 
			return false;
		
		var dx = targetX - x;
		var dy = targetY - y;
		var progress = ( y - _start ) / ( targetY - _start );
		var pos = ( progress * 2 * Math.PI ) - Math.PI;
		var cx = wave * Math.sin( pos );
		x = targetX + cx;
		y += dy * ( progress * .5 + .03 );
		rotation += ( 0 - rotation ) / 4;
		var z = Math.cos( pos );
		_blur += ( 0 - _blur ) / 8;
		scaleX = scaleY = -z;
		filters = [ new flash.filters.BlurFilter( _blur , _blur ) ];
		alpha += ( 1 - alpha ) / 1.05;
		var done = Math.abs( progress ) > .995;
		if( done ) {
			x = targetX;
			y = targetY;
			rotation = 0;
			alpha = scaleX = scaleY = 1;
			filters = [];
		}
		return done;
	}
}

class RockwellExtraBold extends flash.text.Font {}