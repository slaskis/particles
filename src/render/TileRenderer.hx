package render;


class TileRenderer extends flash.display.BitmapData , implements IRenderer {
	var _clear : flash.display.BitmapData;
	var _map : particles.TileMap;
	var _point : flash.geom.Point;
	var _zero : flash.geom.Point;
	var _rot : Int;
	var _w : Float;
	var _h : Float;
	
	public function new( map : particles.TileMap , width , height ) {
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
	
	public inline function render( p : particles.Particle ) {
		_point.x = p.x - _w;
		_point.y = p.y - _h;
		var bmp = _map.get( "rotation" , 60 - ( p.lifetime % 60 ) );
		copyPixels( bmp , _map.rect , _point , null , null , true );
	}
	
	public inline function after() {
		unlock();
	}
	
	#if debug
	public function debug() : flash.display.BitmapData {
		return _map.getBitmap(0);
	}
	#end
}
