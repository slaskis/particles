package render;

import particles.VectorArray;

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
	
	public inline function render( p : particles.Particle ) {
		var s = _shapes[ p.id - 1 ];
		if( !s.visible ) s.visible = true;
		s.x = p.x;
		s.y = p.y;
		s.z = p.z;
	}
	
	public inline function after();
	
	#if debug
	public function debug() : flash.display.BitmapData {
		var s = _shapes[0];
		var bmp = new flash.display.BitmapData( Std.int( s.width ) , Std.int( s.height ) , true , 0x0 );
		bmp.draw( s );
		return bmp;
	}
	#end
}

class Rect extends flash.display.Shape {
	public function new() {
		super();
		var c = Std.int( Math.random() * 0xFFFFFF );
		graphics.beginFill( c , 1 );
		graphics.drawRect( 0 , 0 , 20 , 20 );
		var c = Std.int( Math.random() * 0xFFFFFF );
		graphics.beginFill( c , 1 );
		graphics.drawRect( 5 , 5 , 10 , 10 );
	}
}