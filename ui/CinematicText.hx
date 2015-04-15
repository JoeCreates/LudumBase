package ui ;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRandom;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class CinematicText extends FlxSpriteGroup {
	
	public var letters:Array<CinematicLetter>;
	public var fullText:FlxText;
	public var minYMotion:Float = 10;
	public var maxYMotion:Float = 20;
	public var autoHide:Bool;
	public var finished = false;
	
	public function new(x:Float, y:Float, text:String, size:Int = 24, spacing:Float = 0,
		font:String = "fairfax", autoHide:Bool = false) {
		super();
		letters = new Array<CinematicLetter>();
		this.autoHide = autoHide;
		
		// Populate full text slowly to get position of each character
		fullText = new FlxText(0, 0, 0, "", size);
		fullText.font = font;
		var cumulativeWidth:Float = 0;
		
		for (i in 0...text.length) {
			fullText.text += text.charAt(i);
			fullText.calcFrame();
			fullText.updateHitbox();
			var letter:CinematicLetter = new CinematicLetter(text.charAt(i), size, font);
			letter.setPosition(x + cumulativeWidth + i * spacing, y);
			cumulativeWidth = fullText.width;
			letters.push(letter);
			letter.alpha = 0;
			add(letter);
		}
	}
	
	public function show():Void {
		for (letter in letters) {
			showLetter(letter);
		}
	}
	
	public function hide():Void {
		for (letter in letters) {
			hideLetter(letter);
		}
	}
	
	
	public function showLetter(letter:CinematicLetter):Void {
		var r:FlxRandom = FlxG.random;
		var targetY:Float = letter.y;
		letter.y += r.float(minYMotion, maxYMotion);
		FlxTween.tween(letter, { alpha: 1, y: targetY },
			r.float(1, 2), { startDelay: r.float(0, 1), ease: FlxEase.quadOut, onComplete: function(tween:FlxTween) {
				if (autoHide) hideLetter(letter);
			} });
	}
	
	public function hideLetter(letter:CinematicLetter):Void {
		var r:FlxRandom = FlxG.random;
		var targetY:Float = letter.y - r.float(minYMotion, maxYMotion);
		FlxTween.tween(letter, { alpha: 0, y: targetY },
			r.float(1, 2), { startDelay: r.float(0, 1), ease: FlxEase.quadIn } );
		new FlxTimer(4, function(timer:FlxTimer) {
			finished = true;
		});
	}
}

class CinematicLetter extends FlxText {
	public function new(char:String, size:Int = 24, font:String = "fairfax") {
		super(0, 0, 0, char, size);
		this.font = font;
	}
}