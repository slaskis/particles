package particles;

class ParticlePool {
	
	var _original : Particle;
	var _available : Int;
	var _growthRate : Int;
	var _pool : haxe.FastList<Particle>;
	
	public function new( original : Particle , ?growthRate : Int = 0x10 ) {
		_original = original;
		_growthRate = growthRate;
		_pool = new haxe.FastList<Particle>();
	}
	
	public function release( particle : Particle ) {
		_pool.add( particle );
		_available++;
	}
	
	public function retrieve() {
		if( _available == 0 ) {
			for( i in 0..._growthRate )
				_pool.add( _original.clone() );
			_available += _growthRate;
		}
		_available--;
		return _pool.pop();
	}
	
}