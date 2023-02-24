package;

import flixel.input.gamepad.FlxGamepad;
import openfl.Lib;
#if FEATURE_LUAMODCHART
import llua.Lua;
#end
import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PauseSubState extends MusicBeatSubstate
{
	public static var grpMenuShit:FlxTypedGroup<Alphabet>;

	public static var goToOptions:Bool = false;
	public static var goBack:Bool = false;

	public var tweenManager:FlxTweenManager;

	var curSelected:Int = 0;

	public static var playingPause:Bool = false;

	var pauseMusic:FlxSound;

	var perSongOffset:FlxText;

	var bg:FlxSprite;

	var levelDifficulty:FlxText;

	var levelInfo:FlxText;

	var textArray:Array<String> = [
		"Yeah I use Kade Engine *insert gay fat guy dancing* (-Bolo)",
		"Kade engine *insert burning PC gif* (-Bolo)",
		"This is my kingdom cum (-Bolo)",
		"192.0.0.1 (-Kori)",
		"Dead engine? (-Bolo)",
		"Amber best Pyro bow user fuck you! (-Bolo)",
		"I love watching Yosuga No Sora with my sister. (-Bolo)", // Wtf 💀
		"God i love futabu!! so fucking much (-McChomk)", // God died in vain 💀
		"Lag issues? Don't worry we are currently mining cryptocurrencies with ur pc :D (-Bolo)",
		"Are you really reading this thing? (-Bolo)",
		"I fced Sex mod with only one hand! (-Bolo)",
		"Don't take these dialogues seriously lol (-Bolo)",
		"0.01% batch (-PopCat)",
		"Are you have the stupid? (-BombasticTom)",
		"I am here (-Faid)",
		"I love men (-HomoKori)",
		"Why do I have a pic of Mario with massive tits on my phone? (-Rudy)",
		"I mom (-NxtVithor)",
		"We are gonna be using your fork as a base for myth engine (-Awoo)",
		"Cool ass looking shit. (-BeastlyGhost)",
		"Camellia's 2.5 fork poggers. (-Bolo)",
		"Myth Engine Peak (-Bolo)",
		"MYCOCK (-Zeurunix)",
		"Shawty trifling, she must be from dirty docks! (-Jaldabo)",
		"oh we're even quoted oh boy (-Tomato Sauce)",
		"TinyBreasts (-TeneBrysté)",
		"100HEX (-Garacide)",
		"fire emoji 🔥 (-Faid)",
		"bolo dot com (-Tomato Sauce)",
		"wishlist average4k on steam (-Tomato Sauce)",
		"hi mom im in a fnf mod (-Tomato Sauce)",
		"subscribe to aleonepic (-Aleon)",
		"who made this cover it sounds like ass (-Tomato Sauce)",
		"Search Infinity Stones in discord gif tab (-Bolo)",
		"download phigros on the google play and appstore (-Tomato Sauce)"
	];

	public function new()
	{
		super();
		grpMenuShit = new FlxTypedGroup<Alphabet>();
		tweenManager = new FlxTweenManager();
		openCallback = refresh;
	}

	override public function create()
	{
		/*if (FlxG.sound.music.playing)
			FlxG.sound.music.pause(); */
		/*for (i in FlxG.sound.list)
			{
				if (i.playing && i.ID != 9000)
					i.pause();
		}*/

		playingPause = true;

		#if cpp
		add(PlayState.pauseStream);
		PlayState.pauseStream.volume = 0;
		PlayState.pauseStream.play();
		#else
		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		#end

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		levelInfo = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.songName.toUpperCase();
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		levelDifficulty = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyFromInt(PlayState.storyDifficulty).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		add(grpMenuShit);
		perSongOffset = new FlxText(0, FlxG.height - 18, FlxG.width, textArray[FlxG.random.int(0, textArray.length - 1)], 12);
		perSongOffset.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		perSongOffset.scrollFactor.set();

		#if FEATURE_FILESYSTEM
		add(perSongOffset);
		#end

		for (i in 0...CoolUtil.pauseMenuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, CoolUtil.pauseMenuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			if (!grpMenuShit.members.contains(songText))
				grpMenuShit.add(songText);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		super.create();
	}

	override function update(elapsed:Float)
	{
		tweenManager.update(elapsed);
		#if !cpp
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;
		#end

		#if cpp
		if (PlayState.pauseStream.volume < 0.5)
			PlayState.pauseStream.volume += 0.01 * elapsed;
		#end

		#if desktop
		if (PlayState.pauseStream.time == 0)
		{
			if (!PlayState.pauseStream.playing)
				PlayState.pauseStream.play();
		}
		#end

		super.update(elapsed);

		#if !mobile
		if (FlxG.mouse.wheel != 0)
			#if desktop
			changeSelection(-FlxG.mouse.wheel);
			#else
			if (FlxG.mouse.wheel < 0)
				changeSelection(1);
			if (FlxG.mouse.wheel > 0)
				changeSelection(-1);
			#end
		#end

		/*for (i in FlxG.sound.list)
			{
				if (i.playing && i.ID != 9000)
					i.pause();
		}*/

		if (bg.alpha > 0.6)
			bg.alpha = 0.6;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var upPcontroller:Bool = false;
		var downPcontroller:Bool = false;
		var leftPcontroller:Bool = false;
		var rightPcontroller:Bool = false;
		var oldOffset:Float = 0;

		if (gamepad != null && KeyBinds.gamepad)
		{
			upPcontroller = gamepad.justPressed.DPAD_UP;
			downPcontroller = gamepad.justPressed.DPAD_DOWN;
			leftPcontroller = gamepad.justPressed.DPAD_LEFT;
			rightPcontroller = gamepad.justPressed.DPAD_RIGHT;
		}

		if (controls.UP_P || upPcontroller)
		{
			changeSelection(-1);
		}
		else if (controls.DOWN_P || downPcontroller)
		{
			changeSelection(1);
		}

		if ((controls.ACCEPT && !FlxG.keys.pressed.ALT) || FlxG.mouse.pressed)
		{
			var daSelected:String = CoolUtil.pauseMenuItems[curSelected];
			#if desktop
			PlayState.pauseStream.stop();
			#end
			switch (daSelected)
			{
				case "Resume":
					close();
					PlayState.instance.scrollSpeed = (FlxG.save.data.scrollSpeed == 1 ? PlayState.SONG.speed * PlayState.songMultiplier : FlxG.save.data.scrollSpeed * PlayState.songMultiplier);
				case "Restart Song":
					PlayState.startTime = 0;
					MusicBeatState.resetState();
				case "Options":
					goToOptions = true;
					close();
				case "Exit to menu":
					PlayState.startTime = 0;

					/*if (FlxG.save.data.fpsCap > 300)
						(cast(Lib.current.getChildAt(0), Main)).setFPSCap(300); */

					if (PlayState.isStoryMode)
					{
						// GameplayCustomizeState.freeplayNoteStyle = 'normal';
						MusicBeatState.switchState(new StoryMenuState());
					}
					else
					{
						MusicBeatState.switchState(new FreeplayState());
					}

					#if !cpp
					pauseMusic.pause();
					#end
			}
		}

		if (FlxG.keys.justPressed.J)
		{
			// for reference later!
			// PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, FlxKey.J, null);
		}
	}

	override function destroy()
	{
		super.destroy();
	}

	override function close()
	{
		tweenManager.clear();
		#if cpp
		PlayState.pauseStream.pause();

		remove(PlayState.pauseStream);
		#else
		pauseMusic.pause();
		#end
		super.close();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = CoolUtil.pauseMenuItems.length - 1;
		if (curSelected >= CoolUtil.pauseMenuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	private function refresh()
	{
		for (i in 0...grpMenuShit.length - 1)
		{
			grpMenuShit.members[i].y = (70 * i) + 30;
		}

		#if cpp
		add(PlayState.pauseStream);
		PlayState.pauseStream.volume = 0;
		PlayState.pauseStream.play();
		#else
		pauseMusic.volume = 0;
		pauseMusic.play();
		#end

		levelInfo.y = 15;
		levelDifficulty.y = 15 + 32;

		bg.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		perSongOffset.text = textArray[FlxG.random.int(0, textArray.length - 1)];

		tweenManager.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		tweenManager.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		tweenManager.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		changeSelection();
	}
}
