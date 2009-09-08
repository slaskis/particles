package render;
interface IRenderer {
	#if debug
	public function debug() : flash.display.BitmapData;
	#end
	public function clear() : Void;
	public function before() : Void;
	public function after() : Void;
	public function render( p : particles.Particle ) : Void;
}
