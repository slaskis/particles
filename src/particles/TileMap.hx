package particles;
/**
 Factory class which:
 - Takes a source IBitmapDrawable
 - Applies effect(s) (like "rotation") to it and creates a tilemap of it
 - Associated with a property? new Tile().get( "rotation" , 1 )
 - How about merging effects?
 - Creates multiple bitmaps if necessary

var t = new TileMap( source , 64 , 64 ); // Source and tile size (can the tile size be adjusted if needed?)
t.add( "rot" , Rotation( 180 ) , 60 ); // a rotation of 180 degrees over 60 frames
t.add( "scale" , Scale( 4 ) , 12 ); // a scale by 4x over 12 frames
// t now has 71 frames (one is always the same for every effect, the original, which is reused)
t.get( "rot" , 1 ); // Fetches the first frame of the rotation effect
t.add( "rotscale" , Combine( [ Rotation( 180 ) , Scale( 4 ) ] ) , 60 ); // a scale by 4 and rotation of 180 degrees over 60 frames
t.remove( "rot" );

*/
enum TileEffect {
	Combine( effects : Array<TileEffect> );
	Rotation( degrees : Float );
	Scale( x : Float , y : Float );
	Skew( x : Float , y : Float );
	Clip( from : flash.geom.Rectangle , to : flash.geom.Rectangle );
	Transform( from : flash.geom.Matrix , to : flash.geom.Matrix );
	Tint( color : UInt );
	Alpha( alpha : Float );
	Color( from : flash.geom.ColorTransform , to : flash.geom.ColorTransform );
	Filter( filter : flash.filters.BitmapFilter );
}

class EffectInfo {
	public var startFrame : Int;
	public var endFrame : Int;
	public var key : String;
	public var frames : Int;
	public var effect : TileEffect;
	public var currentEffect : TileEffect;
	public var colorTransform : flash.geom.ColorTransform;
	public var matrix : flash.geom.Matrix;
	public function new( key , start , end , frames , effect ) {
		this.key = key;
		this.startFrame = start;
		this.endFrame = end;
		this.frames = frames;
		this.effect = effect;
		this.currentEffect = effect;
	}
	public function toString() {
		return "[Effect key:" + key + " frames:"+ frames+ " effect:" + effect + " colorTransform:"+colorTransform+" matrix:"+matrix+"]";
	}
}

class MapInfo {
	public var tilesX : Int;
	public var tilesY : Int; 
	public var frames : Int;
	public function new( x , y ) {
		tilesX = x;
		tilesY = y;
		frames = x * y;
	}
	public function toString() {
		return tilesX + "x" + tilesY + "=" + frames;
	}
}

class TileMap {
	
	public static var ZERO_POINT : flash.geom.Point = new flash.geom.Point();
	
	#if flash10
	public static inline var MAX_TILE_MAP_WIDTH : Int = 4095; 
	public static inline var MAX_TILE_MAP_HEIGHT : Int = 4095;
	#else
	public static inline var MAX_TILE_MAP_WIDTH : Int = 2880;
	public static inline var MAX_TILE_MAP_HEIGHT : Int = 2880;
	#end
	
	static inline var TO_RADIANS : Float = Math.PI / 180;
	
	public var rect : flash.geom.Rectangle;
	public var smoothing : Bool;
	public var blendMode : flash.display.BlendMode;
	
	var _bitmaps : Array<flash.display.BitmapData>;
	var _source : flash.display.IBitmapDrawable;
	var _effects : Hash<EffectInfo>;
	var _numBitmaps : Int;
	var _resized : Bool;
	var _tmp : flash.display.BitmapData;
	var _origRect : flash.geom.Rectangle;
	var _tmpRect : flash.geom.Rectangle;
	var _maxRect : flash.geom.Rectangle;
	var _currentFrame : Int;
	var _totalFrames : Int;
	var _bitmapIndex : Int;
	var _framePosition : flash.geom.Point;
	var _mapInfo : MapInfo;
	var _tileMapWidth : Int;
	var _tileMapHeight : Int;
	
	public function new( source : flash.display.IBitmapDrawable , tileWidth : Int , tileHeight : Int ) {
		_source = source;
		_bitmaps = new Array<flash.display.BitmapData>();
		_effects = new Hash<EffectInfo>();
		rect = new flash.geom.Rectangle( 0 , 0 , tileWidth , tileHeight );
		blendMode = null;
		smoothing = false;
		_totalFrames = _currentFrame = 0;
		_origRect = rect.clone();
		_maxRect = rect.clone();
		_tmpRect = rect.clone();
		_framePosition = new flash.geom.Point();
	}
	
	public function add( key : String , effect : TileEffect , frames : Int ) {
		_effects.set( key , new EffectInfo( key , 0 , 0 , frames , effect ) );
		update();
	}
	
	public function remove( key : String ) {
		_effects.remove( key );
		update();
	}
	
	/**
	 * Getting a TileMap frame.
	 * 
	 * Updates the TileMap#rect and returns the bitmap to use.
	 */
	public inline function get( key : String , offset : Int ) {
		if( offset < 0 ) offset = 0;
		if( offset > _totalFrames ) offset = _totalFrames;
		var frame = getFrame( key , offset );
		rect.x = frame.x;
		rect.y = frame.y;
		return _bitmaps[ _bitmapIndex ];
	}
	
	/*
   		1. Calculate the necessary size of the bitmap(s)
   		1. 1. Create a bitmap if the size has changed
   		1. 2. Create more bitmaps if needed
   		2. Go through the effects, draw the frames
   		2. 1. If the drawing has caused the tile size to change, set a resize bool and stop drawing frames (but keep calculating to get the largest tile size)
   		2. 2. If the resize bool is set after gone over the effects, change the tile rect and run update again.
	*/
	function update() {
		trace( "Updating the TileMap using a tile size of " + rect );
		
		// TODO Set an "optimal" tile map size based on number of frames and framesizes.
		// If they're modified all bitmaps need to be removed
		_tileMapWidth = 480;
		_tileMapHeight = 480;
		
		// Calculate some MapInfo with the current sizes
		_mapInfo = new MapInfo( Math.ceil( _tileMapWidth / _maxRect.width ), Math.ceil( _tileMapHeight / _maxRect.height ) );
		trace( "Updating MapInfo: " + _mapInfo );
		
		// Create a temporary bitmap, if we haven't already, on which we write the effects and then copy onto the final bitmaps
		updateTempBitmap();
		
		// Clear the bitmaps
		for( b in _bitmaps )
			b.fillRect( b.rect , 0x0 );
		
		// Apply the effects to the source 
		_resized = false;
		_currentFrame = 0;
		for( e in _effects )
			applyEffect( e );
		
		// Try again if it's been resized
		if( _resized ) {
			trace( "Tile has to be resized from: " + rect + " to:" + _maxRect );
			update();
		}
		
		_totalFrames = _currentFrame;
		
		// Now it's ok to reset the tile rect
		rect = _maxRect.clone();
		_tmpRect = rect.clone();
	}
	
	inline function applyEffect( e : EffectInfo ) {
		// function draw( source : IBitmapDrawable, ?matrix : Matrix, ?colorTransform : ColorTransform, ?blendMode : BlendMode, ?clipRect : Rectangle, ?smoothing : Bool ) : Void
		e.startFrame = _currentFrame;
		
		var step = 1 / e.frames;
		for( f in 0...e.frames ) {
			calcEffect( e , step , f );
			if( !_resized )
				writeFrame( e );
		}
		/* Original:
		switch( e.effect ) {
			case Combine( effects ):
				// TODO This probably needs to do some kind of recursive applyEffect?
				
			case Rotation( degrees ):
				
				// It's because the interpolation of a rotation matrix is not linear, but follows
				// sine/cosine.
				
				var step = degrees / e.frames;
				var tmp = rect.clone();
				var m = new flash.geom.Matrix();
				for( f in 0...e.frames ) {
					var degree = f * step;
					var theta = degree * TO_RADIANS;
					m.identity();
					m.rotate( theta );
					tmp = getTransformBounds( m );
					if( tmp.width > _maxRect.width || tmp.height > _maxRect.height ) {
						if( tmp.width > _maxRect.width ) _maxRect.width = tmp.width;
						if( tmp.height > _maxRect.height ) _maxRect.height = tmp.height;
						_resized = true;
					} 
					if( !_resized ) {
						m.identity();
						m.translate( -rect.width * .5 , -rect.height * .5 );
						m.rotate( theta );
						m.translate( _maxRect.width * .5 , _maxRect.height * .5 );
						_tmp.fillRect( _maxRect , 0x0 );
						_tmp.draw( _source , m , null , blendMode , null , smoothing );
						writeFrame( e );
					}
				}
				
			case Scale( sx , sy ):
				var from = new flash.geom.Matrix();
				var to = new flash.geom.Matrix();
				to.scale( sx , sy );
				trace( "Scale: " + from + " - " + to );
				// TODO Does this really have to be untyped?
				untyped e.effect = Transform( from , to );
				applyEffect( e );
				
			case Skew( sx , sy ):
				var from = new flash.geom.Matrix();
				var to = new flash.geom.Matrix( 1 , sx , sy );
				trace( "Skew: " + from + " - " + to );
				untyped e.effect = Transform( from , to );
				applyEffect( e );
				
			case Transform( from , to ): 
				var step = 1 / e.frames;
				var m = new flash.geom.Matrix();
				for( f in 0...e.frames ) {
					interpolateMatrix( m , from , to , f * step );
					trace( "Step: " + (f * step) + " Frame: " + f + " Interpolated:" + m );
					var tmp = getTransformBounds( m );
					if( tmp.width > _maxRect.width || tmp.height > _maxRect.height ) {
						if( tmp.width > _maxRect.width ) _maxRect.width = tmp.width;
						if( tmp.height > _maxRect.height ) _maxRect.height = tmp.height;
						_resized = true;
					} 
					if( !_resized ) {
						var c = new flash.geom.Matrix();
						c.translate( -rect.width * .5 , -rect.height * .5 );
						c.concat( m );
						c.translate( _maxRect.width * .5 , _maxRect.height * .5 );
						_tmp.fillRect( _maxRect , 0x0 );
						_tmp.draw( _source , c , null , blendMode , null , smoothing );
						writeFrame( e );
					}
				}
			
			case Tint( color ):
				// Uses Color to tint to a color
				var from = new flash.geom.ColorTransform();
				var to = new flash.geom.ColorTransform();
				to.color = color;
				untyped e.effect = Color( from , to );
				applyEffect( e );
			
			case Alpha( alpha ):
				// Uses Color to fade to an alpha
				var from = new flash.geom.ColorTransform();
				from.alphaOffset = -255;
				from.alphaMultiplier = 1;
				var to = new flash.geom.ColorTransform();
				// TODO Why doesn't this work?! Changing the alpha doesn't seem to do anything?
				to.alphaOffset = 255;
				to.alphaMultiplier = alpha;
				untyped e.effect = Color( from , to );
				applyEffect( e );
				
			case Color( from , to ):
				var step = 1 / e.frames;
				var transform = new flash.geom.ColorTransform();
				for( f in 0...e.frames ) {
					interpolateColorTransform( transform , from , to , step * f );
					trace( "Color: " + transform );
					_tmp.draw( _source , null , transform , blendMode , null , smoothing );
					writeFrame( e );
				}
				
			case Clip( from , to ):
				var step = 1 / e.frames;
				var rect = new flash.geom.Rectangle();
				for( f in 0...e.frames ) {
					interpolateRectangle( rect , from , to , step * f );
					trace( "Clip: " + rect );
					_tmp.draw( _source , null , null , blendMode , rect , smoothing );
					writeFrame( e );
				}
				
			case Filter( filter ):
				// run applyFilter() after each draw
				// TODO How should the variables be interpolated? blurX,blurY etc
				// This might be interesting: http://www.senocular.com/flash/actionscript.php?file=ActionScript_3.0/com/senocular/gyro/InterpolateBevelFilter.as
			default:
				throw "Invalid effect: " + e;
		}
		*/
		e.endFrame = _currentFrame - 1;
		return e;
	}
	
	function calcEffect( e : EffectInfo , step : Float , f : Int , ?current = false ) {
		//trace( "Calc effect at frame:" + f + " step:" + step + " effect:" + e );
		var ef = if( current ) e.currentEffect else e.effect;
		switch( ef ) {
			case Combine( effects ):
				// Recursively updates the effects
				var effects : Array<TileEffect> = Type.enumParameters( e.effect )[0];
				//trace( "Combining: " + effects );
				for( fx in effects ) {
					e.currentEffect = fx;
					calcEffect( e , step , f , true );
				}
			
			case Rotation( degrees ):
			
				// Because the interpolation of a rotation matrix is not linear, but follows
				// sine/cosine, we need to do this special from the other transformations.
				var degree = f * ( degrees / e.frames );
				var theta = degree * TO_RADIANS;
				if( e.matrix == null ) 
					e.matrix = new flash.geom.Matrix();
				//trace( "Rotate: " + degree );
				// TODO This needs to be concatenated or if it's combined with a scale it wont work!
				e.matrix.identity();
				e.matrix.rotate( theta );
				var tmp = getTransformBounds( e.matrix );
				if( tmp.width > _maxRect.width || tmp.height > _maxRect.height ) {
					if( tmp.width > _maxRect.width ) _maxRect.width = tmp.width;
					if( tmp.height > _maxRect.height ) _maxRect.height = tmp.height;
					_resized = true;
				}
			
			case Scale( sx , sy ):
				var from = new flash.geom.Matrix();
				var to = new flash.geom.Matrix();
				to.scale( sx , sy );
				trace( "Scale: " + from + " - " + to );
				// TODO Does this really have to be untyped?
				untyped e.currentEffect = Transform( from , to );
				calcEffect( e , step , f , true );
			
			case Skew( sx , sy ):
				var from = new flash.geom.Matrix();
				var to = new flash.geom.Matrix( 1 , sx , sy );
				trace( "Skew: " + from + " - " + to );
				untyped e.currentEffect = Transform( from , to );
				calcEffect( e , step , f , true );
			
			case Transform( from , to ): 	
				if( e.matrix == null ) 
					e.matrix = new flash.geom.Matrix();
				interpolateMatrix( e.matrix , from , to , f * step );
				trace( "Step: " + ( f * step ) + " Frame: " + f + " Interpolated:" + e.matrix );
				var tmp = getTransformBounds( e.matrix );
				if( tmp.width > _maxRect.width || tmp.height > _maxRect.height ) {
					if( tmp.width > _maxRect.width ) _maxRect.width = tmp.width;
					if( tmp.height > _maxRect.height ) _maxRect.height = tmp.height;
					_resized = true;
				}
		
			case Tint( color ):
				// Uses Color to tint to a color
				var from = new flash.geom.ColorTransform();
				var to = new flash.geom.ColorTransform();
				to.color = color;
				untyped e.currentEffect = Color( from , to );
				calcEffect( e , step , f , true );
		
			case Alpha( alpha ):
				// Uses Color to fade to an alpha
				var from = new flash.geom.ColorTransform();
				from.alphaOffset = -255;
				from.alphaMultiplier = 1;
				var to = new flash.geom.ColorTransform();
				// TODO Why doesn't this work?! Changing the alpha doesn't seem to do anything?
				to.alphaOffset = 255;
				to.alphaMultiplier = alpha;
				// It's going backwards?
				untyped e.currentEffect = Color( from , to );
				calcEffect( e , step , f , true );
			
			case Color( from , to ):
				if( e.colorTransform == null )
					e.colorTransform = new flash.geom.ColorTransform();
				interpolateColorTransform( e.colorTransform , from , to , step * f );
			
			case Clip( from , to ):
				var rect = new flash.geom.Rectangle();
				// TODO The rectangle should be set in the effectinfo
				interpolateRectangle( rect , from , to , step * f );
				trace( "Clip: " + rect );
			
			case Filter( filter ):
				// run applyFilter() after each draw
				// TODO How should the variables be interpolated? blurX,blurY etc
				// This might be interesting: http://www.senocular.com/flash/actionscript.php?file=ActionScript_3.0/com/senocular/gyro/InterpolateBevelFilter.as
			default:
				throw "Invalid effect: " + e;
		}
		
		return e;
	}

	inline function interpolateMatrix( mi : flash.geom.Matrix , m1 : flash.geom.Matrix , m2 : flash.geom.Matrix , t : Float ) {
		mi.a = m1.a + ( m2.a - m1.a ) * t;
		mi.b = m1.b + ( m2.b - m1.b ) * t;
		mi.c = m1.c + ( m2.c - m1.c ) * t;
		mi.d = m1.d + ( m2.d - m1.d ) * t;
		mi.tx = m1.tx + ( m2.tx - m1.tx ) * t;
		mi.ty = m1.ty + ( m2.ty - m1.ty ) * t;
	}
	

	inline function interpolateColorTransform( mi : flash.geom.ColorTransform, m1 : flash.geom.ColorTransform , m2 : flash.geom.ColorTransform , t : Float ) {
		// TODO This can interpolate differently (HSB)
		// Can use the code from here: http://opensource.adobe.com/svn/opensource/flex/sdk/trunk/frameworks/projects/framework/src/mx/utils/HSBColor.as
		mi.redMultiplier = m1.redMultiplier + ( m2.redMultiplier - m1.redMultiplier ) * t;
		mi.greenMultiplier = m1.greenMultiplier + ( m2.greenMultiplier - m1.greenMultiplier ) * t;
		mi.blueMultiplier = m1.blueMultiplier + ( m2.blueMultiplier - m1.blueMultiplier ) * t;
		mi.alphaMultiplier = m1.alphaMultiplier + ( m2.alphaMultiplier - m1.alphaMultiplier ) * t;
		mi.redOffset = m1.redOffset + ( m2.redOffset - m1.redOffset ) * t;
		mi.greenOffset = m1.greenOffset + ( m2.greenOffset - m1.greenOffset ) * t;
		mi.blueOffset = m1.blueOffset + ( m2.blueOffset - m1.blueOffset ) * t;
		mi.alphaOffset = m1.alphaOffset + ( m2.alphaOffset - m1.alphaOffset ) * t;
	}
	
	inline function interpolateRectangle( ri : flash.geom.Rectangle , r1 : flash.geom.Rectangle , r2 : flash.geom.Rectangle , t : Float ) {
		ri.top = r1.top + ( r2.top - r1.top ) * t;
		ri.bottom = r1.bottom + ( r2.bottom - r1.bottom ) * t;
		ri.left = r1.left + ( r2.left - r1.left ) * t;
		ri.right = r1.right + ( r2.right - r1.right ) * t;
	}
	
	function getTransformBounds( trans : flash.geom.Matrix ) {
		var tempBounds = _origRect.clone();
		var tl = tempBounds.topLeft;
		var br = tempBounds.bottomRight;
		var tr = tl.clone();
		var bl = br.clone();
		tr.offset(br.x - tl.x, 0);
		bl.offset(0, br.y - tl.y);

		var points = [
			trans.transformPoint(tl),
			trans.transformPoint(br),
			trans.transformPoint(tr),
			trans.transformPoint(bl)
		];
		tempBounds.setEmpty();
		tempBounds.topLeft = trans.transformPoint(tl);
		for( p in points ) {
			if( tempBounds.right < p.x )	tempBounds.right = p.x;
			if( tempBounds.top > p.y )		tempBounds.top = p.y;
			if( tempBounds.left > p.x )		tempBounds.left = p.x;
			if( tempBounds.bottom < p.y ) 	tempBounds.bottom = p.y;
		}
		return tempBounds;
	}
	
	inline function updateTempBitmap() {
		if( _tmp == null || _tmp.width != _maxRect.width || _tmp.height != _maxRect.height )
			_tmp = new flash.display.BitmapData( Std.int( _maxRect.width ) , Std.int( _maxRect.height ) , true , 0x0 );
	}
	
	inline function writeFrame( effect : EffectInfo ) {
	//	trace( "Writing frame effect: " + effect );	
		var m = null;
		if( effect.matrix != null ) { 
			m = new flash.geom.Matrix();
			m.translate( -rect.width * .5 , -rect.height * .5 );
			m.concat( effect.matrix );
			m.translate( _maxRect.width * .5 , _maxRect.height * .5 );
		}
		_tmp.fillRect( _maxRect , 0x0 );
		_tmp.draw( _source , m , effect.colorTransform );
		var frame = getFrame( effect.key , _currentFrame - effect.startFrame );
		var bitmap = getBitmap( _bitmapIndex );
		bitmap.copyPixels( _tmp , _maxRect , frame );
		_currentFrame++;
	}
	
	
	inline function getFrame( key : String , frame : Int ) {
		var effect = _effects.get( key );
		if( effect == null ) throw "No effect found with key: " + key;
		var currentFrame = effect.startFrame + frame;
		_bitmapIndex = Math.floor( currentFrame / _mapInfo.frames );
		var frameIndexAtBitmap = currentFrame % _mapInfo.frames;
		var row = Math.floor( frameIndexAtBitmap / _mapInfo.tilesX );
		var col = Math.floor( frameIndexAtBitmap % _mapInfo.tilesX );
		_framePosition.x = col * _maxRect.width;
		_framePosition.y = row * _maxRect.height;
		//trace( "BitmapIndex: " + _bitmapIndex + ", FrameIndex: " + frameIndexAtBitmap + ", FramePos: " + framePos );
		return _framePosition;
	}
	
	
	public function getBitmap( index ) {
		if( _bitmaps[ index ] == null ) 
			_bitmaps[ index ] = new flash.display.BitmapData( _tileMapWidth , _tileMapHeight , true , 0x0 );
		return _bitmaps[ index ];
	}
	
}