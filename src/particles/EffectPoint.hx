package particles;

enum EffectType {
	Spring( force : Null<Float> );
	Repel( force : Null<Float> , minDistance : Null<Float> );
	Attract( force : Null<Float> );
}

class EffectPoint implements haxe.Public {
	
	var type : EffectType;
	var x : Float;
	var y : Float;
	var z : Float;
	
	public function new( type , x , y , z ) {
		this.type = type;
		this.x = x;
		this.y = y;
		this.z = z;
	}
}