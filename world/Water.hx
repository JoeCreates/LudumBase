package world;

import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.filters.DisplacementMapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import org.flixel.*;

public class Water {
	private var rect:Rectangle = new Rectangle(0, 0, 480, 160);
	private var point:Point = new Point(0, 160);
	private var zeroPoint:Point = new Point(0, 0);
	private var matrix:Matrix = new Matrix();
	private var transform:ColorTransform = new ColorTransform(1, 1, 1, 0.3);
	private var displacementFilter:DisplacementMapFilter;
	private var displacementBitmap:BitmapData = new BitmapData(480, 100, false, 0);
	private var displacementIteration:int = 0;
	private var timer:Number = 0;
	
	public function Water() {
		// This flips the screen for the water reflection
		matrix.scale(1, -1);
		matrix.translate(0, 160);
		// This is the filter that makes the reflection ripple
		displacementFilter = new DisplacementMapFilter(displacementBitmap, zeroPoint, 1, 2, 10, 1);
		displacementBitmap.perlinNoise(20, 3, 1, 0, true, true, 7, true, [1, 1]);
	}
	
	public function update():Void {
		timer += FlxG.elapsed;
		if (timer > 0.3) { // Update the water ripple
			displacementIteration++;
			displacementBitmap.perlinNoise(20, 3, 1, displacementIteration, true, true, 7, true, [1, 1]);
			timer = 0;
		}
	}
	
	public function render():Void {
		Assets.reflection.fillRect(rect, 0xff004cd6); // Clear the reflection
		Assets.reflection.draw(FlxG.buffer, matrix, transform); // Flip the screen and copy it to the reflection
		Assets.reflection.applyFilter(Assets.reflection, rect, zeroPoint, displacementFilter); // Apply the ripple filter
		FlxG.buffer.copyPixels(Assets.reflection, rect, point, null, null, true); // Copy it onto screen
	}
}