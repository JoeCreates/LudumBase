package;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import world.World;

/**
 * Extends basic FlxState with additional functionality
 * 
 * @author Joe Williamson
 */
class GameState extends FlxState {
	
	public var world:World;
	public var uiGroup:FlxGroup;
	
	public var uiCamera:FlxCamera;
	public var worldCamera:FlxCamera;
	
	public var worldZoom(default, set):Float;
	public var baseZoom:Float;
	
	public var zoomTween:FlxTween;
	
	public function new() {
		super();
		
		// Cameras
		worldCamera = FlxG.camera;
		uiCamera = new FlxCamera();
		uiCamera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(uiCamera);
		FlxCamera.defaultCameras = [worldCamera];
		
		baseZoom = worldCamera.zoom;
		worldZoom = 1;
		
		// Groups
		uiGroup = new FlxGroup();
		uiGroup.cameras = [uiCamera];
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