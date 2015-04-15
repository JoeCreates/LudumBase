package world;

import flixel.addons.nape.FlxNapeTilemap;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemapBuffer;
import flixel.system.FlxAssets;

/**
 * Not to be used like a normal tilemap, as this should not be directly rendered. Copy buffer to a sprite first.
 */
class NapeSpriteTilemap extends FlxNapeTilemap {

	public var sprite:FlxSprite;
	public var buffer(get, never):FlxTilemapBuffer;
	
	public function new(sprite:FlxSprite) {
		super();
		this.sprite = sprite;
		
		cameras = [new FlxCamera()];
		
		body.userData.gameObject = this;
	}
	
	override public function draw():Void {
		// Scale gets lost unless we keep record before copying buffer
		
		super.draw();
		
		var osx = sprite.scale.x;
		var osy = sprite.scale.y;
		var ox = sprite.origin.x;
		var oy = sprite.origin.y;
		
		// Set buffer as sprite's buffer
		sprite.pixels = buffer.pixels;
		
		sprite.scale.set(osx, osy);
		sprite.origin.set(ox, oy);
	}
	
	private function get_buffer():FlxTilemapBuffer {
		return _buffers[0];
	}
	
	public function fitCameraToMap():Void {
		camera.setSize(Std.int(widthInTiles * _tileWidth * scale.x), Std.int(widthInTiles * _tileWidth * scale.y));
	}
	
	override private function loadMapHelper(tileGraphic:FlxTilemapGraphicAsset, tileWidth:Int = 0, tileHeight:Int = 0, ?autoTile:FlxTilemapAutoTiling,
		startingIndex:Int = 0, drawIndex:Int = 1, collideIndex:Int = 1):Void {
		super.loadMapHelper(tileGraphic, tileWidth, tileHeight, autoTile, startingIndex, drawIndex, collideIndex);
		fitCameraToMap();
	}
	
	
}