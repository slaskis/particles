import particles.Particle;
import particles.TileMap;
import particles.Emitter;
import particles.EffectPoint;
import render.LetterRenderer;

class Banner extends flash.display.Sprite {
	
	static var NUM_PARTICLES = 60;
	#if slow
	static inline var EXPECTED_FPS = 1000 / 18;
	#else
	static inline var EXPECTED_FPS = 1000 / 30;
	#end
	public static var TEXT_FORMAT = new flash.text.TextFormat( "RockwellExtraBold" , 36 , 0xFFCB08 );
	
	var _tf : flash.text.TextField;
	var _text : String;
	var _renderer : LetterRenderer;
	var _emitter : Emitter;
	var _lastTime : Float;
	var _repeller : EffectPoint;
	var _tweens : Array<Dynamic>;
	var _width : Int;
	var _height : Int;
	var _margin : Int;
	var _timeout : Int;
	var _ppu : Float;
	var _arrow : flash.display.DisplayObject;
	var _content : flash.display.Sprite;
	var _tweenDone : Dynamic;
	
	public function new() super()
	
	public function init() {
		// Set some default values
		_width = stage.stageWidth;
		_height = stage.stageHeight;
		_ppu = .3;
		_timeout = 3000;
		_margin = 50;
		_text = "Café Opera 
har bytt till 
en godare 
irish coffee. 
Boka drink- 
bord här.  ";

		
		// Find values in "flash vars"
		for( param in Reflect.fields( root.loaderInfo.parameters ) ) {
			var val : String = untyped root.loaderInfo.parameters[ param ];
			switch( param ) {
				case "size":
					var sizes = val.split( "x" );
					_width = Std.parseInt( sizes[0] );
					_height = Std.parseInt( sizes[1] );
				case "ppu":
					_ppu = Std.parseInt( val );
				case "timeout":
					_timeout = Std.parseInt( val );
				case "text":
					_text = StringTools.replace( val , "\\n" , "\n" );
				case "margin":
					_margin = Std.parseInt( val );
				case "textSize":
					TEXT_FORMAT.size = Std.parseInt( val );
				case "numParticles":
					NUM_PARTICLES = Std.parseInt( val );
			}
		}
		
		
		var chars = "abcdefghijklmnopqrstuvwxyzåäö0123456789";
		_renderer = new LetterRenderer( NUM_PARTICLES , chars , TEXT_FORMAT );
		_renderer.addEventListener( flash.events.Event.COMPLETE , onLettersDone );
		_renderer.createLetters();
		addChild( _renderer );
		
		/*
		LetterRenderer.FRAME_TIME = EXPECTED_FPS - 10;
		_renderer = new BitmapLetterRenderer( NUM_PARTICLES , chars , _width , _height , TEXT_FORMAT );
		_renderer.addEventListener( flash.events.Event.COMPLETE , onLettersDone );
		_renderer.createLetters();	
		addChild( new flash.display.Bitmap( _renderer ) );
		*/

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
			minZ: -500.,
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
		_emitter = new Emitter( Custom( -.5 , .5 , 0 , 0 , -5 , 5 ) , [ p1 , p2 ] , 160 , NUM_PARTICLES , _ppu );
		_emitter.x = _width / 2;
		_emitter.y = _height / 15;
	}

	function onLettersDone(_) {
		reset();
		addEventListener( flash.events.Event.ENTER_FRAME , update );
		
		
		#if debug
		//addChild( new flash.display.Bitmap( _renderer.debug() ) );
		//addChild( new flash.display.Bitmap( _renderer.debugMap.letter ) ).x = 20;
		//addChild( render.Letter._tf );
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
		
		// Resize until it fits the window
		var lastSize = TEXT_FORMAT.size = 12;
		while( _tf.textWidth < _width - _margin && _tf.textHeight < _height - _margin ) {
			_tf.defaultTextFormat = TEXT_FORMAT;
			_tf.htmlText = _text;
			lastSize = TEXT_FORMAT.size;
			if( ++TEXT_FORMAT.size > 127 )
				break;
			trace( "Resizing to: " + TEXT_FORMAT.size );
		}
		TEXT_FORMAT.size = lastSize;
		_tf.defaultTextFormat = TEXT_FORMAT;
		_tf.htmlText = _text;
		
		_tf.x = _width / 2 - _tf.textWidth / 2;
		_tf.y = _height / 2 - _tf.textHeight / 2;
		//addChild( _tf );
		
		_content = new flash.display.Sprite();
		addChild( _content );
		
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
				_content.addChild( l );
			}
		}
		
		var lastCharIndex = _tf.text.length - 1;
		var lastLineIndex = _tf.getLineIndexOfChar( lastCharIndex );
		var lastLineMetrics = _tf.getLineMetrics( lastLineIndex );
		var lastCharPosition = _tf.getCharBoundaries( lastCharIndex );
		var arr = flash.Lib.attach( "Arrow" );
		var h = lastCharPosition.height * .7;
		arr.width = ( arr.width / arr.height ) * h;
		arr.height = h;
		arr.x = _tf.x + lastCharPosition.x + lastCharPosition.width;
		arr.y = _tf.y + lastCharPosition.y + lastLineMetrics.ascent - h;
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
		_content.addChild( arr );
		
		// Stop the emitting...
		_emitter.maxParticles = 0;
		_tweenDone = reset;
	}
	
	function reset() {
		if( _emitter != null )
			_emitter.maxParticles = NUM_PARTICLES;
		
		// Tween out the content
		if( _content != null && contains( _content ) ) {
			for( i in 0..._content.numChildren ) {
				var c = _content.getChildAt( i );
				var targetY = stage.stageHeight + 50;
				_tweens.push( function() {
					c.alpha += ( 0 - c.alpha ) / 6;
					return c.alpha < .01;
				} );
			}
			_tweenDone = clear;
		} else clear();
	}
	
	function clear() {
		if( _content != null && contains( _content ) ) {
			while( _content.numChildren > 0 ) {
				var c = _content.getChildAt( 0 );
				_content.removeChild( c );
			}
			removeChild( _content );
		}
		
		_lastTime = haxe.Timer.stamp();
		var o = this;
		haxe.Timer.delay( function() {
			// Wait a second before killing it
			haxe.Timer.delay( o.showText , 1000 );
		} , _timeout );
	}
	
	function update(_) {
		// Time scaling
		var t = haxe.Timer.stamp();
		var dt = ( t - _lastTime ) / EXPECTED_FPS * 1000;
		
		// Render
		var i = 0;
		_renderer.before();
		_emitter.z = -10 + Math.random() * 20;
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
						haxe.Timer.delay( _tweenDone , 3000 );
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
		
		var cTag = getClickTag();
		if( cTag != "" ) {
			var c = new flash.display.Sprite();
			c.graphics.beginFill( 0x0 , 0 );
			c.graphics.drawRect( 0 , 0 , flash.Lib.current.stage.stageWidth , flash.Lib.current.stage.stageHeight );
			c.buttonMode = true;
			c.addEventListener( flash.events.MouseEvent.CLICK , function(_) {
				flash.Lib.getURL( new flash.net.URLRequest( getClickTag() ) );
			} );
			c.addEventListener( flash.events.MouseEvent.MOUSE_OVER , function(e) {
				var arrow = e.target;
				
			} );
			flash.Lib.current.addChild( c );
		}
	}
	
	static function getClickTag() {
		var cTag = "";
		for( param in Reflect.fields( flash.Lib.current.root.loaderInfo.parameters ) ) {
			if( param.toLowerCase() == "clicktag" ) {
				cTag = param;
				break;
			}
		}
		return cTag;
	}
}

class Letter extends flash.text.TextField {
	
	static inline var DIFF_PI = Math.PI - Math.PI * 2;
	static inline var FIX_PI = 1 / Math.sin( Math.PI );
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