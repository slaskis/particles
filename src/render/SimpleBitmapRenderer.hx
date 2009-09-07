package render;


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
	
	public inline function render( p : particles.Particle ) {
		_point.x = p.x - _source.width * .5;
		_point.y = p.y - _source.height * .5;
		copyPixels( _source , _source.rect , _point , null , _zero , true );
	}
	
	public inline function after() {
		unlock();
	}
	
}