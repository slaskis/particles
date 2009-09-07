package particles;

import particles.VectorArray;

class ParticlePool {
	
	var _original : Particle;
	var _available : Int;
	var _growthRate : Int;
	var _pool : Array<Particle>;
	
	public function new( original : Particle , ?growthRate : Int = 0x10 ) {
		_original = original;
		_growthRate = growthRate;
		_pool = new Array<Particle>();
	}
	
	public function retrieve() {
		if( _available == 0 ) {
			for( i in 0..._growthRate )
				_pool.push( _original.clone() );
			_available += _growthRate;
			trace( "Resized the Particle Pool" );
		}
		_available--;
		return _pool.shift();
	}
	
	public function release( particle : Particle ) {
		_pool.push( particle );
		_available++;
	}
	
}