package;

import CoolUtil.CoolText;
import flixel.FlxCamera;
import openfl.filters.ShaderFilter;
import openfl.Assets;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

#if FEATURE_DISCORD
import Discord.DiscordClient;
#end

class CreditsState extends MusicBeatState
{
	var credits:Array<CreditsMetadata> = [];

	var descText:CoolText;

	public static var curSelected:Int = 1;

	private var grpCredits:FlxTypedGroup<Alphabet>;

	public static var instance:CreditsState = null;

	var camGame:FlxCamera;

	var camCredits:FlxCamera;

	var camOther:FlxCamera;

	var intendedColor:Int;
	var colorTween:FlxTween;
	var bg:FlxSprite;

	var width:Float = 0;

	override function create()
	{
		instance = this;
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		populateCreditsData();

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Credits Menu", null);
		#end

		persistentUpdate = true;

		camGame = new FlxCamera();
		camGame.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);

		camCredits = new FlxCamera();
		camCredits.bgColor.alpha = 0;
		camCredits.copyFrom(camGame);

		FlxG.cameras.add(camCredits, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camOther, false);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		var blackBG = new FlxSprite();
		blackBG.alpha = 0.5;
		add(blackBG);

		grpCredits = new FlxTypedGroup<Alphabet>();
		add(grpCredits);

		for (i in 0...credits.length)
		{
			if (credits[i].category == "1")
			{
				var creditText:Alphabet = new Alphabet(0, 70 * i, credits[i].name, true, false, 1, 1);
				creditText.isMenuItem = true;
				creditText.changeX = false;
				creditText.targetY = i;
				creditText.ID = i;

				creditText.screenCenter(X);
				// creditText.yAdd -= 70;

				if (creditText.width > width)
					width = creditText.width;

				grpCredits.add(creditText);
			}
			else
			{
				var creditText:Alphabet = new Alphabet(0, 70 * i, credits[i].name, false, false, 1, 1);
				creditText.camera = camCredits;

				creditText.forEach(function(char:FlxSprite)
				{
					char.antialiasing = FlxG.save.data.antialiasing;
				});

				creditText.isMenuItem = true;
				creditText.changeX = false;
				creditText.targetY = i;

				creditText.ID = i;

				creditText.screenCenter(X);
				creditText.yAdd -= 70;

				if (creditText.width > width)
					width = creditText.width;

				grpCredits.add(creditText);
			}
		}

		blackBG.makeGraphic(Std.int(width + 35), FlxG.height, FlxColor.BLACK);
		blackBG.updateHitbox();
		blackBG.screenCenter(X);

		descText = new CoolText(50, 410, 32, 32, Paths.bitmapFont('fonts/vcr'));
		descText.autoSize = true;
		descText.antialiasing = FlxG.save.data.antialiasing;
		descText.updateHitbox();
		descText.screenCenter(X);
		add(descText);

		changeSelection();

		super.create();

		bg.color = FlxColor.fromString(credits[curSelected].color);
		intendedColor = bg.color;
	}

	/**
	 * Load song data from the data files.
	 */
	static function populateCreditsData()
	{
		var creditsList = CoolUtil.coolTextFile(Paths.txt('data/creditsList'));

		for (i in 0...creditsList.length)
		{
			var data:Array<String> = creditsList[i].split(':');
			var name = data[0];
			var link = data[1];
			var desc = data[2];
			var category = data[3];
			var color = data[4];

			var meta = new CreditsMetadata(name, link, desc, category, color);

			instance.credits.push(meta);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music.volume > 0.8)
		{
			FlxG.sound.music.volume -= 0.5 * FlxG.elapsed;
		}

		var upP = FlxG.keys.justPressed.UP;
		var downP = FlxG.keys.justPressed.DOWN;
		var accepted = FlxG.keys.justPressed.ENTER;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.DPAD_UP)
			{
				changeSelection(-1);
			}
			if (gamepad.justPressed.DPAD_DOWN)
			{
				changeSelection(1);
			}
		}

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.BACK)
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (accepted)
			fancyOpenURL(credits[curSelected].link);

		if (FlxG.mouse.wheel != 0)
		{
			changeSelection(-FlxG.mouse.wheel);
		}

		grpCredits.forEach(function(spr:Alphabet)
		{
			if (FlxG.mouse.overlaps(spr))
			{
				if (FlxG.mouse.justPressed)
				{
					if (curSelected != Std.int(spr.ID))
					{
						curSelected = Std.int(spr.ID);
						changeSelection();
					}
					else if (credits[curSelected].category != "1")
						fancyOpenURL(credits[curSelected].link);
				}
			}
		});
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (credits[curSelected] != null && credits[curSelected].category == "1")
		{
			curSelected += change;
		}

		if (curSelected < 1)
			curSelected = 1;
		if (curSelected >= credits.length)
			curSelected = credits.length - 1;

		var bullShit:Int = 0;

		for (item in grpCredits.members)
		{
			item.screenCenter(X);
			item.targetY = bullShit - curSelected;
			bullShit++;
		}

		descText.text = credits[curSelected].desc;
		descText.updateHitbox();
		descText.screenCenter(X);

		var newColor:Int = FlxColor.fromString(credits[curSelected].color);
		if (newColor != intendedColor)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 0.5, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
				}
			});
		}
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}

class CreditsMetadata
{
	public var name:String = "";
	public var link:String = "";
	public var desc:String = "";
	public var category:String = "0";

	public var color:String = "#4e7093";

	public function new(name:String, link:String, desc:String, ?category:String = "0", ?color:String = "#4e7093")
	{
		this.name = name;
		this.link = link;
		this.desc = desc;
		this.category = category;
		this.color = color;
	}
}
