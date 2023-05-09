import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import MusicBeatState.subStates;

class OptionsDirect extends MusicBeatState
{
	var menuBG:FlxSprite;

	public static var instance:OptionsDirect = null;

	var colorArray:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 255),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(255, 255, 0),
		FlxColor.fromRGB(255, 127, 0),
		FlxColor.fromRGB(255, 0, 0)
	];

	override function create()
	{
		instance = this;
		FlxG.camera.fade(FlxColor.BLACK, 0.8, true);
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		subStates.push(new OptionsMenu());
		menuBG = new FlxSprite().loadGraphic(Paths.image("menuDesat"));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = FlxG.save.data.antialiasing;
		add(menuBG);

		tweenColorShit();

		super.create();

		openSubState(subStates[0]);
	}

	function tweenColorShit()
	{
		var beforeInt = FlxG.random.int(0, 6);
		var randomInt = FlxG.random.int(0, 6);

		FlxTween.color(menuBG, 4, menuBG.color, colorArray[beforeInt], {
			onComplete: function(twn)
			{
				if (beforeInt != randomInt)
					beforeInt = randomInt;

				tweenColorShit();
			}
		});
	}
}
