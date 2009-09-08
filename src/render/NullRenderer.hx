package render;

class NullRenderer implements IRenderer {
	public function new();
	public function before();
	public function render( p );
	public function after();
	public function clear();
	
	#if debug
	public function debug() return new flash.display.BitmapData(1,1)
	#end
}