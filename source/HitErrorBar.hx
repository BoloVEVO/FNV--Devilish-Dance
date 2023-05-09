package;

import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import flixel.util.FlxTimer;

using StringTools;

/**
 *
 * HitErrorBar like OSU!! 
 * @author BoloVEVO
 *
**/
class HitErrorBar extends FlxSpriteGroup
{
	var trianglePointer:FlxSprite;

	var timingBar:FlxSprite;

	var widthArray:Array<Float> = [];

	var currentMS:Float = 0;

	var lastMS:Float = 0;

	var middleLine:FlxSprite;

	public var hitNotesGroup:FlxTypedGroup<NoteHitBar>;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		this.x = x;
		this.y = y;
		this.alpha = 0.4;

		var reverseWins = Ratings.timingWindows.copy();
		reverseWins.reverse();

		for (i in 0...Ratings.timingWindows.length * 2)
		{
			var id = i;
			if (id >= Ratings.timingWindows.length)
				id -= Ratings.timingWindows.length;

			widthArray[i] = i < Ratings.timingWindows.length ? Ratings.timingWindows[id].timingWindow
				- (Ratings.timingWindows[id + 1] != null ? Ratings.timingWindows[id + 1].timingWindow : 0) : reverseWins[id].timingWindow
				- (reverseWins[id - 1] != null ? reverseWins[id - 1].timingWindow : 0);
		}

		var totalWidth = 0.0;
		for (i in widthArray)
			totalWidth += i;

		var judgeLine:BitmapData = new BitmapData(Std.int(totalWidth), 5, true);

		var daOffset = 0.0;

		for (i in 0...Ratings.timingWindows.length * 2)
		{
			var id = i;
			if (id >= Ratings.timingWindows.length)
				id -= Ratings.timingWindows.length;

			var shitWidth = widthArray[i];
			judgeLine.fillRect(new openfl.geom.Rectangle(daOffset, 0, shitWidth, 5),
				i < Ratings.timingWindows.length ? Ratings.timingWindows[id].displayColor : reverseWins[id].displayColor);
			daOffset += widthArray[i];
		}

		timingBar = new FlxSprite().loadGraphic(judgeLine);

		timingBar.setGraphicSize(300, 5); // Set to a determined scale to don't have a large timing bar because of really high timings.

		timingBar.updateHitbox();

		trianglePointer = new FlxSprite((timingBar.x + timingBar.width / 2) - 5, 0).makeGraphic(10, 10, FlxColor.TRANSPARENT);

		FlxSpriteUtil.drawTriangle(trianglePointer, 0, 0, 10, FlxColor.WHITE, {thickness: 0, color: FlxColor.WHITE}, {smoothing: true});

		trianglePointer.scale.set(1, 0.65);
		trianglePointer.updateHitbox();

		trianglePointer.antialiasing = FlxG.save.data.antialiasing;

		middleLine = new FlxSprite((timingBar.x + timingBar.width / 2) - 1.5, -10.5).makeGraphic(3, 25, FlxColor.WHITE);

		if (FlxG.save.data.downscroll)
		{
			trianglePointer.flipY = true;
			trianglePointer.y = -12;
		}
		else
			trianglePointer.y = 12.5;

		add(timingBar);

		if (PlayState.inDaPlay)
		{
			hitNotesGroup = new FlxTypedGroup<NoteHitBar>();

			var dummyBar = new NoteHitBar((timingBar.x + timingBar.width / 2) - 1.5, -10.5);
			dummyBar.makeGraphic(3, 18, FlxColor.WHITE);
			dummyBar.alpha = 0;
			hitNotesGroup.add(dummyBar);
		}

		add(middleLine);
		add(trianglePointer);

		timer = new FlxTimer(PlayState.instance.timerManager);
	}

	override function update(elapsed:Float)
	{
		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 2.5), 0, 1);

		var toGo = FlxMath.remapToRange((timingBar.x + timingBar.width / 2)
			+ currentMS, (timingBar.x + timingBar.width / 2),
			(timingBar.x + timingBar.width / 2)
			+ Ratings.timingWindows[0].timingWindow, (timingBar.x + timingBar.width / 2), timingBar.x
			+ timingBar.width)
			- 5;

		trianglePointer.x = FlxMath.lerp(toGo, trianglePointer.x, lerpVal);

		if (PlayState.inDaPlay)
		{
			hitNotesGroup.camera = this.camera;
			hitNotesGroup.forEachAlive(function(hitNote:NoteHitBar)
			{
				hitNote.existTime += 10;
				if (hitNote.existTime > 1000)
					hitNote.alpha -= 0.1 * elapsed;
			});
		}

		super.update(elapsed);
	}

	var timer:FlxTimer;

	public function registerHit(noteMS:Float)
	{
		lastMS = currentMS;
		currentMS = noteMS;

		this.alpha = 0.7;
		PlayState.instance.tweenManager.cancelTweensOf(this);
		this.alpha = 0.7;

		var toGo = FlxMath.remapToRange((timingBar.x + timingBar.width / 2)
			+ currentMS, (timingBar.x + timingBar.width / 2),
			(timingBar.x + timingBar.width / 2)
			+ Ratings.timingWindows[0].timingWindow, (timingBar.x + timingBar.width / 2), timingBar.x
			+ timingBar.width)
			- 1.5;

		if (PlayState.inDaPlay)
		{
			if (!PlayState.instance.members.contains(hitNotesGroup))
				PlayState.instance.add(hitNotesGroup);

			var newBar = hitNotesGroup.recycle(NoteHitBar);
			newBar.loadGraphic(hitNotesGroup.members[0].graphic);
			newBar.alpha = 0.7;
			newBar.setPosition(toGo, y - 7);

			hitNotesGroup.add(newBar);
		}

		if (timer != null)
			timer.cancel();

		timer.start(3, function(tmr)
		{
			PlayState.instance.tweenManager.tween(this, {alpha: 0.4}, 1.5);
		});
	}

	override function destroy()
	{
		timingBar.destroy();
		trianglePointer.destroy();
		timer.destroy();

		super.destroy();
	}
}

class NoteHitBar extends FlxSprite
{
	public var existTime:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (alpha == 0)
			kill();
	}
}
