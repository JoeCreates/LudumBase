package world;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import world.WorldLoader;

/**
 * Defines how to load objects into a world from a TiledMap
 * 
 * A WorldLoader can be used by many Worlds
 */
class WorldLoader {
	
	public var typeLoaders:Map<String, TiledObject->FlxObject>;
	
	public function new() {
		typeLoaders = new Map<String, TiledObject->FlxObject>();
	}
	
	/**
	 * Load the obj
	 * 
	 * @param	world    The world into which objects are being loaded
	 * @param	tiledObjects The Tiled object layer data from which the world is being loaded
	 * @return  A FlxGroup of loaded game objects
	 */
	public function load(world:World, tiledObjects:TiledObjectLayer):FlxGroup {
		// The group into which objects are to be loaded
		var group:FlxGroup = new FlxGroup();
		
		// For each object in layer
		for (tObj in tiledObjects.objects) {
			// If the type is recognised by the loaded
			if (typeLoaders.exists(tObj.type)) {
				// Call the loader function for that type with the object data
				var obj:FlxObject = typeLoaders.get(tObj.type)(tObj);
				// If necessary, map the objects name to this object
				if (tObj.name != null) {
					world.namedObjects.set(tObj.name, obj);
				}
				// And add any created object to the group if it exists
				if (obj != null) {
					group.add(obj);
				}
			} else {
				throw ("Error loading world. Object type undefined: " + tObj.type);
			}
		}
		
		return group;
	}
	
}