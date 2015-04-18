package world;

import flixel.addons.nape.FlxNapeTilemap;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.tile.FlxTilemapBuffer;
import nape.phys.Body;
import world.WorldLayer.WorldLayerType;

/** Allows you to treat a FlxNapeTilemap like a sprite. Kind of. */
//TODO make it so does it efficiently if spriteyness is not necessary
class TileLayer extends FlxSprite implements PhysicalLayer {
	
	public var layerType:WorldLayerType = WorldLayerType.TILE;
	
	public var tilemap:NapeSpriteTilemap;
	public var world:World;
	public var body:Body;
	
	public function new(world:World) {
		super();
		
		tilemap = new NapeSpriteTilemap(this);
		this.world = world;
		body = tilemap.body;
		body.mass = World.DEFAULT_WORLD_MASS;
		body.inertia = World.DEFAULT_WORLD_INERTIA;
	}
	
	override public function update(dt:Float):Void {
		super.update(dt);
		updatePhysObjects();
	}
	
	override public function draw():Void {
		//TODO potentially inefficient? if slowness, look here first
		tilemap.draw();
		super.draw();
	}
	
	public function updatePhysObjects():Void {
		var body:Body = tilemap.body;
		x = body.position.x - origin.x * scale.x;
		y = body.position.y - origin.y * scale.y;
		if (body.allowRotation) {
			angle = body.rotation * FlxAngle.TO_DEG;
		}
		trace(world.body.rotation + " " + body.allowRotation + " " + (body.rotation * FlxAngle.TO_DEG) + " " + angle);
	}
	
	
}