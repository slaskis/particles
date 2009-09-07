package render;
interface IRenderer {
	public function clear() : Void;
	public function before() : Void;
	public function after() : Void;
	public function render( p : particles.Particle ) : Void;
}
