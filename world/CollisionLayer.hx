package world;
import flixel.addons.nape.FlxNapeSpace;
import flixel.FlxObject;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import world.WorldLayer;

class CollisionLayer extends FlxObject implements PhysicalLayer {

	public var body:Body;
	public var world:world.World;
	public var layerType:WorldLayerType;
	public var origin:FlxPoint;
	public var scale:FlxPoint;
	
	public function new(world:World) {
		super();
		this.world = world;
		layerType = WorldLayerType.COLLISION;
		body = new Body(BodyType.DYNAMIC);
		body.space = FlxNapeSpace.space;
		body.mass = World.DEFAULT_WORLD_MASS;
		body.inertia = World.DEFAULT_WORLD_INERTIA;
		body.space = FlxNapeSpace.space;
		body.userData.gameObject = this;
		origin = FlxPoint.get(0, 0);
		scale = FlxPoint.get(1, 1);
	}
	
	public function placePolygon(vertices:Array<Vec2>, ?mat:Material) {
		body.space = null;
		var polygon:Polygon = new Polygon(vertices, mat);
		body.shapes.add(polygon);
		body.space = FlxNapeSpace.space;
		
	}
	
	public function updatePhysObjects():Void {
		x = body.position.x - origin.x * scale.x;
		y = body.position.y - origin.y * scale.y;
		if (body.allowRotation) {
			angle = body.rotation * FlxAngle.TO_DEG;
		}
	}
	
	override public function update(dt:Float):Void {
		super.update(dt);
		updatePhysObjects();
	}
	
	//override public function set_x(x:Float):Float {
		//this.x = x;
		//body.x = x + bodyOffset.x;
		//return x;
	//}
	//
	//override public function set_y(y:Float):Float {
		//this.y = y;
		//body.x = x + bodyOffset.y;
		//return y;
	//}
	
}