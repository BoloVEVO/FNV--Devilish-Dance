package;

#if FEATURE_STEPMANIA
import smTools.SMFile;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import flixel.input.keyboard.FlxKey;
#if FEATURE_MULTITHREADING
import sys.thread.Mutex;
#end
import openfl.utils.Assets as OpenFlAssets;
import openfl.Lib;

using StringTools;

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	var bg:FlxSprite;

	var http = new haxe.Http("https://raw.githubusercontent.com/BoloVEVO/Kade-Engine-Public/stable/version.txt");
	var returnedData:Array<String> = [];

	override public function create():Void
	{
		(cast(Lib.current.getChildAt(0), Main)).checkInternetConnection();

		/*if (Main.internetConnection)
			getBuildVer(); */

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		@:privateAccess
		{
			Debug.logTrace("We loaded " + openfl.Assets.getLibrary("default").assetsLoaded + " assets into the default library");
		}

		FlxG.fixedTimestep = false;

		FlxG.autoPause = false;

		FlxG.save.bind('funkin' #if (flixel < "5.0.0"), 'ninjamuffin99' #end);

		PlayerSettings.init();

		OpenFlAssets.cache.enabled = true;

		KadeEngineData.initSave();

		#if html5
		FlxG.save.data.gpuRender = false;
		#end

		KeyBinds.keyCheck();

		// It doesn't reupdate the list before u restart rn lmao

		NoteskinHelpers.updateNoteskins();

		if (FlxG.save.data.volDownBind == null)
			FlxG.save.data.volDownBind = "NUMPADMINUS";
		if (FlxG.save.data.volUpBind == null)
			FlxG.save.data.volUpBind = "NUMPADPLUS";

		FlxG.sound.muteKeys = [FlxKey.fromString(Std.string(FlxG.save.data.muteBind))];
		FlxG.sound.volumeDownKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volDownBind))];
		FlxG.sound.volumeUpKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volUpBind))];

		FlxG.mouse.visible = true;

		FlxG.worldBounds.set(0, 0);

		MusicBeatState.initSave = true;

		Highscore.load();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		trace('hello');

		// DEBUG BULLSHIT

		bg = new FlxSprite().loadGraphic(Paths.image('titleBG'));
		bg.screenCenter();
		bg.alpha = 0;
		// bg.antialiasing = FlxG.save.data.antialiasing;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();

		logoBl = new FlxSprite(-150, 1500);

		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.antialiasing = FlxG.save.data.antialiasing;
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.7));

		logoBl.updateHitbox();
		logoBl.screenCenter();
		logoBl.y -= 55;
		// logoBl.color = FlxColor.BLACK;

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = FlxG.save.data.antialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		if (!initialized)
		{
			credGroup = new FlxGroup();

			textGroup = new FlxGroup();

			blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			credGroup.add(blackScreen);
			credGroup.add(bg);

			credTextShit = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
			credTextShit.screenCenter();

			ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
			ngSpr.visible = false;
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
			ngSpr.updateHitbox();
			ngSpr.screenCenter(X);
			ngSpr.antialiasing = FlxG.save.data.antialiasing;
		}

		FlxG.sound.volume = FlxG.save.data.volume;
		FlxG.sound.muted = FlxG.save.data.mute;

		super.create();

		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		#if !cpp
		if (!initialized)
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		else
			startIntro();
		#else
		startIntro();
		#end
		#end
	}

	var logoBl:FlxSprite;

	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro()
	{
		persistentUpdate = true;

		add(bg);
		add(logoBl);
		add(titleText);

		FlxG.mouse.visible = true;
		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		// credTextShit.alignment = CENTER;

		if (initialized)
			skipIntro();
		else
		{
			credTextShit.visible = false;

			FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

			add(credGroup);
			add(ngSpr);
			/*var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
				diamond.persist = true;
				diamond.destroyOnNoUse = false;

				FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
					new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
				FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
					{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
			 */

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('freakyMenu'));
			// FlxG.sound.list.add(music);
			// music.play();
			FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "ke_freakyMenu" : "freakyMenu"));
			MainMenuState.freakyPlaying = true;

			FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.changeBPM(140);
		}

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('data/introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		if (bg.alpha < 1)
			bg.alpha += 0.1 * elapsed;
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT || FlxG.mouse.justPressed;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		if (pressedEnter && !transitioning && skippedIntro)
		{
			if (FlxG.save.data.flashing)
				titleText.animation.play('press');

			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			// FlxG.sound.music.stop();

			MainMenuState.firstStart = true;
			MainMenuState.finishedFunnyMove = false;

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				// Get current version of Kade Engine
				if (MainMenuState.updateShit)
				{
					MusicBeatState.switchState(new OutdatedSubState());
				}
				else
				{
					MusicBeatState.switchState(new MainMenuState());
				}
			});
			// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
		}

		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	function getBuildVer():Void
	{
		http.onData = function(data:String)
		{
			returnedData[0] = data.substring(0, data.indexOf(';'));
			returnedData[1] = data.substring(data.indexOf('-'), data.length);
			if (!MainMenuState.buildVer.contains(returnedData[0].trim()) && !OutdatedSubState.leftState)
			{
				Debug.logInfo('New version detected: ' + returnedData[0]);
				MainMenuState.updateShit = true;
				Debug.logInfo('outdated lmao! ' + returnedData[0] + ' != ' + MainMenuState.kadeEngineVer);
				OutdatedSubState.needVer = returnedData[0];
				OutdatedSubState.currChanges = returnedData[1];
			}
			else
			{
				Debug.logInfo('Build is up to date bois.');
			}
		}

		http.onError = function(error)
		{
			Debug.logError('error: $error');
		}

		http.request();
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			if (!initialized)
			{
				var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
				money.screenCenter(X);
				money.y += (i * 60) + 200;
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String)
	{
		if (!initialized)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		if (!initialized)
		{
			while (textGroup.members.length > 0)
			{
				credGroup.remove(textGroup.members[0], true);
				textGroup.remove(textGroup.members[0], true);
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		logoBl.animation.play('bump', true);

		danceLeft = !danceLeft;

		// Debug.logInfo('beat $curBeat');

		switch (curBeat)
		{
			case 0:
				deleteCoolText();
			case 1:
				addMoreText('TITS');

			case 2:
				addMoreText('JIGGLE PHYSICS');
			// credTextShit.visible = true;
			case 3:
				deleteCoolText();
				addMoreText('FUCK');

			// credTextShit.text += '\npresent...';
			// credTextShit.addText();
			case 4:
				addMoreText('INTRO TEXT');

			// credTextShit.visible = false;
			// credTextShit.text = 'In association \nwith';
			// credTextShit.screenCenter();

			case 5:
				deleteCoolText();
				addMoreText('Friday');
			// credTextShit.visible = true;
			case 6:
				addMoreText('Night');
			// credTextShit.text += '\nNight';
			case 7:
				addMoreText('Voltex'); // credTextShit.text += '\nFunkin';

			// credTextShit.text += '\nNewgrounds';
			case 8:
				skipIntro();
				initialized = true;
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			bg.alpha = 1;
			Debug.logInfo("Skipping intro...");

			remove(ngSpr);

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);

			// FlxTween.tween(logoBl, {y: -100}, 1.4, {ease: FlxEase.expoInOut});

			// logoBl.angle = -4;

			/*new FlxTimer().start(0.01, function(tmr:FlxTimer)
				{
					if (logoBl.angle == -4)
						FlxTween.angle(logoBl, logoBl.angle, 4, 4, {ease: FlxEase.quartInOut});
					if (logoBl.angle == 4)
						FlxTween.angle(logoBl, logoBl.angle, -4, 4, {ease: FlxEase.quartInOut});
			}, 0);*/

			// It always bugged me that it didn't do this before.
			// Skip ahead in the song to the drop.
			if (!initialized)
				FlxG.sound.music.time = 3433; // 9.4 seconds

			skippedIntro = true;
		}
	}
}
