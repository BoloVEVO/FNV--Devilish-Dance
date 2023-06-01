package;

import CoolUtil.CoolText;
import flixel.graphics.FlxGraphic;
import flixel.input.gamepad.FlxGamepad;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import lime.utils.Assets as LimeAssets;
import WeekData;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	var scoreText:CoolText;

	static var weeksID:Array<String> = [];

	var storyBackground:FlxSprite = null;

	public static function weekData():Array<WeekData>
	{
		var weeksToLoad:Array<WeekData> = [];

		weeksID = CoolUtil.coolTextFile(Paths.txt('data/weekList'));

		for (week in weeksID)
		{
			var data = Week.loadJSONFile(week);
			weeksToLoad.push(data);
		}

		return weeksToLoad;
	}

	public static var weeksLoaded:Array<WeekData> = null;

	var curDifficulty:Int = 1;

	public static var weekUnlocked:Array<Bool> = [];

	var diffList:Array<String> = [];

	var txtWeekTitle:CoolText;

	var curWeek:Int = 0;

	var currentWeek:Int = 0;

	var txtTracklist:CoolText;

	var availableDiffs:String = '';

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var diffsThatExists:Array<String>;

	function unlockWeeks():Array<Bool>
	{
		var weeks:Array<Bool> = [];

		for (i in 0...weeksLoaded.length)
			weeks.push(true);
		return weeks;

		weeks.push(true);

		for (i in 0...FlxG.save.data.weekUnlocked)
			weeks.push(true);

		return weeks;
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		weeksLoaded = weekData();

		weekUnlocked = unlockWeeks();

		PlayState.currentSong = "bruh";

		PlayState.SONG = null;

		PlayState.inDaPlay = false;
		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Story Mode Menu", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
			{
				FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "ke_freakyMenu" : "freakyMenu"));
				MainMenuState.freakyPlaying = true;
				Conductor.changeBPM(102);
			}
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new CoolText(10, 10, 32, 32, Paths.bitmapFont('fonts/vcr'));
		scoreText.autoSize = true;

		txtWeekTitle = new CoolText(FlxG.width * 0.7, 10, 32, 32, Paths.bitmapFont('fonts/vcr'));
		txtWeekTitle.autoSize = true;
		txtWeekTitle.alpha = 0.7;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0x000000);
		storyBackground = new FlxSprite(0, 56);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		trace("Line 70");

		for (i in 0...weeksLoaded.length)
		{
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, weeksID[i]);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = FlxG.save.data.antialiasing;
			// weekThing.updateHitbox();

			// Needs an offset thingie
			if (!weekUnlocked[i])
			{
				trace('locking week ' + i);
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = FlxG.save.data.antialiasing;
				grpLocks.add(lock);
			}
		}

		trace("Line 96");

		var charArray:Array<String> = weeksLoaded[0].characters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		trace("Line 124");

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = FlxG.save.data.antialiasing;
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = FlxG.save.data.antialiasing;

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + sprDifficulty.width + 68, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = FlxG.save.data.antialiasing;
		difficultySelectors.add(rightArrow);

		trace("Line 150");

		add(yellowBG);
		add(storyBackground);
		add(grpWeekCharacters);

		txtTracklist = new CoolText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 32, 32, Paths.bitmapFont('fonts/vcr'));
		txtTracklist.autoSize = false;
		txtTracklist.fieldWidth = 500;
		txtTracklist.alignment = CENTER;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);

		add(scoreText);
		add(txtWeekTitle);

		updateText();

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && weekUnlocked[curWeek])
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		PlayStateChangeables.modchart = true;
		PlayStateChangeables.botPlay = false;
		PlayStateChangeables.opponentMode = false;
		PlayStateChangeables.mirrorMode = false;
		PlayStateChangeables.holds = true;
		PlayStateChangeables.healthDrain = false;
		PlayStateChangeables.healthGain = 1;
		PlayStateChangeables.healthLoss = 1;
		PlayStateChangeables.practiceMode = false;
		PlayStateChangeables.skillIssue = false;

		trace("Line 165");
		changeWeek();
		changeDifficulty();

		super.create();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;
		scoreText.updateHitbox();

		txtWeekTitle.text = weeksLoaded[curWeek].weekName.toUpperCase();
		txtWeekTitle.updateHitbox();

		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		difficultySelectors.visible = weekUnlocked[curWeek];

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

				if (gamepad != null)
				{
					if (gamepad.justPressed.DPAD_UP)
					{
						changeWeek(-1);
					}
					if (gamepad.justPressed.DPAD_DOWN)
					{
						changeWeek(1);
					}

					if (gamepad.pressed.DPAD_RIGHT)
						rightArrow.animation.play('press')
					else
						rightArrow.animation.play('idle');
					if (gamepad.pressed.DPAD_LEFT)
						leftArrow.animation.play('press');
					else
						leftArrow.animation.play('idle');

					if (gamepad.justPressed.DPAD_RIGHT)
					{
						changeDifficulty(1);
					}
					if (gamepad.justPressed.DPAD_LEFT)
					{
						changeDifficulty(-1);
					}
				}

				#if !mobile
				if (FlxG.mouse.wheel != 0)
				{
					#if desktop
					changeWeek(-FlxG.mouse.wheel);
					#else
					if (FlxG.mouse.wheel < 0) // HTML5 BRAIN'T
						changeWeek(1);
					else if (FlxG.mouse.wheel > 0)
						changeWeek(-1);
					#end
				}
				#end

				if (FlxG.keys.justPressed.UP)
				{
					changeWeek(-1);
				}

				if (FlxG.keys.justPressed.DOWN)
				{
					changeWeek(1);
				}

				var mouseRight = (FlxG.mouse.overlaps(rightArrow, FlxG.camera) && FlxG.mouse.justPressed);
				var mouseLeft = (FlxG.mouse.overlaps(leftArrow, FlxG.camera) && FlxG.mouse.justPressed);

				if (controls.RIGHT || mouseRight)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.LEFT || mouseLeft)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.RIGHT_P || mouseRight)
					changeDifficulty(1);
				if (controls.LEFT_P || mouseLeft)
					changeDifficulty(-1);
			}

			var weekClicked = (FlxG.mouse.overlaps(grpWeekText.members[curWeek]) && FlxG.mouse.pressed && !stopspamming);
			if ((controls.ACCEPT && !FlxG.keys.pressed.ALT) || weekClicked)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (weekUnlocked[curWeek])
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				grpWeekCharacters.members[1].animation.play('bfConfirm');
				stopspamming = true;
			}

			PlayState.storyPlaylist = weeksLoaded[curWeek].songs;
			PlayState.isStoryMode = true;
			selectedWeek = true;
			PlayState.rate = 1;

			PlayState.isSM = false;

			var diffString = weeksLoaded[curWeek].difficulties[curDifficulty];

			for (k in weeksLoaded[curWeek].difficulties)
				Debug.logInfo(k);

			PlayState.storyDifficulty = CoolUtil.difficultyArray.indexOf(diffString);

			var diff:String = CoolUtil.getSuffixFromDiff(diffString);

			PlayState.swags = 0;
			PlayState.sicks = 0;
			PlayState.bads = 0;
			PlayState.shits = 0;
			PlayState.goods = 0;
			PlayState.campaignMisses = 0;
			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0], diff);
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;
			PlayState.campaignAccuracy = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
	}

	var tweenDifficulty:FlxTween;

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Std.int(weeksLoaded[curWeek].difficulties.length - 1);
		if (curDifficulty > weeksLoaded[curWeek].difficulties.length - 1)
			curDifficulty = 0;

		var graphicName = weeksLoaded[curWeek].difficulties[curDifficulty].toLowerCase();

		var newImage:FlxGraphic = Paths.image('menuDifficulties/$graphicName');

		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			if (tweenDifficulty != null)
				tweenDifficulty.cancel();
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07, {
				onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}
			});
		}

		sprDifficulty.alpha = 0;

		rightArrow.x = leftArrow.x + sprDifficulty.width + 68;

		var diffString = weeksLoaded[curWeek].difficulties[curDifficulty];

		var abDiff = CoolUtil.difficultyArray.indexOf(diffString); // USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		sprDifficulty.y = leftArrow.y - 15;
		intendedScore = Highscore.getWeekScore(curWeek, abDiff, 1);
		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, abDiff, 1);
		#end
		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= weeksLoaded.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weeksLoaded.length - 1;

		if (weeksLoaded[curWeek].difficulties == null || weeksLoaded[curWeek].difficulties.length == 0)
			weeksLoaded[curWeek].difficulties = CoolUtil.defaultDifficulties;

		if (weeksLoaded[curWeek].background != null)
		{
			storyBackground.loadGraphic(Paths.image('menuBackgrounds/${weeksLoaded[curWeek].background}'));
			storyBackground.alpha = 1;
		}
		else
			storyBackground.alpha = 0;

		changeDifficulty();

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && weekUnlocked[curWeek])
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateText();
	}

	function updateText()
	{
		var weekArray:Array<String> = weeksLoaded[curWeek].characters;
		for (i in 0...grpWeekCharacters.length)
		{
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}

		var stringThing:Array<String> = weeksLoaded[curWeek].songs;
		txtTracklist.text = "Tracks\n\n";

		for (i in stringThing)
			txtTracklist.text += "\n" + i;

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.updateHitbox();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty, 1);
		#end
	}

	public static function unlockNextWeek(week:Int):Void
	{
		if (week <= weeksLoaded.length - 1 /*&& FlxG.save.data.weekUnlocked == week*/) // fuck you, unlocks all weeks
		{
			weekUnlocked.push(true);
			trace('Week ' + week + ' beat (Week ' + (week + 1) + ' unlocked)');
		}

		FlxG.save.data.weekUnlocked = weekUnlocked.length - 1;
		FlxG.save.flush();
	}
}
