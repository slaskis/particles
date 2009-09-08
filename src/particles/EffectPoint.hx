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
	
	public function toString() {
		return "[EffectPoint x:"+x+" y:"+y+" z:"+z+" type:"+type+"]";
	}
	
	#if debug
	var _dbg : flash.display.Shape;
	public function debug() {
		if( _dbg == null ) {
			var c = Std.int( Math.random() * 0xFFFFFF ); 
			var s = new flash.display.Shape();
			s.graphics.beginFill( c , .3 );
			var radius = switch( type ) {
				case Spring( f ): f * 100;
				case Repel( f , d ): d;
				case Attract( f ): f * .1;
			}
			s.graphics.drawCircle( 0 , 0 , radius );
			_dbg = s;
		}
		_dbg.x = x;
		_dbg.y = y;
		#if flash10
		_dbg.z = z;
		#end
		return _dbg;
	}
	#end
}