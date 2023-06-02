package;

import CoolUtil.CoolText;
import flixel.FlxSubState;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import PlayState;
import Options;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;

using StringTools;

class OptionCata extends FlxSprite
{
	public var title:String;

	public var options:Array<Option>;

	public var optionObjects:FlxTypedGroup<OptionText>;

	public var graphics:Array<FlxSprite> = [];

	public var titleObject:FlxText;

	public var middle:Bool = false;

	public var text:OptionText;

	public var fixedY:Bool = false;

	public function new(x:Float, y:Float, _title:String, _options:Array<Option>, middleType:Bool = false)
	{
		super(x, y);
		title = _title;
		middle = middleType;

		graphics = [];

		var blackGraphic = new FlxSprite().makeGraphic(295, 64, FlxColor.BLACK);
		var cumGraphic = new FlxSprite().makeGraphic(295, 64, FlxColor.WHITE);

		graphics.push(blackGraphic);
		graphics.push(cumGraphic);

		if (!middleType)
			loadGraphic(graphics[0].graphic);
		alpha = 0.4;

		options = _options;

		optionObjects = new FlxTypedGroup();

		titleObject = new FlxText((middleType ? 1180 / 2 : x), y + (middleType ? 0 : 16), 0, title);
		titleObject.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleObject.borderSize = 3;

		if (middleType)
		{
			titleObject.x = 50 + ((1180 / 2) - (titleObject.fieldWidth / 2));
		}
		else
			titleObject.x += (width / 2) - (titleObject.fieldWidth / 2);

		titleObject.scrollFactor.set();

		scrollFactor.set();

		for (i in 0...options.length)
		{
			var opt = options[i];
			text = new OptionText(middleType ? 0 : 75, (46 * i) + 175, 35, 35, Paths.bitmapFont('fonts/vcr'));
			text.autoSize = true;
			text.borderStyle = FlxTextBorderStyle.OUTLINE;
			text.borderSize = 2;
			text.antialiasing = FlxG.save.data.antialiasing;
			text.targetY = i;
			text.alpha = 0.4;
			text.ID = i;

			text.text = opt.getValue();

			if (middleType)
				text.alignment = FlxTextAlign.RIGHT;

			text.updateHitbox();

			text.scrollFactor.set();

			optionObjects.add(text);
		}
	}

	public function changeColor(color:FlxColor)
	{
		if (color == FlxColor.BLACK)
			loadGraphic(graphics[0].graphic);
		else if (color == FlxColor.WHITE)
			loadGraphic(graphics[1].graphic);
	}

	override function destroy()
	{
		for (graphic in graphics)
			graphic.destroy();
		graphics.resize(0);
		for (shit in optionObjects)
		{
			shit.destroy();
		}

		optionObjects.clear();

		options.resize(0);

		super.destroy();
	}
}

class OptionText extends CoolText
{
	public var targetY:Float = 0;

	public var rawY:Float = 0;

	public var lerpFinished:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var optLerp = CoolUtil.boundTo(elapsed * 15, 0, 1);

		rawY = (targetY * 45.75) + 405;
		y = FlxMath.lerp(y, rawY, optLerp);

		lerpFinished = y == rawY;
	}
}

class OptionsMenu extends MusicBeatSubstate
{
	public static var instance:OptionsMenu = null;

	public var background:FlxSprite;

	public var selectedCat:OptionCata;

	public var selectedOption:Option;

	public var selectedCatIndex = 0;

	public var selectedOptionIndex = 0;

	public static var mustScroll:Bool = false;

	public var isInCat:Bool = false;

	public var options:Array<OptionCata>;

	public static var isInPause = false;

	public var shownStuff:FlxTypedGroup<OptionText>;

	public static var visibleRange = [164, 640];

	var changedOption = false;

	var holdTime:Float = 0;

	public function new(pauseMenu:Bool = false)
	{
		super();

		isInPause = pauseMenu;

		options = [
			new OptionCata(50, 40, "Gameplay", [
				new ScrollSpeedOption("Change your scroll speed. (1 = Chart dependent)"),
				new OffsetThing("Change the note visual offset (how many milliseconds a note looks like it is offset in a chart)"),
				new AccuracyDOption("Change how accuracy is calculated. (Accurate = Simple, Complex = Milisecond Based)"),
				new ScoreDOption("Change how score is calculated. (Simple = Normal, Complex = Note Rating Amount Based"),
				new HitSoundOption("Toogle hitsound every time you hit a Strum Note."),
				new HitSoundVolume("Set hitsound volume."),
				new HitSoundMode("Set at what condition you want the hitsound to play."),
				new GhostTapOption("Toggle counting pressing a directional input when no arrow is there as a miss."),
				new DownscrollOption("Toggle making the notes scroll down rather than up."),
				new BotPlay("A bot plays for you!"),
				new ResetButtonOption("Toggle pressing R to gameover. (Use it with caution!)"),
				new InstantRespawn("Toggle if you instantly respawn after dying."),
				new NoteCamera("Toggle Camera movement to the note direction the character sings"),
				new CamZoomOption("Toggle the camera zoom in-game."),
				// new OffsetMenu("Get a note offset based off of your inputs!"),
				new DFJKOption(),
				new Judgement("Create a custom judgement preset"),
				new CustomizeGameplay("Drag and drop gameplay modules to your prefered positions!")
			]),
			new OptionCata(345, 40, "Appearance", [
				new NoteskinOption("Change your current noteskin"),
				new ScoreSmoothing("Toggle smoother poping score for Score Text (High CPU usage)."),
				new MiddleScrollOption("Put your lane in the center or on the right."),
				new HealthBarOption("Toggles health bar visibility"),
				new JudgementCounter("Show your judgements that you've gotten in the song"),
				new LaneUnderlayOption("How transparent your lane is, higher = more visible."),
				new ScrollAlpha("Changes the Transparancy of the Hold Notes."),
				new HitErrorBarOption("Toggle Hit Error Bar to see how late/early are your hits."),
				new StepManiaOption("Sets the colors of the arrows depending on quantization instead of direction."),
				new AccuracyOption("Display accuracy information on the info bar."),
				new RoundAccuracy("Round your accuracy to the nearest whole number for the score text (cosmetic only)."),
				new SongPositionOption("Show the song's current position as a scrolling bar."),
				new Colour("The color behind icons now fit with their theme. (e.g. Pico = green)"),
				new NPSDisplayOption("Shows your current Notes Per Second on the info bar."),
				new RainbowFPSOption("Make the FPS Counter flicker through rainbow colors."),
				new CpuStrums("Toggle the CPU's strumline lighting up when it hits a note."),
				new NoteCocks("Toggle The Note Splashes every time you get a SICK!")
			]),
			new OptionCata(640, 40, "Misc", [
				new FPSOption("Toggle the FPS Counter"),
				new FPSCapOption("Change your FPS Cap."),
				new DisplayMemory("Toggle the Memory Usage"),
				#if FEATURE_DISCORD
				new DiscordOption("Change your Discord Rich Presence update interval."),
				#end
				new FlashingLightsOption("Toggle flashing lights that can cause epileptic seizures and strain."),
				new WatermarkOption("Enable and disable all watermarks from the engine."),
				new MissSoundsOption("Toggle miss sounds playing when you don't hit a note."),
				new ScoreScreen("Show the score screen after the end of a song"),
				new ShowInput("Display every single input on the score screen."),
			]),
			new OptionCata(935, 40, "Performance", [

				new Background("Toogle Stage Background depending of your computer performance."),
				new CharacterOption("Toogle Characters on Stage depending of your computer performance."),
				new DistractionsAndEffectsOption("Toggle stage distractions that can hinder your gameplay and save memory."),
				new GPURendering("Toggle GPU rendering to push Graphics textures to GPU, reducing RAM memory usage. "),
				new AntialiasingOption("Toggle antialiasing, improving graphics quality at a slight performance penalty."),
				// new NotePostProcessing("Toggle Note Post processing to load notes while song elapses. (Useful for low-end computers)")
			]),
			new OptionCata(50, 104, "Saves", [

				new AutoSaveChart("Toggle if in 5mins within chart it autosaves."),
				new ResetModifiersOption("Reset your Gameplay modifiers. This is irreversible!"),
				new ResetScoreOption("Reset your score on all songs and weeks. This is irreversible!"),
				new LockWeeksOption("Reset your story mode progress. This is irreversible!"),
				new ResetSettings("Reset ALL your settings. This is irreversible!"),
				new ClearLogFolder("Deletes all the log files from the log folder of your game directory."),
				new ClearCrashDumpFolder("Deletes all the crash dump files from the crash folder of your game directory.")
			]),
			new OptionCata(-1, 125, "Editing Keybinds", [
				new LeftKeybind("The left note's keybind"),
				new DownKeybind("The down note's keybind"),
				new UpKeybind("The up note's keybind"),
				new RightKeybind("The right note's keybind"),
				new PauseKeybind("The keybind used to pause the game"),
				new ResetBind("The keybind used to die instantly"),
				new MuteBind("The keybind used to mute game audio"),
				new VolUpBind("The keybind used to turn the volume up"),
				new VolDownBind("The keybind used to turn the volume down"),
				new FullscreenBind("The keybind used to fullscreen the game")
			], true),
			new OptionCata(-1, 125, "Editing Judgements", [

				new SickMSOption("How many milliseconds are in the SICK hit window"),
				new GoodMsOption("How many milliseconds are in the GOOD hit window"),
				new BadMsOption("How many milliseconds are in the BAD hit window"),
				new ShitMsOption("How many milliseconds are in the SHIT hit window")
			], true)
		];

		menu = new FlxTypedGroup<FlxSprite>();

		shownStuff = new FlxTypedGroup<OptionText>();

		background = new FlxSprite(50, 40).makeGraphic(1180, 640, FlxColor.BLACK);
		background.alpha = 0.5;
		background.scrollFactor.set();

		descBack = new FlxSprite(50, 642).makeGraphic(1180, 38, FlxColor.BLACK);
		descBack.alpha = 0.3;
		descBack.scrollFactor.set();

		if (isInPause)
		{
			var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0;
			bg.scrollFactor.set();
			menu.add(bg);

			descBack.alpha = 0.3;
			background.alpha = 0.5;
			bg.alpha = 0.6;

			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		}

		descText = new CoolText(65, 648, 20, 20, Paths.bitmapFont('fonts/vcr'));
		descText.autoSize = false;
		descText.fieldWidth = 1750;
		descText.antialiasing = FlxG.save.data.antialiasing;
		descText.borderStyle = FlxTextBorderStyle.OUTLINE;
		descText.borderSize = 2;

		openCallback = refresh;
	}

	public var menu:FlxTypedGroup<FlxSprite>;

	public var descText:CoolText;
	public var descBack:FlxSprite;

	override function create()
	{
		instance = this;

		menu.add(background);

		menu.add(descBack);

		selectedCat = options[0];

		add(menu);

		add(shownStuff);

		add(descBack);
		add(descText);

		isInCat = true;

		for (i in 0...options.length - 1)
		{
			if (i > 4)
				continue;
			var cat = options[i];
			add(cat);
			add(cat.titleObject);
		}

		switchCat(selectedCat);

		super.create();
	}

	function refresh()
	{
		#if cpp
		if (isInPause)
		{
			add(PlayState.pauseStream);
			PlayState.pauseStream.play();
		}
		#end
		switchCat(selectedCat);
	}

	var saveIndex:Int = 0;

	var saveOptIndex:Int = 0;

	public function switchCat(cat:OptionCata, toSubCat:Bool = false, fromSubCat:Bool = false)
	{
		if (toSubCat)
		{
			saveIndex = options.indexOf(selectedCat);
			saveOptIndex = selectedOptionIndex;
			isInCat = false;
		}
		else if (!fromSubCat)
		{
			saveIndex = 0;
			saveOptIndex = 0;
			selectedOptionIndex = 0;
		}

		visibleRange = [164, 640];
		/*if (cat.middle)
			visibleRange = [Std.int(cat.titleObject.y), 640]; */

		if (selectedCatIndex > options.length - 3 && !toSubCat)
			selectedCatIndex = 0;

		if (selectedCat.middle)
			remove(selectedCat.titleObject);

		selectedCat.changeColor(FlxColor.BLACK);
		selectedCat.alpha = 0.4;
		selectedCat = cat;
		selectedCat.alpha = 0.3;
		selectedCat.changeColor(FlxColor.WHITE);

		if (fromSubCat)
		{
			selectedOption = selectedCat.options[saveOptIndex];
			selectedOptionIndex = saveOptIndex;
			isInCat = false;
		}
		else
		{
			selectedOption = selectedCat.options[0];
			selectedOptionIndex = 0;
		}

		for (leStuff in shownStuff)
		{
			shownStuff.remove(leStuff, true);
		}

		shownStuff.members.resize(0);
		shownStuff.clear();

		if (selectedCat.middle)
			add(selectedCat.titleObject);

		if (!isInCat)
			selectOption(selectedOption);

		for (opt in selectedCat.optionObjects.members)
			opt.targetY = opt.ID - 5;

		for (i in selectedCat.optionObjects)
			shownStuff.add(i);

		Debug.logTrace("Changed cat: " + selectedCatIndex);

		updateOptColors();
	}

	public function selectOption(option:Option)
	{
		var object = selectedCat.optionObjects.members[selectedOptionIndex];

		selectedOption = option;

		if (!isInCat)
		{
			object.text = "> " + option.getValue();

			descText.text = option.getDescription();

			updateOptColors();

			if (selectedOption.blocked)
				descText.color = FlxColor.YELLOW;
			else
				descText.color = FlxColor.WHITE;

			descText.updateHitbox();
		}
		Debug.logTrace("Changed opt: " + selectedOptionIndex);

		Debug.logTrace("Bounds: " + visibleRange[0] + "," + visibleRange[1]);
	}

	var exiting:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		#if desktop
		if (isInPause)
		{
			if (PlayState.pauseStream.time == 0)
			{
				if (!PlayState.pauseStream.playing)
					PlayState.pauseStream.play();
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var accept = false;
		var right = false;
		var left = false;
		var up = false;
		var down = false;
		var any = false;
		var escape = false;
		var clickedCat = false;

		var rightHold = controls.RIGHT_P || FlxG.keys.pressed.RIGHT || (gamepad != null ? gamepad.pressed.DPAD_RIGHT : false);

		var leftHold = controls.LEFT_P || FlxG.keys.pressed.LEFT || (gamepad != null ? gamepad.pressed.DPAD_LEFT : false);

		changedOption = false;

		accept = controls.ACCEPT || FlxG.keys.justPressed.ENTER || (gamepad != null ? gamepad.justPressed.A : false);
		right = controls.RIGHT_P || FlxG.keys.justPressed.RIGHT || (gamepad != null ? gamepad.justPressed.DPAD_RIGHT : false);
		left = controls.LEFT_P || FlxG.keys.justPressed.LEFT || (gamepad != null ? gamepad.justPressed.DPAD_LEFT : false);
		up = controls.UP_P || FlxG.keys.justPressed.UP || (gamepad != null ? gamepad.justPressed.DPAD_UP : false);
		down = controls.DOWN_P || FlxG.keys.justPressed.DOWN || (gamepad != null ? gamepad.justPressed.DPAD_DOWN : false);

		any = FlxG.keys.justPressed.ANY || (gamepad != null ? gamepad.justPressed.ANY : false);
		escape = controls.BACK || FlxG.keys.justPressed.ESCAPE || (gamepad != null ? gamepad.justPressed.B : false);

		if (selectedCat != null && !exiting)
		{
			for (i in selectedCat.optionObjects.members)
			{
				if (selectedCat.middle)
				{
					i.screenCenter(X);
					i.updateHitbox();
				}

				// I wanna die!!!
				if (i.y < visibleRange[0] - 24 || i.y > visibleRange[1] - 24)
				{
					if (i.visible)
						i.visible = false;
				}
				else
				{
					if (!i.visible)
						i.visible = true;

					if (selectedCat.optionObjects.members[selectedOptionIndex].text != i.text || isInCat)
						i.alpha = 0.4;
					else
						i.alpha = 1;
				}
			}
		}

		if (isInCat)
		{
			descText.text = "Please select a category";

			descText.color = FlxColor.WHITE;
			descText.updateHitbox();

			if (selectedOption != null)
			{
				if (right)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedCatIndex++;

					if (selectedCatIndex > options.length - 3)
						selectedCatIndex = 0;
					if (selectedCatIndex < 0)
						selectedCatIndex = options.length - 3;

					switchCat(options[selectedCatIndex]);
				}
				else if (left)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedCatIndex--;

					if (selectedCatIndex > options.length - 3)
						selectedCatIndex = 0;
					if (selectedCatIndex < 0)
						selectedCatIndex = options.length - 3;

					switchCat(options[selectedCatIndex]);
				}
			}

			if (accept)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				selectedOptionIndex = 0;
				isInCat = false;
				selectOption(selectedCat.options[0]);
			}

			if (escape)
			{
				if (!isInPause)
				{
					exiting = true;
					FlxTween.tween(background, {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
					for (i in 0...selectedCat.optionObjects.length)
					{
						FlxTween.tween(selectedCat.optionObjects.members[i], {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
					}
					for (i in 0...options.length - 1)
					{
						FlxTween.tween(options[i].titleObject, {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
						FlxTween.tween(options[i], {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
					}
					FlxTween.tween(descText, {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
					FlxTween.tween(descBack, {alpha: 0}, 0.5, {
						ease: FlxEase.smootherStepInOut,
						onComplete: function(twn:FlxTween)
						{
							close();

							MusicBeatState.switchState(new MainMenuState());
						}
					});
				}
				else
				{
					PauseSubState.goBack = true;
					PlayState.instance.updateSettings();
					close();
				}
			}
		}
		else
		{
			if (selectedOption != null)
				if (selectedOption.acceptType)
				{
					if (escape && selectedOption.waitingType)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						selectedOption.waitingType = false;
						var object = selectedCat.optionObjects.members[selectedOptionIndex];
						object.text = "> " + selectedOption.getValue();
						object.updateHitbox();
						Debug.logTrace("New text: " + object.text);
						return;
					}
					else if (any)
					{
						var object = selectedCat.optionObjects.members[selectedOptionIndex];
						selectedOption.onType(gamepad == null ? FlxG.keys.getIsDown()[0].ID.toString() : gamepad.firstJustPressedID());
						object.text = "> " + selectedOption.getValue();
						object.updateHitbox();
						Debug.logTrace("New text: " + object.text);
					}
				}

			if (selectedOption.acceptType)
				if (accept)
				{
					var prev = selectedOptionIndex;
					var object = selectedCat.optionObjects.members[selectedOptionIndex];
					selectedOption.press();

					if (selectedOptionIndex == prev)
					{
						object.text = "> " + selectedOption.getValue();
						object.updateHitbox();
					}
				}

			#if !mobile
			if (FlxG.mouse.wheel != 0)
			{
				if (FlxG.mouse.wheel < 0)
					down = true;
				else if (FlxG.mouse.wheel > 0)
					up = true;
			}
			#end

			var bullShit:Int = 0;

			for (option in selectedCat.optionObjects.members)
			{
				if (selectedOptionIndex > 4)
				{
					option.targetY = bullShit - selectedOptionIndex;
					bullShit++;
				}
			}

			if (down)
			{
				if (selectedOption.acceptType)
					selectedOption.waitingType = false;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();
				selectedOptionIndex++;

				if (selectedOptionIndex < 0)
				{
					Debug.logInfo('UHH');
					selectedOptionIndex = options[selectedCatIndex].options.length - 1;
				}
				if (selectedOptionIndex > options[selectedCatIndex].options.length - 1)
				{
					if (options[selectedCatIndex].options.length >= 6)
					{
						for (option in selectedCat.optionObjects.members)
						{
							var leY = option.targetY;
							option.targetY = leY + (selectedOptionIndex - 6);
						}
					}
					selectedOptionIndex = 0;
					Debug.logTrace('returning');
				}

				selectOption(options[selectedCatIndex].options[selectedOptionIndex]);
			}
			else if (up)
			{
				if (selectedOption.acceptType)
					selectedOption.waitingType = false;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();
				selectedOptionIndex--;

				if (selectedOptionIndex < 0)
				{
					Debug.logInfo('UHH');
					selectedOptionIndex = options[selectedCatIndex].options.length - 1;
				}
				if (selectedOptionIndex > options[selectedCatIndex].options.length - 1)
				{
					selectedOptionIndex = 0;

					Debug.logTrace('returning');
				}

				selectOption(options[selectedCatIndex].options[selectedOptionIndex]);
			}
			if (!selectedOption.acceptType)
			{
				if (right)
					changeOptionValue(true);
				else if (left)
					changeOptionValue(false);

				if (selectedOption.getAccept())
				{
					if (rightHold || leftHold)
						holdTime += elapsed;
					else
						resetHoldTime();

					if (holdTime > 0.5)
					{
						if (Math.floor(elapsed) % 10 == 0)
						{
							if (rightHold)
								changeOptionValue(true);
							else if (leftHold)
								changeOptionValue(false);
						}
					}
				}
			}

			if (changedOption)
				updateOptColors();

			if (escape)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));

				PlayerSettings.player1.controls.loadKeyBinds();

				if (selectedCat.middle)
				{
					switchCat(options[saveIndex], false, true);
				}
				else
				{
					if (selectedCat.optionObjects != null)
						for (i in selectedCat.optionObjects.members)
						{
							if (i != null)
							{
								if (selectedOptionIndex > 4)
								{
									i.targetY += (selectedOptionIndex - 5);
									i.y = i.rawY;
								}
							}
						}

					for (object in selectedCat.optionObjects.members)
					{
						object.text = selectedCat.options[selectedCat.optionObjects.members.indexOf(object)].getValue();
						object.updateHitbox();
					}
					selectedOptionIndex = 0;

					isInCat = true;
				}
			}
		}

		#if !mobile
		if (!isInPause)
		{
			for (i in 0...options.length - 1)
			{
				if (i <= 4)
				{
					clickedCat = ((FlxG.mouse.overlaps(options[i].titleObject) || FlxG.mouse.overlaps(options[i]))
						&& FlxG.mouse.justPressed);
					if (clickedCat)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						selectedCatIndex = i;
						switchCat(options[i]);
						selectedOptionIndex = 0;
						isInCat = false;
						selectOption(selectedCat.options[0]);
					}
				}
			}
		}
		#end
	}

	override function close():Void
	{
		#if desktop
		if (isInPause)
		{
			PlayState.pauseStream.pause();
			remove(PlayState.pauseStream);
		}
		#end

		FlxG.save.flush();

		super.close();
	}

	override function destroy():Void
	{
		instance = null;
		for (cata in options)
			if (cata != null)
				cata.destroy();
		options.resize(0);

		super.destroy();
	}

	function resetHoldTime()
	{
		holdTime = 0;
	}

	function changeOptionValue(?right:Bool = false)
	{
		var object = selectedCat.optionObjects.members[selectedOptionIndex];

		if (right)
			selectedOption.right();
		else
			selectedOption.left();
		changedOption = true;

		object.text = "> " + selectedOption.getValue();
		object.updateHitbox();
	}

	function updateOptColors():Void
	{
		for (i in 0...selectedCat.options.length)
		{
			var opt = selectedCat.options[i];
			var optObject = selectedCat.optionObjects.members[i];
			opt.updateBlocks();

			if (opt.blocked)
				optObject.color = FlxColor.YELLOW;
			else
				optObject.color = FlxColor.WHITE;

			optObject.updateHitbox();
		}
	}
}
