package;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.filters.BlurFilter;
import world.World;

/**
 * Extends basic FlxState with additional functionality
 * 
 * @author Joe Williamson
 */
class GameState extends FlxState {
	
	public var world:World;
	public var uiGroup:FlxSpriteGroup;
	
	public var uiCamera:FlxCamera;
	public var worldCamera:FlxCamera;
	
	public var worldZoom(default, set):Float;
	public var baseZoom:Float;
	
	public var zoomTween:FlxTween;
	
	override public function create():Void {
		super.create();
		
		// Cameras
		worldCamera = FlxG.camera;
		uiCamera = new FlxCamera(Std.int(FlxG.camera.x), Std.int(FlxG.camera.y), 
		                         FlxG.camera.width, FlxG.camera.height, FlxG.camera.zoom);
		uiCamera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(uiCamera);
		FlxCamera.defaultCameras = [worldCamera];
		
		baseZoom = worldCamera.zoom;
		worldZoom = 1;
		
		// Groups
		uiGroup = new FlxSpriteGroup();
		uiGroup.cameras = [uiCamera];
		
		add(uiGroup);
		
		var blur:BlurFilter = new BlurFilter();
		worldCamera.flashSprite.filters.push(blur);
		worldCamera.flashSprite.filters = worldCamera.flashSprite.filters;
	}
	
	public function zoomTo(zoom:Float, duration:Float = 1, ?ease:Float->Float):FlxTween {
		if (ease == null) ease = FlxEase.quadInOut;
		
		if (zoomTween != null) {
			zoomTween.cancel();
		}
		zoomTween = FlxTween.tween(this, { worldZoom: zoom }, duration, { type: FlxTween.ONESHOT, ease: ease } ); 
		return zoomTween;
	}
	
	private function set_worldZoom(worldZoom:Float):Float {
		// Set world and camera zoom
		worldCamera.zoom = baseZoom * worldZoom;
		return this.worldZoom = worldZoom;
	}
	
	//TODO autotweening
	//TODO camera targetting
	//TODO sound fading
}