package particles;

//import particles.VectorArray;

class ParticlePool {
	
	var _originals : Array<Particle>;
	var _available : Int;
	var _growthRate : Int;
	var _pool : Array<Particle>;
	
	public function new( originals : Array<Particle> , ?growthRate : Int = 0x10 ) {
		_originals = originals;
		_growthRate = growthRate;
		_pool = new Array<Particle>();
	}
	
	public function retrieve() {
		if( _available == 0 ) {
			for( i in 0..._growthRate )
				_pool.push( _originals[ Std.int( Math.random() * ( _originals.length - .01 ) ) ].clone() );
			_available += _growthRate;
		}
		_available--;
		return _pool.shift();
	}
	
	public function release( particle : Particle ) {
		_pool.push( particle );
		_available++;
	}
	
}