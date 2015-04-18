package world;

import config.Config;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.addons.nape.FlxNapeTilemap;
import flixel.FlxBasic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.callbacks.PreCallback;
import nape.callbacks.PreFlag;
import nape.callbacks.PreListener;
import nape.constraint.Constraint;
import nape.constraint.WeldJoint;
import nape.dynamics.CollisionArbiter;
import nape.geom.Mat23;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.FluidProperties;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Shape;
import openfl.Assets;
import haxe.io.Path;
import haxe.xml.Parser;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import openfl.display.BitmapData;
import states.PlayState;
import world.WorldLayer.WorldLayerType;

/**
 * A 2D world using Tiled maps, Nape Physics, and hxDynaLight lighting
 * 
 * Consists of TileLayers and FlxGroups of game objects.
 */
class World extends FlxGroup {
	
	private static inline var TILESET_PATH = "assets/images/";
	public static inline var DEFAULT_WORLD_MASS = 10000000;
	public static inline var DEFAULT_WORLD_INERTIA = 10000000;
	
	// Collision callback types
	public static var groundCollisionType:CbType = new CbType();
	public static var onewayCollisionType:CbType = new CbType();
	public static var actorCollisionType:CbType = new CbType();
	
	/** TiledMap data */
	public var tiledMap:TiledMap;
	
	public var namedObjects:Map<String, FlxBasic>;
	public var namedLayers:Map<String, WorldLayer>;
	
	public var x(default, set):Float;
	public var y(default, set):Float;
	
	//TODO multiple light layers
	//public var lighting:LightLayer;
	
	public var scale:FlxPoint;
	
	/** The main body of this world. Attach bodies to this. */
	public var body:Body;
	
	public function new(?scale:FlxPoint) {
		super();
		this.scale = (scale == null) ? new FlxPoint(1, 1) : scale;
		
		namedObjects = new Map<String, FlxBasic>();
		namedLayers = new Map<String, WorldLayer>();
	}
	
	public function load(tiledLevel:Dynamic, worldLoader:WorldLoader,
	                     ?bodyType:BodyType, ?pivot:FlxPoint):Void {
		tiledMap = new TiledMap(tiledLevel);
		
		// Create and position body to center of map, or pivot if specified
		if (bodyType == null) bodyType = BodyType.KINEMATIC;
		body = new Body(bodyType, pivot != null ?
			Vec2.get(pivot.x, pivot.y) :
			Vec2.get(tiledMap.fullWidth * scale.x / 2, tiledMap.fullHeight * scale.y / 2));
		body.space = FlxNapeSpace.space;
			
		// Camera scroll bounds
		FlxG.camera.setScrollBoundsRect(0, 0, tiledMap.fullWidth, tiledMap.fullHeight, true);
		FlxG.camera.maxScrollY += FlxG.height / 2;
		
		// Load tileset graphics
		var tilesetBitmaps:Array<BitmapData> = new Array<BitmapData>();
		for (tileset in tiledMap.tilesets) {
			var imagePath = new Path(tileset.imageSource);
			var processedPath = TILESET_PATH + imagePath.file + "." + imagePath.ext;
			tilesetBitmaps.push(FlxAssets.getBitmapData(processedPath));
		}
		
		// Combine tilesets into single tileset
		var tileSize:FlxPoint = FlxPoint.get(tiledMap.tileWidth, tiledMap.tileHeight);
		var combinedTileset:FlxTileFrames = FlxTileFrames.combineTileSets(tilesetBitmaps, tileSize);
		tileSize.put();
		
		// Load layers into PhysicsTilemaps
		for (tiledLayer in tiledMap.layers) {
			switch (tiledLayer.type) {
				case TiledLayerType.OBJECT:
					
					// Collision Layer
					if (tiledLayer.properties.contains("collision")) {
						var cl:CollisionLayer = loadCollisionLayer(cast tiledLayer);
						cl.body.cbTypes.add(groundCollisionType);
						if (tiledLayer.properties.get("collision") == "oneway") {
							cl.body.cbTypes.add(onewayCollisionType);
						}
						namedLayers.set(tiledLayer.name, cl);
						add(cl);
					}
					
					// Object Layer
					else {
						var group:ObjectLayer = new ObjectLayer(this);
						worldLoader.load(group, cast tiledLayer);
						namedLayers.set(tiledLayer.name, group);
						for (m in group) {
							//TODO lots of badness can occur here because it is too specific
							if (Std.is(m, FlxNapeSprite)) {
								var s:FlxNapeSprite = cast m;
								s.setPosition(s.x * scale.x, s.y * scale.y);
							}
							else if (Std.is(m, FlxObject)) {
								var o:FlxObject = cast m;
								o.x *= scale.x;
								o.y *= scale.y;
							}
						}
						add(group);
					}
				case TiledLayerType.TILE:
					var tileLayer:TileLayer = loadTileLayer(cast tiledLayer, combinedTileset);
					namedLayers.set(tiledLayer.name, tileLayer);
					add(tileLayer);
			}
		}
		
		initCollisions();
	}
	
	public function loadCollisionLayer(tiledLayer:TiledObjectLayer):CollisionLayer {
		var cl:CollisionLayer = new CollisionLayer(this);
		for (to in tiledLayer.objects) {
			var points:Array<Vec2> = [];
			if (to.objectType == TiledObject.RECTANGLE) {
				points = [Vec2.get(0, 0), Vec2.get(to.width, 0),
						  Vec2.get(to.width, to.height), Vec2.get(0, to.height)];
			} else {
				for (p in to.points) {
					points.push(Vec2.get(p.x, p.y));
				}
			}
			var tilePosition:Vec2 = Vec2.get(to.x, to.y);
			for (p in points) {
				p.addeq(tilePosition);
			}
			cl.placePolygon(points);
		}
		
		//TODO repetition
		var tiledMap:TiledMap = tiledLayer.map;
		var mapWidth:Int = Std.int(tiledMap.fullWidth * scale.x);
		var mapHeight:Int = Std.int(tiledMap.fullHeight * scale.y);
		
		cl.origin.set(tiledMap.fullWidth / 2, tiledMap.fullHeight / 2);
		cl.scale.copyFrom(scale);
		
		cl.body.type = BodyType.DYNAMIC;
		cl.body.setShapeMaterials(new Material(0, 1, 2));
		// Center shapes about origin TODO do this in PhysicsTilemap
		for (shape in cl.body.shapes) {
			shape.translate(Vec2.get(-tiledMap.fullWidth / 2, -tiledMap.fullHeight / 2));
		}
		var matrix:Mat23 = Mat23.scale(scale.x, scale.y);
		cl.body.transformShapes(matrix);
		// Move origin of tilemap to center
		cl.body.position.setxy(mapWidth / 2, mapHeight / 2);
		
		weld(cl.body);
		
		return cl;
	}
	
	public function loadTileLayer(tiledLayer:TiledTileLayer, combinedTileset:FlxTilemapGraphicAsset):TileLayer {
		var tileLayer:TileLayer = new TileLayer(this);
		var tilemap:NapeSpriteTilemap = tileLayer.tilemap;
		var mapWidth:Int = Std.int(tiledMap.fullWidth * scale.x);
		var mapHeight:Int = Std.int(tiledMap.fullHeight * scale.y);
		
		tilemap.loadMapFromArray(tiledLayer.tileArray, tiledMap.width,  tiledMap.height, combinedTileset,
								 Std.int(tiledMap.tileWidth * scale.x),  Std.int(tiledMap.tileHeight * scale.y), FlxTilemapAutoTiling.OFF, 1, 1, 1);
		
		tileLayer.scale.copyFrom(scale);
		tileLayer.origin.set(tiledMap.fullWidth / 2, tiledMap.fullHeight / 2);
		tileLayer.offset.subtractPoint(tileLayer.origin);//TODO This is a hack to work around flixel issue
		
		// Collidable layers
		if (tiledLayer.properties.contains("collision")) {
			tilemap.setupCollideIndex(1);
			tilemap.body.cbTypes.add(groundCollisionType);
			if (tiledLayer.properties.get("collision") == "oneway") {
				tilemap.body.cbTypes.add(onewayCollisionType);
			}
		}
		
		tilemap.body.type = BodyType.DYNAMIC;
		tilemap.body.shapes.push(new Circle(10, null, new Material(0, 0, 0, 0, 0)));
		tilemap.body.setShapeMaterials(new Material(0, 1, 2));
		// Center shapes about origin TODO do this in PhysicsTilemap
		for (shape in tilemap.body.shapes) {
			shape.translate(Vec2.get(-tiledMap.fullWidth / 2, -tiledMap.fullHeight / 2));
		}
		var matrix:Mat23 = Mat23.scale(scale.x, scale.y);
		tilemap.body.transformShapes(matrix);
		// Move origin of tilemap to center
		tilemap.body.position.setxy(mapWidth / 2, mapHeight / 2);
		
		weld(tilemap.body);
		
		return tileLayer;
	}
	
	public function weld(weldBody:Body):Void {
		var j:WeldJoint = new WeldJoint(body, weldBody, Vec2.get(0, 0), Vec2.get(0, 0));
		j.stiff = true;
		j.breakUnderError = false;
		j.breakUnderForce = false;
		j.space = FlxNapeSpace.space;
	}
	
	public function getObject(name:String):FlxBasic {
		return namedObjects.get(name);
	}
	
	public function getLayer(name:String):WorldLayer {
		return namedLayers.get(name);
	}
	
	private function initCollisions():Void {
		// Oneway collision detection exception
		FlxNapeSpace.space.listeners.add(new PreListener(InteractionType.COLLISION,
			World.onewayCollisionType, World.actorCollisionType,
			function(cb:PreCallback) {
				//TODO this does not handle cases where both objects are grounds and groundable
				var groundBody:Body;
				var groundableBody:Body;
				var collision:CollisionArbiter = cb.arbiter.collisionArbiter;
				
				var body1IsGround:Bool = collision.body1.cbTypes.has(World.groundCollisionType);
				groundBody = body1IsGround ? collision.body1 : collision.body2;
				groundableBody = !body1IsGround ? collision.body1 : collision.body2;
				var collisionNormal:Float = FlxAngle.asDegrees(collision.normal.angle) - (body1IsGround ? 0 : 180);
				var groundable:Groundable = cast groundableBody.userData.gameObject;
				var ground:FlxObject = cast groundBody.userData.gameObject;
				
				// Ignore if not landing on ground
				if (!(collisionNormal >= Config.minGroundedAngle && collisionNormal <= Config.maxGroundedAngle)) {
					return PreFlag.IGNORE;
				}
				return PreFlag.ACCEPT;
			}));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.ONGOING, InteractionType.COLLISION,
			World.groundCollisionType, World.actorCollisionType,
			function(cb:InteractionCallback) {
				//TODO this does not handle cases where both objects are grounds and groundable
				var groundBody:Body;
				var groundableBody:Body;
				var collision:CollisionArbiter = cb.arbiters.at(0).collisionArbiter;
				
				var body1IsGround:Bool = collision.body1.cbTypes.has(World.groundCollisionType);
				groundBody = body1IsGround ? collision.body1 : collision.body2;
				groundableBody = !body1IsGround ? collision.body1 : collision.body2;
				
				var collisionNormal:Float = FlxAngle.asDegrees(collision.normal.angle) - (body1IsGround ? 0 : 180);
				var groundable:Groundable = cast groundableBody.userData.gameObject;
				var ground:FlxObject = cast groundBody.userData.gameObject;
				if (collisionNormal >= Config.minGroundedAngle && collisionNormal <= Config.maxGroundedAngle
				    && groundableBody.velocity.y >= -Config.gravity * FlxG.elapsed) {
					groundable.ground.add(ground);
				} else {
					groundable.ground.remove(ground);
				}
			}));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.END, InteractionType.COLLISION,
			World.groundCollisionType, World.actorCollisionType,
			function(cb:InteractionCallback) {
				var int1isGround:Bool = cb.int1.castBody.cbTypes.has(World.groundCollisionType);
				var groundable:Groundable = int1isGround ? cast cb.int2.userData.gameObject :  cast cb.int1.userData.gameObject;
				var ground:FlxObject = !int1isGround ? cast cb.int2.userData.gameObject :  cast cb.int1.userData.gameObject;
				groundable.ground.remove(ground);
			}));
	}
	
	//TODO casting ugliness
	private function set_x(x:Float):Float {
		var change:Float = x - this.x;
		this.x = x;
		//for (l in members) {
			//var layer:WorldLayer = cast l;
			//if (layer.layerType == WorldLayerType.TILE) {
				//var tl:TileLayer = cast layer;
				//tl.x += change;
			//}
		//}
		return x;
	}
	
	private function set_y(y:Float):Float {
		var change:Float = y - this.y;
		this.y = y;
		//for (l in members) {
			//var layer:WorldLayer = cast l;
			//switch(layer.layerType) {
				//case WorldLayerType.TILE:
					//var tl:TileLayer = cast layer;
					//tl.y += change;
				//case CollisionLayer:
					//var cl:CollisionLayer = cast layer;
					//cl.y += change;
				//default:
			//}
		//}
		return y;
	}
	
}

