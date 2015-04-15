package world;

import config.Config;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.nape.FlxNapeSpace;
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
import nape.dynamics.CollisionArbiter;
import nape.geom.Mat23;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
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

/**
 * A 2D world using Tiled maps and Nape Physics.
 * 
 * Consists of TileLayers and FlxGroups of game objects.
 */
class World extends FlxGroup {
	
	private static inline var TILESET_PATH = "assets/images/";
	
	// Collision callback types
	public static var groundCollisionType:CbType = new CbType();
	public static var onewayCollisionType:CbType = new CbType();
	public static var actorCollisionType:CbType = new CbType();
	
	/** TiledMap data */
	public var tiledMap:TiledMap;
	
	public var worldLoader:WorldLoader;
	public var namedObjects:Map<String, FlxObject>;
	
	public var scale:FlxPoint;
	
	public function new(tiledLevel:Dynamic, worldLoader:WorldLoader, ?scale:FlxPoint) {
		super();
		
		this.scale = (scale == null) ? new FlxPoint(1, 1) : scale;
		
		this.worldLoader = worldLoader;
		
		namedObjects = new Map<String, FlxObject>();
		
		tiledMap = new TiledMap(tiledLevel);
		
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
					var group:FlxGroup = worldLoader.load(this, cast tiledLayer);
					for (m in group) {
						if (Std.is(m, FlxObject)) {
							var o:FlxObject = cast m;
							o.x *= scale.x;
							o.y *= scale.y;
						}
					}
					add(group);
				case TiledLayerType.TILE:
					var tileLayer:TileLayer = loadTileLayer(cast tiledLayer, combinedTileset);
					// TODO: flixel doesn't really allow for these to happen at the same time right now
					add(tileLayer);
					//add(tileLayer.tilemap);
			}
			
			//TODO rotation
			//tilemap.body.rotate(tilemap.body.position, FlxAngle.asRadians(10));
			//tilemap.angle = 10;
			//tilemap.sprite.origin.set();
			//tilemap.sprite.angle = 10;
			//
		}
		
		initCollisions();
	}
	
	public function loadTileLayer(tiledLayer:TiledTileLayer, combinedTileset:FlxTilemapGraphicAsset):TileLayer {
		var tileLayer:TileLayer = new TileLayer();
		var tilemap:NapeSpriteTilemap = tileLayer.tilemap;
		var mapWidth:Int = Std.int(tiledMap.fullWidth * scale.x);
		var mapHeight:Int = Std.int(tiledMap.fullHeight * scale.y);
		
		tilemap.loadMapFromArray(tiledLayer.tileArray, tiledMap.width,  tiledMap.height, combinedTileset,
								 Std.int(tiledMap.tileWidth * scale.x),  Std.int(tiledMap.tileHeight * scale.y), FlxTilemapAutoTiling.OFF, 1, 1, 1);
		
		tileLayer.scale.copyFrom(scale);
		tileLayer.origin.set(tiledMap.fullWidth / 2, tiledMap.fullHeight / 2);
		tileLayer.offset.subtractPoint(tileLayer.origin);//Hack to work around flixel issue
		
		// Collidable layers
		if (tiledLayer.properties.contains("collision")) {
			tilemap.setupCollideIndex(1);
			tilemap.body.cbTypes.add(groundCollisionType);
			if (tiledLayer.properties.get("collision") == "oneway") {
				tilemap.body.cbTypes.add(onewayCollisionType);
			}
		}
		
		// TODO define in editor
		tilemap.body.type = BodyType.KINEMATIC;
		
		// Center shapes about origin TODO do this in PhysicsTilemap
		for (shape in tilemap.body.shapes) {
			shape.translate(Vec2.get(-tiledMap.fullWidth / 2, -tiledMap.fullWidth / 2));
		}
		
		var matrix:Mat23 = Mat23.scale(scale.x, scale.y);
		tilemap.body.transformShapes(matrix);
		
		// Move origin of tilemap to center
		tilemap.body.position.setxy(mapWidth / 2, mapWidth / 2);
		
		return tileLayer;
	}
	
	public function getObject(name:String):FlxObject {
		return namedObjects.get(name);
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
				
				if (collisionNormal >= Config.minGroundedAngle && collisionNormal <= Config.maxGroundedAngle) {
					groundable.ground.add(ground);
				} else {
					groundable.ground.remove(ground);
				}
			}));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.END, InteractionType.COLLISION,
			World.groundCollisionType, World.actorCollisionType,
			function(cb:InteractionCallback) {
				var groundable:Groundable = cast cb.int2.userData.gameObject;
				groundable.ground.remove(cast cb.int1.userData.gameObject);
			}));
	}
	
}

