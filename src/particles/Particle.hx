package particles;

enum EdgeBehavior {
	Wrap;
	Bounce;
	Remove;
}

typedef Bounds = {
	minX : Float,
	maxX : Float,
	minY : Float,
	maxY : Float,
	minZ : Float,
	maxZ : Float,
}

class Particle {
	
	static var PARTICLE_ID : Int = 0;
	
	public var vx : Float;
	public var vy : Float;
	public var vz : Float;
	
	/**
	 * Friction of the particle. 
	 * Value between 0 (no friction, never stops) and 1 (extreme friction, not moving)
	 */
	public var friction : Float;
	
	/**
	 * The mass of the particle, affects all forces and effect points.
	 * TODO
	 */
	public var mass : Float;
	
	/**
	 * Bounciness of the particle against edges. Only applied when bounds 
	 * is set and edgeBehavior is set to Bounce.
	 */
	public var bounce : Float;
	
	/**
	 * Defines the edges of the particle.
	 */
	public var bounds : Bounds;
	
	/**
	 * Maximum speed of the particle. In any direction.
	 */
	public var maxSpeed : Null<Float>;
	
	/**
	 * Random wandering of the particle. "jiggleness".
	 */
	public var wander : Float;
	
	/**
	 * The number of updates the particle has existed.
	 */
	public var lifetime : Int;
	
	/**
	 * How the particle should behave when a particle hits it's bounds.
	 */
	public var edgeBehavior : EdgeBehavior;
	
	public var x : Float;
	public var y : Float;
	public var z : Float;
	
	public var id(default,null) : Int;
	
	public var active : Bool;
	
	/**
	 * If set to true the direction axis is updated.
	 * TODO
	 */
	public var turn : Bool;
	
	public var direction : { x : Float , y : Float , z : Float };
	
	/**
	 * Callback for when the particle has been removed.
	 */
	public dynamic var onRemove : Particle -> Void;
	
	
	// Previous values
	var _x : Float;
	var _y : Float;
	var _z : Float;
	
	var _points : Array<EffectPoint>;
	var _forces : Array<Force>;
	
	public function new( x=0. , y=0. , z=0. ) {
		vx = vy = vz = wander = 0.;
		lifetime = 0;
		friction = .9;
		bounce = -.5;
		active = true;
		turn = false;
		bounds = null;
		edgeBehavior = Bounce;
		id = PARTICLE_ID++;
		
		_points = new Array<EffectPoint>();
		_forces = new Array<Force>();
		
		this.x = _x = x;
		this.y = _y = y;
		this.z = _z = z;
	}
	
	public function clone() {
		var p = new Particle( x , y , z );
		p.vx = vx;
		p.vy = vy;
		p.vz = vz;
		p.edgeBehavior = edgeBehavior;
		p.onRemove = onRemove;
		p.maxSpeed = maxSpeed;
		p.bounds = bounds;
		p.bounce = bounce;
		p.active = active;
		p.turn = turn;
		p.mass = mass;
		p.friction = friction;
		p.wander = wander;
		for( f in _forces )
			p.addForce( f );
		for( pt in _points )
			p.addPoint( pt );
		return p;
	}
	
	public function pushX( v : Float ) vx += v
	public function pushY( v : Float ) vy += v
	public function pushZ( v : Float ) vz += v
	public function push( x=0. , y=0. , z=0. ) {
		vx += x;
		vy += y;
		vz += z;
	}
	
	/**
	 * Applies a force to the particle. Returns the index 
	 * of the force.
	 */ 
	public function addForce( f : Force ) {
		return _forces.push( f );
	}
	
	/**
	 * Removes a force from the particle, using the index 
	 * returned when the force was added.
	 */
	public function removeForceByIndex( index : Int ) {
		return _forces.splice( index , 1 ).length > 0;
	}
	
	/**
	 * Removes a force from the particle, using the instance
	 * of the force.
	 */
	public function removeForce( f : Force ) {
		return _forces.remove( f );
	}
	
	/**
	 * Adds a spring point. Returns the index of the point for removal.
	 */
	public function addPoint( pt : EffectPoint ) {
		return _points.push( pt );
	}
	
	/**
	 * Removes a point by the point instance.
	 */
	public function removePoint( pt : EffectPoint ) {
		return _points.remove( pt );
	}
	
	/**
	 * Removes a point by the id.
	 */
	public function removePointByIndex( index : Int ) {
		return _points.splice( index , 1 ).length > 0;
	}
	
	/**
	 * The main update method, should be called periodically.
	 * Optional (but recommended) to pass a delta time scale.
	 * 
	 * Ex of how to use delta time scale:
	 * 
	 *    var now = haxe.Timer.stamp();
	 *    var dt = ( ( now - _lastTime ) / ( 1000 / EXPECTED_FPS ) ) * 1000;
	 *    particle.update( dt );
	 *    _lastTime = now;
	 *
	 * Returns true if the particle has been removed.
	 *    
	 */
	public inline function update( dt=1. ) {
		var deleted = false;

		if( active ) {
			// Update effect points
			for( pt in _points ) {
				switch( pt.type ) {
					case Spring( f ):
						vx += ( pt.x - x ) * f;
						vy += ( pt.y - y ) * f;
						vz += ( pt.z - z ) * f;
					case Repel( f , d ):
						var dx = pt.x - x;
						var dy = pt.y - y;
						var dz = pt.z - z;
						var dist = Math.sqrt( dx * dx + dy * dy + dz * dz );
						if( dist < d ) {
							var di = 1 / dist;
							var tx = pt.x - d * ( dx * di );
							vx += ( tx - x ) * f;
							var ty = pt.y - d * ( dy * di );
							vy += ( ty - y ) * f;
							var tz = pt.z - d * ( dz * di );
							vz += ( tz - z ) * f;
						}
					case Attract( f ):
						var dx = pt.x - x;
						var dy = pt.y - y;
						var dz = pt.z - z;
						var distSQ = dx * dx + dy * dy + dz * dz;
						var dist = Math.sqrt( distSQ );
						var force = f / distSQ;
						var di = 1 / dist;
						vx += force * ( dx * di );
						vy += force * ( dy * di );
						vz += force * ( dz * di );
				}
			}
		
			// Apply wander 
			if( wander != 0 ) {
				vx += Math.random() * wander - wander * .5;
				vy += Math.random() * wander - wander * .5;
				vz += Math.random() * wander - wander * .5;
			}
		
			// Apply forces
			for( f in _forces ) {
				vx += f.x;
				vy += f.y;
				vz += f.z;
			}
		
			// Apply friction
			vx *= 1 - friction;
			vy *= 1 - friction;
			vz *= 1 - friction;
		
			// Apply max speed
			if( maxSpeed != null ) {
				var speed = Math.sqrt( vx * vx + vy * vy + vz * vz );
				if( speed > maxSpeed ) {
					var si = 1 / speed;
					vx = maxSpeed * ( vx * si );
					vy = maxSpeed * ( vy * si );
					vz = maxSpeed * ( vz * si );
				}
			}
		
			// Apply turn
			if( turn ) {
				// TODO Turn the object in 3 angles (need a public direction/rotation property or something)
				
			}
		
			// Apply delta time scale
			// TODO Is this really the right way? It has different behavior depending on the fps this way
			// It might be that dt has to be applied to every other v* modifier
			// Or i calculate the dt wrong...
			if( dt != 1 ) {
				vx *= dt;
				vy *= dt;
				vz *= dt;
			}
			
			// Update the previous positions (will be needed to find the direction)
			_x = x;
			_y = y;
			_z = z;
			
			// Update the position
			x += vx;
			y += vy;
			z += vz;
			
			// Yes, it lived for another update
			lifetime++;
		
			// Check edges in 3 dimensions
			if( bounds != null ) {
				switch( edgeBehavior ) {
					case Wrap:
						if( x > bounds.maxX )		x = bounds.minX;
						else if( x < bounds.minX )	x = bounds.maxX;
						if( y > bounds.maxY )		y = bounds.minY;
						else if( y < bounds.minY )	y = bounds.maxY;
						if( z > bounds.maxZ ) 		z = bounds.minZ;
						else if( z < bounds.minZ )	z = bounds.maxZ;
					case Bounce:
						if( x > bounds.maxX ){		x = bounds.maxX; vx *= bounce; }
						else if( x < bounds.minX ){	x = bounds.minX; vx *= bounce; }
						if( y > bounds.maxY ){		y = bounds.maxY; vy *= bounce; }
						else if( y < bounds.minY ){	y = bounds.minY; vy *= bounce; }
						if( z > bounds.maxZ ){ 		z = bounds.maxZ; vz *= bounce; }
						else if( z < bounds.minZ ){	z = bounds.minZ; vz *= bounce; }
					case Remove:
						if( x > bounds.maxX || x < bounds.minX ||
							y > bounds.maxY || y < bounds.minY ||
							z > bounds.maxZ || z < bounds.minZ ) {
							if( onRemove != null )
								onRemove( this );
							deleted = true;
						}
					
				}
			}
		}
		
		return !deleted;
	}
	
	public inline function reset() {
		vz = vy = vx = 0.;
		lifetime = 0;
	}
	
	/**
	 * Applies the updated particle on an object with x,y,z properties.
	 */
	public inline function apply( obj : { x : Float , y : Float , z : Float } ) {
		var ret = update();
		obj.x = x;
		obj.y = y;
		obj.z = z;
		return ret;
	}
	
	public function toString() {
		return "[Particle x:" + x + " y:" + y + " z:" + z + "]";
	}
}

