package world;

import flixel.FlxObject;

interface Groundable {
	public var ground:GroundComponent;
}

class GroundComponent extends Component {
	private var currentGrounds:Map<FlxObject, Bool>;
	private var currentGroundCount:Int;
	
	public var isGrounded(get, never):Bool;
	
	public function new() {
		super();
		currentGrounds = new Map<FlxObject, Bool>();
	}
	
	public function add(object:FlxObject):Void {
		if (!currentGrounds.exists(object)) {
			currentGrounds.set(object, true);
			currentGroundCount++;
		}
	}
	
	public function remove(object):Void {
		if (currentGrounds.exists(object)) {
			currentGrounds.remove(object);
			currentGroundCount--;
		}
	}
	
	private function get_isGrounded():Bool {
		return currentGroundCount > 0;
	}
}