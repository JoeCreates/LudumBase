package world;

import flixel.math.FlxPoint;
import nape.phys.Body;

/**
 * This is a hack to allow scaled nape tilemaps because flixel's origin is broken for scaled stuff
 */
class BodyOffset extends FlxPoint {
	
	public var body:Body;
	
	public function new(body:Body) {
		super();
		this.body = body;
	}
	
	/**
	 * Offset becomes the current difference between given coords and current body position
	 */
	public function lock(currentX:Float, currentY:Float):Void {
		set(body.position.x - currentX, body.position.y - currentY);
	}
	
}