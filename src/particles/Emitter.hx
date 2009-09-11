package particles;

enum EmitterType {
	Custom( vxMin : Float , vxMax : Float , vyMin : Float , vyMax : Float , vzMin : Float , vzMax : Float );
	Pour( spread : Float );
}
class Emitter {
	
	public var type : EmitterType;
	public var x : Float;
	public var y : Float;
	public var z : Float;
	public var maxLifetime : Int;
	public var maxParticles : Int;
	public var particlesPerUpdate : Float;
	
	var _pool : ParticlePool;
	var _particles : de.polygonal.ds.DLL<Particle>;
	var _count : Int;
	var _particlesToEmit : Float;
	
	public function new( type : EmitterType , originals : Array<Particle> , maxLifetime : Int , maxParticles : Int , particlesPerUpdate : Float = 1 ) {
		this.type = type;
		this.maxParticles = maxParticles;
		this.maxLifetime = maxLifetime;
		this.particlesPerUpdate = particlesPerUpdate;
		
		var styles = new Array<Particle>();
		for( o in originals ) {
			var p = o.clone();
			p.onRemove = removeParticle;
			styles.push( p );
		}
		_pool = new ParticlePool( styles , maxParticles );
		_particles = new de.polygonal.ds.DLL<Particle>();
		_particlesToEmit = 0.;
		_count = 0;
		x = y = z = 0.;
	}
	
	public inline function position( x , y , z ) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function emit() {
		if( _count < maxParticles ) {
			_particlesToEmit += particlesPerUpdate;
			for( i in 0...Std.int( _particlesToEmit ) ) {
				var p = _pool.retrieve();
				p.x = x;
				p.y = y;
				p.z = z;
				switch( type ) {
					case Custom( vxMin , vxMax , vyMin , vyMax , vzMin , vzMax ):
						p.vx = vxMin + Math.random() * ( vxMax - vxMin );
						p.vy = vyMin + Math.random() * ( vyMax - vyMin );
						p.vz = vzMin + Math.random() * ( vzMax - vzMin );
					case Pour( spread ):
						p.vx = ( spread * -.5 ) + Math.random() * ( spread + spread );
						p.vz = ( spread * -.5 ) + Math.random() * ( spread + spread );
				}
				
				_particles.append( p );
				_count++;
				_particlesToEmit--;
				
				//trace( "Added a particle " + p.id + " lifetime: " + p.lifetime + " now has " + _count );
				if( _count >= maxParticles )
					break;
			}
		}
		
		for( p in _particles )
			checkParticle( p );

		return this;
	}
	
	inline function checkParticle( p : Particle ) {
        if( p.lifetime > maxLifetime )
			removeParticle( p );
	}
	
	inline function removeParticle( p : Particle ) {
		p.reset();
		_pool.release( p );
		_particles.remove( _particles.nodeOf( p ) ); // This could probably be optimized
       	_count--;
       	//trace( "Removed a particle " + p.id + " lifetime: " + p.lifetime + " now has " + _count );
	}
	
	public inline function iterator() return _particles.iterator()

}