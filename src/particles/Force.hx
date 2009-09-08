package particles;

class Force implements haxe.Public {
	var x : Float;
	var y : Float;
	var z : Float;
	
	public function new( ?x=0. , ?y=0. , ?z=0. ) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function toString() {
		return "[Force x:" + x + " y:" + y + " z:" + z + "]";
	}
}