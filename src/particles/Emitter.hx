package particles;

enum EmitterType {
	Custom( vxMin : Float , vxMax : Float , vyMin : Float , vyMax : Float , vzMin : Float , vzMax : Float );
	Pour( spread : Float );
}
/*
man vill ju kunna bestämma riktning och spridning typ
och antal och livslängd
och en effekt typ att den alphar ut, eller så
byter färg kanske
hastighet
*/

import particles.VectorArray;

class Emitter {
	
	public var type : EmitterType;
	public var x : Float;
	public var y : Float;
	public var z : Float;
	public var maxLifetime : Int;
	public var maxParticles : Int;
	public var particlesPerFrame : Int;
	// TODO Would probably be better with a particle-by-second instead of particles-per-frame
	
	var _pool : ParticlePool;
	var _particles : de.polygonal.ds.DLL<Particle>;
	var _count : Int;
	
	public function new( type : EmitterType , particle : Particle , maxLifetime : Int , maxParticles : Int , particlesPerFrame : Int = 1 ) {
		this.type = type;
		this.maxParticles = maxParticles;
		this.maxLifetime = maxLifetime;
		this.particlesPerFrame = particlesPerFrame;
		var particle = particle.clone();
		particle.onRemove = removeParticle;
		_pool = new ParticlePool( particle , maxParticles );
		_particles = new de.polygonal.ds.DLL<Particle>();
		_count = 0;
	}
	
	public inline function position( x , y , z ) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function emit() {
		if( _count < maxParticles ) {
			for( i in 0...particlesPerFrame ) {
				var p = _pool.retrieve();
				p.reset();
				p.x = x;
				p.y = y;
				p.z = z;
				p.active = true;
				switch( type ) {
					case Custom( vxMin , vxMax , vyMin , vyMax , vzMin , vzMax ):
						p.vx = vxMin + Math.random() * ( vxMax - vxMin );
						p.vy = vyMin + Math.random() * ( vyMax - vyMin );
						p.vz = vzMin + Math.random() * ( vzMax - vzMin );
					case Pour( spread ):
						p.vx = ( spread * -.5 ) + Math.random() * ( spread + spread );
				}
				
				_particles.append( p );
				_count++;
				
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
		_pool.release( p );
		_particles.remove( _particles.nodeOf( p ) ); // This could probably be optimized
       	_count--;
       	//trace( "Removed a particle " + p.id + " lifetime: " + p.lifetime + " now has " + _count );
	}
	
	public inline function iterator() return _particles.iterator()

}