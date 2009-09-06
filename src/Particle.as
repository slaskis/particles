/*********************************************
 com.bit101.Particle class v1.1
 Copyright (c)2003 Keith Peters
 All Rights Reserved
 kp@bit-101.com
 Feel free to use this code, but if you redistribute the source, include this header.
 
 Instructions: Create a directory in your classes directory named "com".
 Inside that, create a directory named "bit101" and copy this file into it.
 Then create any movie clip, export it under any name, and under AS 2 Class, enter "com.bit101.Particle".
 All methods and properties of the Particle class will then be available to that movie clip.
 
 History:
 --------
 12/21/03:
 	- changed some methods into getter/setter properties
 		+ Instead of setDrag(true), say draggable = true
 		+ Instead of turnToPath(true), say turnToPath = true
 	- got rid of setWrap and replaced with edgeBehavior
 		+ Instead of setWrap(true), say edgeBehavior = "wrap"
 		+ Instead of setWrap(false), say edgeBehavior = "bounce" or "remove"
 	- added access modifiers
 	- moved onEnterFrame code to an attached clip at depth 1,000,000.
 	  This allows you to assign your own separate onEnterFrame code to the particle.
 	- added "com" to class path.
 	
 Public Properties:
 ------------------
 vx:Number - the velocity on the x axis. default is 0
 vy:Number - the velocity on the y axis. default is 0
 damp:Number - a pseudo-friction value. 1.0 is no friction. Usual values are between 0.9 and 1.0. default is 0.9
 bounce:Number - how much the particle will bounce from a wall. -1.0 will bounce with same force it hit with.
          default is -0.5
 grav:Number - how much velocity is added to vy each frame. Usual values are 0.0 to 2.0. default is 0
 maxSpeed:Number - maximum allowed speed in any direction for a particle.
            default is Number.MAX_VALUE (essentially infinity or no limit)
 wander:Number - gives particle a random motion. numbers between 0 and 5 works well. default is 0
 draggable:Boolean - if true, drag and throw is possible on the particle
 edgeBehavior:String - determines behavior when particle hits an edge of the world.
 			Can be set to "wrap", "bounce", or "remove"
 			wrap causes the particle to disappear and appear on the opposite edge of the space
 			bounce causes the particle to bounce off the edge at a speed determined by the bounce property
 			remove causes the particle to be permanently deleted if it leaves the space.
 turnToPath:Boolean - if true, particle will turn towards the direction it is moving in.
 
 Public Methods:
 ---------------
 setBounds(bounds:Object)
 	- sets the "walls" of the universe in which the particle will be able to travel
	- arguments:
		bounds. an object containing properties: xMin, xMax, yMin, yMax.
		        you can directly use the object returned from the method getBounds().
				default values are the Stage dimensions.

 gravToMouse(bGrav:Boolean [, force:Number])
 	- causes the particle to gravitate towards the mouse. it is advised that us use maxSpeed along with this,
	  as this method can create near infinite particle speeds.
	- arguments:
		bGrav. if true, particle will gravitate towards mouse. if false, it won't. default is false.
		force. the gravitational force applied to the particle.
		       generally high numbers of 1000 or more are used. default is 1000
		
 springToMouse(bSpring:Boolean [, force:Number])
 	- causes the particle to spring to the mouse
	- arguments:
		bSpring. if true, particle will spring to the mouse. if false, it won't. default is false.
		force. the strength of the spring. generally numbers less than 1 are used. default is 0.1
		
 repelMouse(bRepel:Boolean [, force:Number, minDist:Number])
 	- causes the particle to spring away from the mouse
	- arguments:
		bRepels. if true, particle will spring away from the mouse. if false it won't.
		force. the strength of the spring action. generally numbers less than 1 are used. default is 0.1
		minDist. the distance in pixels from the mouse that the particle will attempt maintain.
		         default is 100
	- returns:
		the index number of the point added (can be used to remove the point)
		
 addSpringPoint(x:Number, y:Number [, force:Number])
 	- adds a stationary point to which the particle will spring. any number of points can be added,
	  but the result will be that the particle will spring to an point which is the average of all points.
	- arguments:
		x, y. the point to which the particle will spring.
		force. the strength of the spring. default is 0.1
	- returns:
		the index number of the point added (can be used to remove the point)
		
 addGravPoint(x:Number, y:Number [, force:Number])
 	- adds a stationary point to which the particle will try to gravitate. any number of points can be added.
	- arguments:
		x, y. the point to which the particle will gravitate.
		force. the gravitational force of the point. default is 1000
	- returns:
		the index number of the point added (can be used to remove the point)
		
 addRepelPoint(x:Number, y:Number [, force:Number, minDist:Number])
 	- adds a stationary point which the particle will try to spring away from.
	  any number of points can be added.
	- arguments:
		x, y. the point the particle will try to avoid.
		force. the force of the spring. default is 0.1
		minDist. the distance in pixels from the point that the particle will try to maintain. default is 100
	- returns:
		the index number of the point added (can be used to remove the point)
		
 addSpringClip(clip:MovieClip [, force:Number])
 	- designates a movie clip to which the particle will spring towards. any number of clips can be added.
	- arguments:
		clip. a movie clip towards which the particle will spring.
		force. the strength of the spring. default is 0.1
	- returns:
		the index number of the clip added (can be used to remove the clip from the list)
		
 addGravClip(clip:MovieClip [, force:Number])
 	- designates a movie clip to which the particle will gravitate. any number of clips can be added.
	- arguments:
		clip. a movie clip towards which the particle will spring.
		force. the strength of the gravitation. default is 1000
	- returns:
		the index number of the clip added (can be used to remove the clip from the list)
 
 addRepelClip(clip:MovieClip [, force:Number, minDist:Number])
 	- designates a movie clip which the particle will spring away from. any number of clips can be added.
	- arguments:
		clip. a movie clip which the particle will spring away from.
		force. the strength of the spring. default is 0.1
		minDist. the distance in pixels from the point that the particle will try to maintain. default is 100
	- returns:
		the index number of the clip added (can be used to remove the clip from the list)
		
 removeSpringPoints(index:Number)
 	- removes a previously specified spring point
	- arguments:
		index. the number of the point to remove
		
 removeGravPoints(index:Number)
 	- removes a previously specified gravity point
	- arguments:
		index. the number of the point to remove

 removeRepelPoints(index:Number)
 	- removes a previously specified repel point
	- arguments:
		index. the number of the point to remove

 clearSpringPoints()
 	- removes all spring points
	
 clearGravPoints()
 	- removes all grav points
	
 clearRepelPoints()
 	- removes all repel points
	
 clearSpringClips()
 	- removes all spring points
	
 clearGravClips()
 	- removes all grav points
	
 clearRepelClips()
 	- removes all repel points
	
	
**********************************************/
class com.bit101.Particle extends MovieClip {
	//
	private var __vx:Number = 0;
	private var __vy:Number = 0;
	private var __k:Number = .2;
	private var __damp:Number = .9;
	private var __bounce:Number = -.5;
	private var __grav:Number = 0;
	private var __bounds:Object;
	private var __draggable:Boolean = false;
	private var __edgeBehavior:String = "bounce";
	private var __drag:Boolean;
	private var __oldx:Number;
	private var __oldy:Number;
	private var __maxSpeed:Number;
	private var __wander:Number = 0;
	private var __turn:Boolean = false;
	private var __springToMouse:Boolean = false;
	private var __mouseK:Number = .2;
	private var __gravToMouse:Boolean = false;
	private var __gravMouseForce:Number = 5000;
	private var __repelMouse:Boolean = false;
	private var __repelMouseMinDist:Number = 100;
	private var __repelMouseK:Number = .2;
	private var __springPoints:Array;
	private var __gravPoints:Array;
	private var __repelPoints:Array;
	private var __springClips:Array;
	private var __gravClips:Array;
	private var __repelClips:Array;
	private var __efClip:MovieClip;

	//
	public function Particle() {
		init();
	}
	private function init() {
		__bounds = new Object();
		setBounds({xMin:0, yMin:0, yMax:Stage.height, xMax:Stage.width});
		__maxSpeed = Number.MAX_VALUE;
		__springPoints = new Array();
		__gravPoints = new Array();
		__repelPoints = new Array();
		__springClips = new Array();
		__gravClips = new Array();
		__repelClips = new Array();
		createEmptyMovieClip("__efClip", 1000000);
		__efClip.onEnterFrame = __efHandler;
	}
	public function set vx(nVx:Number):Void {
		__vx = nVx;
	}
	public function get vx():Number {
		return __vx;
	}
	public function set vy(nVy:Number):Void {
		__vy = nVy;
	}
	public function get vy():Number {
		return __vy;
	}
	public function set damp(nDamp:Number):Void {
		__damp = nDamp;
	}
	public function get damp():Number {
		return __damp;
	}
	public function set bounce(nBounce:Number):Void {
		__bounce = nBounce;
	}
	public function get bounce():Number {
		return __bounce;
	}
	public function set grav(nGrav:Number):Void {
		__grav = nGrav;
	}
	public function get grav():Number {
		return __grav;
	}
	public function set maxSpeed(nMaxSpeed:Number) {
		__maxSpeed = nMaxSpeed;
	}
	public function get maxSpeed():Number {
		return __maxSpeed;
	}
	public function set wander(nWander:Number) {
		__wander = nWander;
	}
	public function get wander():Number {
		return __wander;
	}
	public function set edgeBehavior(sEdgeBehavior:String):Void {
		__edgeBehavior = sEdgeBehavior;
	}
	public function get edgeBehavior():String{
		return __edgeBehavior;
	}
	public function setBounds(oBounds) {
		__bounds.top = oBounds.yMin;
		__bounds.bottom = oBounds.yMax;
		__bounds.left = oBounds.xMin;
		__bounds.right = oBounds.xMax;
	}
	public function set draggable(bDrag) {
		__draggable = true;
		if (bDrag) {
			onPress = function () {
				this.startDrag();
				__drag = true;
			};
			onRelease = function () {
				this.stopDrag();
				__drag = false;
			};
			onReleaseOutside = function () {
				this.stopDrag();
				__drag = false;
			};
		}
		else {
			onPress = undefined;
			onRelease = undefined;
			onReleaseOutside = undefined;
			__drag = false;
		}
	}
	public function get draggable():Boolean {
		return __draggable;
	}
	public function set turnToPath(bTurn:Boolean):Void {
		__turn = bTurn;
	}
	public function get turnToPath():Boolean {
		return __turn;
	}
	private function __efHandler() {
 		_parent.__move();
	}
	private function __move(){
		if (__drag) {
			__vx = _x - __oldx;
			__vy = _y - __oldy;
			__oldx = _x;
			__oldy = _y;
		}
		else {
			if (__springToMouse) {
				__vx += (_parent._xmouse - _x) * __mouseK;
				__vy += (_parent._ymouse - _y) * __mouseK;
			}
			if (__gravToMouse) {
				var dx = _parent._xmouse - _x;
				var dy = _parent._ymouse - _y;
				var distSQ = dx * dx + dy * dy;
				var dist = Math.sqrt(distSQ);
				var force = __gravMouseForce / distSQ;
				__vx += force * dx / dist;
				__vy += force * dy / dist;
			}
			if (__repelMouse) {
				var dx = _parent._xmouse - _x;
				var dy = _parent._ymouse - _y;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist < __repelMouseMinDist) {
					var tx = _parent._xmouse - __repelMouseMinDist * dx / dist;
					var ty = _parent._ymouse - __repelMouseMinDist * dy / dist;
					__vx += (tx - _x) * __repelMouseK;
					__vy += (ty - _y) * __repelMouseK;
				}
			}
			for (var sp = 0; sp < __springPoints.length; sp++) {
				var point = __springPoints[sp];
				__vx += (point.x - _x) * point.k;
				__vy += (point.y - _y) * point.k;
			}
			for (var gp = 0; gp < __gravPoints.length; gp++) {
				var point = __gravPoints[gp];
				var dx = point.x - _x;
				var dy = point.y - _y;
				var distSQ = dx * dx + dy * dy;
				var dist = Math.sqrt(distSQ);
				var force = point.force / distSQ;
				__vx += force * dx / dist;
				__vy += force * dy / dist;
			}
			for (var rp = 0; rp < __repelPoints.length; rp++) {
				var point = __repelPoints[rp];
				var dx = point.x - _x;
				var dy = point.y - _y;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist < point.minDist) {
					var tx = point.x - point.minDist * dx / dist;
					var ty = point.y - point.minDist * dy / dist;
					__vx += (tx - _x) * point.k;
					__vy += (ty - _y) * point.k;
				}
			}
			for (var sc = 0; sc < __springClips.length; sc++) {
				var clip = __springClips[sc].clip;
				var k = __springClips[sc].k;
				__vx += (clip._x - _x) * k;
				__vy += (clip._y - _y) * k;
			}
			for (var gc = 0; gc < __gravClips.length; gc++) {
				var clip = __gravClips[gc].clip;
				var dx = clip._x - _x;
				var dy = clip._y - _y;
				var distSQ = dx * dx + dy * dy;
				var dist = Math.sqrt(distSQ);
				var force = __gravClips[gc].force / distSQ;
				__vx += force * dx / dist;
				__vy += force * dy / dist;
			}
			for (var rc = 0; rc < __repelClips.length; rc++) {
				var clip = __repelClips[rc].clip;
				var minDist = __repelClips[rc].minDist;
				var k = __repelClips[rc].k;
				var dx = clip._x - _x;
				var dy = clip._y - _y;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist < minDist) {
					var tx = clip._x - minDist * dx / dist;
					var ty = clip._y - minDist * dy / dist;
					__vx += (tx - _x) * k;
					__vy += (ty - _y) * k;
				}
			}
			__vx += Math.random() * __wander - __wander / 2;
			__vy += Math.random() * __wander - __wander / 2;
			__vy += __grav;
			__vx *= damp;
			__vy *= damp;
			var speed = Math.sqrt(__vx * __vx + __vy * __vy);
			if (speed > __maxSpeed) {
				__vx = __maxSpeed * __vx / speed;
				__vy = __maxSpeed * __vy / speed;
			}
			if (__turn) {
				_rotation = Math.atan2(__vy, __vx) * 180 / Math.PI;
			}
			_x += __vx;
			_y += __vy;
			if(__edgeBehavior == "wrap"){
				if (_x > __bounds.right + _width/2) {
					_x = __bounds.left - _width/2;
				} else if (_x < __bounds.left - _width/2){
					_x = __bounds.right + _width/2;
				}
				if(_y > __bounds.bottom + _height/2){
					_y = __bounds.top - _height/2;
				} else if (_y < __bounds.top - _height/2){
					_y = __bounds.bottom + _height/2;
				}
			} else if(__edgeBehavior == "bounce"){
				if (_x > __bounds.right - _width/2) {
					_x = __bounds.right - _width/2;
					__vx *= __bounce;
				} else if (_x < __bounds.left + _width/2){
					_x = __bounds.left + _width/2;
					__vx *= __bounce
				}
				if(_y > __bounds.bottom - _height/2){
					_y = __bounds.bottom - _height/2;
					__vy *= __bounce
				} else if (_y < __bounds.top + _height/2){
					_y = __bounds.top + _height/2;
					__vy *= __bounce;
				}
			} else if(__edgeBehavior == "remove"){
				if(_x > __bounds.right + _width/2 || _x < __bounds.left - _width/2 ||
				   _y > __bounds.bottom + _height/2 || _y < __bounds.top - _height/2){
					this.removeMovieClip();
				}
			}
 		}
 	};
	public function gravToMouse(bGrav:Boolean, force:Number) {
		if (bGrav) {
			if (!force) {
				var force = 1000;
			}
			__gravMouseForce = force;
			__gravToMouse = true;
		}
		else {
			__gravToMouse = false;
		}
	}
	public function springToMouse(bSpring:Boolean, force:Number) {
		if (bSpring) {
			if (!force) {
				var force = .1;
			}
			__mouseK = force;
			__springToMouse = true;
		}
		else {
			__springToMouse = false;
		}
	}
	public function repelMouse(bRepel:Boolean, force:Number, minDist:Number) {
		if (bRepel) {
			if (!force) {
				var force = .1;
			}
			if (!minDist) {
				var minDist = 100;
			}
			__repelMouseK = force;
			__repelMouseMinDist = minDist;
			__repelMouse = true;
		}
		else {
			__repelMouse = false;
		}
	}
	public function addSpringPoint(x:Number, y:Number, force:Number) {
		if (!force) {
			var force = .1;
		}
		__springPoints.push({x:x, y:y, k:force});
		return __springPoints.length - 1;
	}
	public function addGravPoint(x:Number, y:Number, force:Number) {
		if (!force) {
			var force = 1000;
		}
		__gravPoints.push({x:x, y:y, force:force});
		return __gravPoints.length - 1;
	}
	public function addRepelPoint(x:Number, y:Number, force:Number, minDist:Number) {
		if (!force) {
			var force = .1;
		}
		if (!minDist) {
			var minDist = 100;
		}
		__repelPoints.push({x:x, y:y, k:force, minDist:minDist});
		return __repelPoints.length - 1;
	}
	public function addSpringClip(clip:MovieClip, force:Number) {
		if (!force) {
			var force = .1;
		}
		__springClips.push({clip:clip, k:force});
		return __springClips.length - 1;
	}
	public function addGravClip(clip:MovieClip, force:Number) {
		if (!force) {
			var force = 1000;
		}
		__gravClips.push({clip:clip, force:force});
		return __gravClips.length - 1;
	}
	public function addRepelClip(clip:MovieClip, force:Number, minDist:Number) {
		if (!force) {
			var force = .1;
		}
		if (!minDist) {
			var minDist = 100;
		}
		__repelClips.push({clip:clip, k:force, minDist:minDist});
		return __repelClips.length - 1;
	}
	public function removeSpringPoint(index:Number) {
		__springPoints.splice(index, 1);
	}
	public function removeGravPoint(index:Number) {
		__gravPoints.splice(index, 1);
	}
	public function removeRepelPoint(index:Number) {
		__repelPoints.splice(index, 1);
	}
	public function removeSpringClip(index:Number) {
		__springClips.splice(index, 1);
	}
	public function removeGravClip(index:Number) {
		__gravClips.splice(index, 1);
	}
	public function removeRepelClip(index:Number) {
		__repelClips.splice(index, 1);
	}
	public function clearSpringPoints() {
		__springPoints = new Array();
	}
	public function clearGravPoints() {
		__gravPoints = new Array();
	}
	public function clearRepelPoints() {
		__repelPoints = new Array();
	}
	public function clearSpringClips() {
		__springClips = new Array();
	}
	public function clearGravClips() {
		__gravClips = new Array();
	}
	public function clearRepelClips() {
		__repelClips = new Array();
	}
}