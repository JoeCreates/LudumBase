package world;
import flixel.addons.nape.FlxNapeSpace;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import world.WorldLayer;

class CollisionLayer extends FlxObject implements WorldLayer {

	public var body:Body;
	public var bodyOffset:BodyOffset;
	public var world:world.World;
	public var layerType:WorldLayerType;
	
	public function new(world:World) {
		super();
		this.world = world;
		layerType = WorldLayerType.COLLISION;
		body = new Body(BodyType.STATIC);
		body.space = FlxNapeSpace.space;
		bodyOffset = new BodyOffset(body);
		body.userData.gameObject = this;
	}
	
	public function placePolygon(vertices:Array<Vec2>, ?mat:Material) {
		body.space = null;
		var polygon:Polygon = new Polygon(vertices, mat);
		body.shapes.add(polygon);
		body.space = FlxNapeSpace.space;
		
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