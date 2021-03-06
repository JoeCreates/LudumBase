package world;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import nape.geom.Vec2;
import nape.shape.Polygon;
import world.WorldLoader;

typedef WorldObjectLoader = TiledObject->ObjectLayer->FlxBasic;

/**
 * Defines how to load objects into a world from a TiledMap
 * 
 * A WorldLoader can be used by many Worlds
 */
class WorldLoader {
	
	public var typeLoaders:Map<String, WorldObjectLoader>;
	
	public function new() {
		typeLoaders = new Map<String, WorldObjectLoader>();
		
		// Default type loaders
		// Submap
		typeLoaders.set("submap", function(to:TiledObject, layer:ObjectLayer) {
			var submap:World = new World(layer.world.scale);
			submap.load("assets/data/" + to.properties.get("map"), this);
			//submap.x = to.x * layer.world.scale.x;
			//submap.y = to.y * layer.world.scale.y;//TODO possibly dont need this
			return submap;
		});
	}
	
	/**
	 * Load the objects from a tiled map into a world
	 * 
	 * @param	layer        The layer into which objects are being loaded
	 * @param	tiledObjects The Tiled object layer data from which the world is being loaded
	 * @return  An ObjectLayer of loaded game objects
	 */
	public function load(layer:ObjectLayer, tiledObjects:TiledObjectLayer):ObjectLayer {
		// For each object in layer
		for (tObj in tiledObjects.objects) {
			// If the type is recognised by the loaded
			if (typeLoaders.exists(tObj.type.toLowerCase())) {
				// Call the loader function for that type with the object data
				var obj:FlxBasic = typeLoaders.get(tObj.type)(tObj, layer);
				// If necessary, map the objects name to this object
				if (tObj.name != null) {
					layer.world.namedObjects.set(tObj.name, obj);
				}
				// And add any created object to the group if it exists
				if (obj != null) {
					layer.add(obj);
				}
			} else {
				throw ("Error loading world. Object type undefined: " + tObj.type);
			}
		}
		
		return layer;
	}
	
}