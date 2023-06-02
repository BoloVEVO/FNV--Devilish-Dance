package;

import CoolUtil.CoolText;
import flixel.util.FlxTimer;
import audio.AudioStream;
import openfl.utils.Future;
import openfl.media.Sound;
import flixel.system.FlxSound;
#if FEATURE_STEPMANIA
import smTools.SMFile;
#end
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import Song.SongData;
import flixel.input.gamepad.FlxGamepad;
import flash.text.TextField;
import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import openfl.utils.Assets as OpenFlAssets;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import FreeplaySubState;
import Modifiers;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import audio.AudioStream;
import openfl.utils.AssetCache;
import MusicBeatState.subStates;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<FreeplaySongMetadata> = [];

	var selector:FlxText;

	public static var rate:Float = 1.0;

	public static var lastRate:Float = 1.0;

	public static var curSelected:Int = 0;

	public static var curPlayed:Int = 0;

	public static var curDifficulty:Int = 1;

	var scoreText:CoolText;
	var comboText:CoolText;
	var diffText:CoolText;
	var diffCalcText:CoolText;
	var previewtext:CoolText;
	var helpText:CoolText;
	var opponentText:CoolText;
	var lerpScore:Int = 0;
	var intendedaccuracy:Float = 0.00;
	var intendedScore:Int = 0;
	var letter:String;
	var combo:String = 'N/A';
	var lerpaccuracy:Float = 0.00;

	var intendedColor:Int;
	var colorTween:FlxTween;

	var bg:FlxSprite;

	var Inst:FlxSound;

	public static var openMod:Bool = false;

	private var grpSongs:FlxTypedGroup<Alphabet>;

	private static var curPlaying:Bool = false;

	public static var songText:Alphabet;

	private var iconArray:Array<HealthIcon> = [];

	var songData:Map<String, Array<SongData>> = [];

	public static var songRating:Map<String, Dynamic> = [];

	public static var songRatingOp:Map<String, Dynamic> = [];

	public static var instance:FreeplayState = null;

	public static var loadedSongData:Bool = false;

	public static var currentSongPlaying:String = '';

	function loadDiff(diff:Int, songId:String, array:Array<SongData>)
		array.push(Song.loadFromJson(songId, CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[diff])));

	public static var list:Array<String> = [];

	override function create()
	{
		instance = this;

		PlayState.SONG = null;
		if (!PlayState.inDaPlay)
		{
			Paths.clearStoredMemory();
		}

		PlayState.wentToChartEditor = false;

		list = CoolUtil.coolTextFile(Paths.txt('data/freeplaySonglist'));

		cached = false;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));

		/*for (i in 0...songs.length - 1)
			songs[i].diffs.reverse(); */

		populateSongData();
		PlayState.inDaPlay = false;
		PlayState.currentSong = "bruh";

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		persistentUpdate = persistentDraw = true;

		// LOAD CHARACTERS
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songFixedName = StringTools.replace(songs[i].songName, "-", " ");
			songText = new Alphabet(0, (70 * i) + 30, songFixedName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			songText.visible = false;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.visible = false;
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new CoolText(FlxG.width * 0.6525, 10, 31, 31, Paths.bitmapFont('fonts/vcr'));
		scoreText.autoSize = true;
		scoreText.fieldWidth = FlxG.width;
		scoreText.antialiasing = FlxG.save.data.antialiasing;

		var bottomBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(Std.int(FlxG.width), 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var bottomText:String = #if !mobile #if PRELOAD_ALL "  Press SPACE to listen to the Song Instrumental / Click and scroll through the songs with your MOUSE /"
			+ #else "  Click and scroll through the songs with your MOUSE /"
			+ #end #end
		" Your offset is " + FlxG.save.data.offset + "ms ";

		var downText:CoolText = new CoolText(bottomBG.x, bottomBG.y + 4, 14.5, 16, Paths.bitmapFont('fonts/vcr'));
		downText.autoSize = true;
		downText.antialiasing = FlxG.save.data.antialiasing;
		downText.scrollFactor.set();
		downText.text = bottomText;
		downText.updateHitbox();
		add(downText);

		var scoreBG:FlxSprite = new FlxSprite((FlxG.width * 0.65) - 6, 0).makeGraphic(Std.int(FlxG.width * 0.4), 337, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		comboText = new CoolText(scoreText.x, scoreText.y + 36, 23, 23, Paths.bitmapFont('fonts/vcr'));
		comboText.autoSize = true;

		comboText.antialiasing = FlxG.save.data.antialiasing;
		add(comboText);

		opponentText = new CoolText(scoreText.x, scoreText.y + 66, 23, 23, Paths.bitmapFont('fonts/vcr'));
		opponentText.autoSize = true;

		opponentText.antialiasing = FlxG.save.data.antialiasing;
		add(opponentText);

		diffText = new CoolText(scoreText.x, scoreText.y + 106, 23, 23, Paths.bitmapFont('fonts/vcr'));

		diffText.antialiasing = FlxG.save.data.antialiasing;
		add(diffText);

		diffCalcText = new CoolText(scoreText.x, scoreText.y + 136, 23, 23, Paths.bitmapFont('fonts/vcr'));
		diffCalcText.autoSize = true;

		diffCalcText.antialiasing = FlxG.save.data.antialiasing;
		add(diffCalcText);

		previewtext = new CoolText(scoreText.x, scoreText.y + 166, 23, 23, Paths.bitmapFont('fonts/vcr'));
		previewtext.text = "Rate: < " + FlxMath.roundDecimal(rate, 2) + "x >";
		previewtext.autoSize = true;

		previewtext.antialiasing = FlxG.save.data.antialiasing;

		add(previewtext);

		helpText = new CoolText(scoreText.x, scoreText.y + 200, 18, 18, Paths.bitmapFont('fonts/vcr'));
		helpText.autoSize = true;
		helpText.text = "LEFT-RIGHT to change Difficulty\n\n" + "SHIFT + LEFT-RIGHT to change Rate\n" + "if it's possible\n\n"
			+ "CTRL to open Gameplay Modifiers\n" + "";

		helpText.antialiasing = FlxG.save.data.antialiasing;
		helpText.color = 0xFFfaff96;
		helpText.updateHitbox();
		add(helpText);

		add(scoreText);

		if (curSelected >= songs.length)
			curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if (!openMod)
		{
			changeSelection();
			changeDiff();
		}

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		PlayStateChangeables.modchart = FlxG.save.data.modcharts;
		PlayStateChangeables.botPlay = FlxG.save.data.botplay;
		PlayStateChangeables.opponentMode = FlxG.save.data.opponent;
		PlayStateChangeables.mirrorMode = FlxG.save.data.mirror;
		PlayStateChangeables.holds = FlxG.save.data.sustains;
		PlayStateChangeables.healthDrain = FlxG.save.data.hdrain;
		PlayStateChangeables.healthGain = FlxG.save.data.hgain;
		PlayStateChangeables.healthLoss = FlxG.save.data.hloss;
		PlayStateChangeables.practiceMode = FlxG.save.data.practice;
		PlayStateChangeables.skillIssue = FlxG.save.data.noMisses;

		if (MainMenuState.freakyPlaying)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "ke_freakyMenu" : "freakyMenu"));
		}

		super.create();

		subStates.push(new FreeplaySubState.ModMenu());

		Paths.clearUnusedMemory();

		if (!FlxG.sound.music.playing && !MainMenuState.freakyPlaying)
		{
			dotheMusicThing();
		}
	}

	public static var cached:Bool = false;

	/**
	 * Load song data from the data files.
	 */
	function populateSongData()
	{
		cached = false;
		list = CoolUtil.coolTextFile(Paths.txt('data/freeplaySonglist'));

		for (i in 0...list.length)
		{
			var data:Array<String> = list[i].split(':');
			var songId = data[0];
			var color = data[3];

			if (color == null)
			{
				color = "#9271fd";
			}

			var meta = new FreeplaySongMetadata(songId, Std.parseInt(data[2]), data[1], FlxColor.fromString(color));

			var diffs = [];
			var diffsThatExist = [];

			for (i in 0...CoolUtil.difficultyArray.length)
			{
				var leDiff = CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[i]);
				if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId$leDiff')))
					diffsThatExist.push(CoolUtil.difficultyArray[i]);
			}

			var customDiffs = CoolUtil.coolTextFile(Paths.txt('data/songs/$songId/customDiffs'));

			if (customDiffs != null)
			{
				for (i in 0...customDiffs.length)
				{
					var cDiff = customDiffs[i];
					if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId-${cDiff.toLowerCase()}')))
					{
						Debug.logTrace('New Difficulties detected for $songId: $cDiff');
						if (!diffsThatExist.contains(cDiff))
							diffsThatExist.push(cDiff);

						if (!CoolUtil.difficultyArray.contains(cDiff))
							CoolUtil.difficultyArray.push(cDiff);
					}
				}
			}

			if (diffsThatExist.length == 0)
			{
				if (FlxG.fullscreen)
					FlxG.fullscreen = !FlxG.fullscreen;
				Debug.displayAlert(meta.songName + " Chart", "No difficulties found for chart, skipping.");
			}

			if (!loadedSongData)
			{
				for (i in 0...CoolUtil.difficultyArray.length)
				{
					var leDiff = CoolUtil.difficultyArray[i];
					if (diffsThatExist.contains(leDiff))
						loadDiff(CoolUtil.difficultyArray.indexOf(leDiff), songId, diffs);
				}
				if (customDiffs != null)
				{
					for (i in 0...customDiffs.length)
					{
						var cDiff = customDiffs[i];
						if (diffsThatExist.contains(cDiff))
							loadDiff(CoolUtil.difficultyArray.indexOf(cDiff), songId, diffs);
					}
				}

				songData.set(songId, diffs);
				trace('loaded diffs for ' + songId);

				if (songData.get(songId) != null)
					for (diff in songData.get(songId))
					{
						var leData = songData.get(songId)[songData.get(songId).indexOf(diff)];
						if (!songRating.exists(leData.songId))
							songRating.set(Highscore.formatSong(leData.songId, songData.get(songId).indexOf(diff), 1), DiffCalc.CalculateDiff(leData));

						if (!songRatingOp.exists(leData.songId))
							songRatingOp.set(Highscore.formatSong(leData.songId, songData.get(songId).indexOf(diff), 1), DiffCalc.CalculateDiff(leData, true));
					}
			}

			meta.diffs = diffsThatExist;
			songs.push(meta);

			/*#if FFEATURE_FILESYSTEM
				sys.thread.Thread.create(() ->
				{
					FlxG.sound.cache(Paths.inst(songId));
				});
				#else
				FlxG.sound.cache(Paths.inst(songId));
				#end */
		}

		#if !FEATURE_STEPMANIA
		trace("FEATURE_STEPMANIA was not specified during build, sm file loading is disabled.");
		#elseif FEATURE_STEPMANIA
		// TODO: Refactor this to multiple difficulties.
		trace("tryin to load sm files");
		for (i in FileSystem.readDirectory("assets/sm/"))
		{
			trace(i);
			if (FileSystem.isDirectory("assets/sm/" + i))
			{
				trace("Reading SM file dir " + i);
				for (file in FileSystem.readDirectory("assets/sm/" + i))
				{
					if (file.contains(" "))
						FileSystem.rename("assets/sm/" + i + "/" + file, "assets/sm/" + i + "/" + file.replace(" ", "_"));
					if (file.endsWith(".sm") && !FileSystem.exists("assets/sm/" + i + "/converted.json"))
					{
						trace("reading " + file);
						var file:SMFile = SMFile.loadFile("assets/sm/" + i + "/" + file.replace(" ", "_"));
						file.jsonPath = "assets/sm/" + i + "/converted.json";

						trace("Converting " + file.header.TITLE);
						var data = file.convertToFNF("assets/sm/" + i + "/converted.json");
						var meta = new FreeplaySongMetadata(file.header.TITLE, 0, "sm", FlxColor.fromString("#9a9b9c"), file, "assets/sm/" + i);
						meta.diffs = ['Normal'];
						songs.push(meta);
						var song = Song.loadFromJsonRAW(data);
						instance.songData.set(file.header.TITLE, [song]);

						if (songData.get(song.songId) != null)
						{
							for (diff in songData.get(song.songId))
							{
								if (!songRating.exists(song.songId))
									songRating.set(Highscore.formatSong(song.songId, songData.get(song.songId).indexOf(diff), 1),
										DiffCalc.CalculateDiff(song));

								if (!songRatingOp.exists(song.songId))
									songRatingOp.set(Highscore.formatSong(song.songId, songData.get(song.songId).indexOf(diff), 1),
										DiffCalc.CalculateDiff(song, true));
							}
						}
					}
					else if (FileSystem.exists("assets/sm/" + i + "/converted.json") && file.endsWith(".sm"))
					{
						trace("reading " + file);
						var file:SMFile = SMFile.loadFile("assets/sm/" + i + "/" + file.replace(" ", "_"));
						file.jsonPath = "assets/sm/" + i + "/converted.json";

						trace("Converting " + file.header.TITLE);

						file.convertToFNF("assets/sm/" + i + "/converted.json");
						var meta = new FreeplaySongMetadata(file.header.TITLE, 0, "sm", FlxColor.fromString("#9a9b9c"), file, "assets/sm/" + i);
						meta.diffs = ['Normal'];
						songs.push(meta);
						var song = Song.loadFromJsonRAW(File.getContent("assets/sm/" + i + "/converted.json"));

						instance.songData.set(file.header.TITLE, [song]);

						if (songData.get(song.songId) != null)
						{
							for (diff in songData.get(song.songId))
							{
								if (!songRating.exists(song.songId))
									songRating.set(Highscore.formatSong(song.songId, songData.get(song.songId).indexOf(diff), 1),
										DiffCalc.CalculateDiff(song));

								if (!songRatingOp.exists(song.songId))
									songRatingOp.set(Highscore.formatSong(song.songId, songData.get(song.songId).indexOf(diff), 1),
										DiffCalc.CalculateDiff(song, true));
							}
						}
					}
				}
			}
		}
		#end

		instance.songData.clear();
		loadedSongData = true;
	}

	public var updateFrame = 0;

	var playinSong:SongData;

	override function update(elapsed:Float)
	{
		if (songStream != null)
		{
			#if desktop
			Conductor.songPosition = songStream.time;
			if (songStream.time != Conductor.songPosition)
				songStream.time = Conductor.songPosition;
			#end
		}
		if (!MainMenuState.freakyPlaying)
		{
			/*if (playinSong != null)
				if (updateFrame == 4)
				{
					TimingStruct.clearTimings();
					var currentIndex = 0;
					for (i in playinSong.eventObjects)
					{
						if (i.type == "BPM Change")
						{
							var beat:Float = i.position;

							var endBeat:Float = Math.POSITIVE_INFINITY;

							var bpm = i.value * rate;

							TimingStruct.addTiming(beat, bpm, endBeat, 0); // offset in this case = start time since we don't have a offset
							if (currentIndex != 0)
							{
								var data = TimingStruct.AllTimings[currentIndex - 1];
								data.endBeat = beat;
								data.length = ((data.endBeat - data.startBeat) / (data.bpm / 60));
								var step = (((60 / data.bpm) * 1000)) / 4;

								TimingStruct.AllTimings[currentIndex].startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step));
								TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
							}
							currentIndex++;
						}
					}
					updateFrame++;
				}
				else if (updateFrame != 5)
					updateFrame++; */

			#if desktop
			if (songStream != null)
			{
				if (songStream.playing)
				{
					if (curTiming != null)
					{
						var curBPM = curTiming.bpm;

						if (curBPM != Conductor.bpm)
						{
							Debug.logInfo("BPM CHANGE to " + curBPM);
							Conductor.changeBPM(curBPM, false);
						}
					}
				}
			}
			#end
		}

		if (songStream != null)
		{
			#if desktop
			if (songStream.volume < 0.7)
			{
				songStream.volume += 0.5 * FlxG.elapsed;
			}
			#end
		}

		if (openMod)
		{
			for (i in 0...iconArray.length)
			{
				iconArray[i].visible = false;
			}

			for (item in grpSongs.members)
			{
				item.alpha = 0;
				item.visible = false;
			}
		}

		super.update(elapsed);

		for (k in iconArray)
		{
			if (k.sprTracker.targetY >= -4 && k.sprTracker.targetY <= 4)
			{
				if (!openMod)
				{
					if (!k.visible)
					{
						k.visible = true;
					}
				}
			}
			else
			{
				if (k.visible)
				{
					k.visible = false;
				}
			}
		}

		for (k in grpSongs.members)
		{
			if (k.targetY >= -4 && k.targetY <= 4)
			{
				if (!openMod)
				{
					if (!k.visible)
					{
						k.visible = true;
					}
				}
			}
			else
			{
				if (k.visible)
				{
					k.visible = false;
				}
			}
		}

		/*if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}*/

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));
		lerpaccuracy = FlxMath.lerp(lerpaccuracy, intendedaccuracy, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1) / (openfl.Lib.current.stage.frameRate / 60));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (Math.abs(lerpaccuracy - intendedaccuracy) <= 0.001)
			lerpaccuracy = intendedaccuracy;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		scoreText.updateHitbox();

		if (combo == "")
		{
			comboText.text = "RANK: N/A";
			comboText.alpha = 0.5;
		}
		else
		{
			comboText.text = "RANK: " + letter + " | " + combo + " (" + HelperFunctions.truncateFloat(lerpaccuracy, 2) + "%)\n";
			comboText.alpha = 1;
		}

		comboText.updateHitbox();

		opponentText.text = "OPPONENT MODE: " + (FlxG.save.data.opponent ? "ON" : "OFF");

		opponentText.updateHitbox();

		var upP = FlxG.keys.justPressed.UP;
		var downP = FlxG.keys.justPressed.DOWN;
		var accepted = FlxG.keys.justPressed.ENTER && !FlxG.keys.pressed.ALT;
		var dadDebug = FlxG.keys.justPressed.SIX;
		var charting = FlxG.keys.justPressed.SEVEN;
		var bfDebug = FlxG.keys.justPressed.ZERO;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (!openMod && !MusicBeatState.switchingState)
		{
			if (FlxG.mouse.wheel != 0)
			{
				#if desktop
				changeSelection(-FlxG.mouse.wheel);
				#else
				if (FlxG.mouse.wheel < 0) // HTML5 BRAIN'T
					changeSelection(1);
				else if (FlxG.mouse.wheel > 0)
					changeSelection(-1);
				#end
			}

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
				if (gamepad.justPressed.DPAD_LEFT)
				{
					changeDiff(-1);
				}
				if (gamepad.justPressed.DPAD_RIGHT)
				{
					changeDiff(1);
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

			if (FlxG.keys.justPressed.SPACE)
			{
				dotheMusicThing();
			}
		}
		previewtext.text = "Rate: " + FlxMath.roundDecimal(rate, 2) + "x";
		previewtext.updateHitbox();

		if (!MainMenuState.freakyPlaying)
		{
			var bpmRatio = Conductor.bpm / 100;
			if (FlxG.save.data.camzoom)
			{
				FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * rate), 0, 1));
			}

			var mult:Float = FlxMath.lerp(1, iconArray[curSelected].scale.x, CoolUtil.boundTo(1 - (elapsed * 35 * rate), 0, 1));
			iconArray[curSelected].scale.set(mult, mult);

			iconArray[curSelected].updateHitbox();
		}

		previewtext.alpha = 1;

		if (FlxG.keys.justPressed.CONTROL && !openMod && !MusicBeatState.switchingState)
		{
			openMod = true;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			openSubState(subStates[0]);
		}

		if (!openMod && !MusicBeatState.switchingState)
		{
			if (FlxG.keys.pressed.SHIFT) // && songs[curSelected].songName.toLowerCase() != "tutorial")
			{
				if (FlxG.keys.justPressed.LEFT)
				{
					rate -= 0.05;
					lastRate = rate;
					updateDiffCalc();
					updateScoreText();
				}
				if (FlxG.keys.justPressed.RIGHT)
				{
					rate += 0.05;
					lastRate = rate;
					updateDiffCalc();
					updateScoreText();
				}

				if (FlxG.keys.justPressed.R)
				{
					rate = 1;
					lastRate = rate;
					updateDiffCalc();
					updateScoreText();
				}

				if (rate > 3)
				{
					rate = 3;
					lastRate = rate;
					updateDiffCalc();
					updateScoreText();
				}
				else if (rate < 0.5)
				{
					rate = 0.5;
					lastRate = rate;
					updateDiffCalc();
					updateScoreText();
				}

				previewtext.text = "Rate: < " + FlxMath.roundDecimal(rate, 2) + "x >";
				previewtext.updateHitbox();
			}
			else
			{
				if (FlxG.keys.justPressed.LEFT)
					changeDiff(-1);
				if (FlxG.keys.justPressed.RIGHT)
					changeDiff(1);
			}

			#if cpp
			{
				if (!MainMenuState.freakyPlaying)
				{
					if (songStream != null)
					{
						if (songStream.playing)
							songStream.speed = rate;

						if (songStream.time == 0)
							if (!songStream.playing)
								dotheMusicThing();
					}
				}
			}
			#end

			#if html5
			diffCalcText.text = "RATING: N/A";
			diffCalcText.alpha = 0.5;
			#end

			if (!openMod && !MusicBeatState.switchingState)
			{
				if (controls.BACK)
				{
					MusicBeatState.switchState(new MainMenuState());
					if (colorTween != null)
					{
						colorTween.cancel();
					}
				}

				for (item in grpSongs.members)
					if (accepted
						|| (((FlxG.mouse.overlaps(item) && item.targetY == 0) || (FlxG.mouse.overlaps(iconArray[curSelected])))
							&& FlxG.mouse.pressed))
					{
						loadSong();
						break;
					}
				#if debug
				// Going to charting state via Freeplay is only enable in debug builds.
				else if (charting)
					loadSong(true);

				// AnimationDebug and StageDebug are only enabled in debug builds.

				if (dadDebug)
				{
					loadAnimDebug(true);
				}
				if (bfDebug)
				{
					loadAnimDebug(false);
				}
				#end
			}
		}
	}

	function updateScoreText()
	{
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		// adjusting the highscore song name to be compatible (changeDiff)
		switch (songHighscore)
		{
			case 'Dad-Battle':
				songHighscore = 'Dadbattle';
			case 'Philly-Nice':
				songHighscore = 'Philly';
			case 'M.I.L.F':
				songHighscore = 'Milf';
		}
		var abDiff = CoolUtil.difficultyArray.indexOf(songs[curSelected].diffs[curDifficulty]);
		#if !switch
		intendedScore = Highscore.getScore(songHighscore, abDiff, rate);
		combo = Highscore.getCombo(songHighscore, abDiff, rate);
		letter = Highscore.getLetter(songHighscore, abDiff, rate);
		intendedaccuracy = Highscore.getAcc(songHighscore, abDiff, rate);
		#end
	}

	override function beatHit()
	{
		super.beatHit();
	}

	override function stepHit()
	{
		super.stepHit();

		if (!MainMenuState.freakyPlaying)
		{
			if (curStep % 4 == 0)
			{
				iconArray[curSelected].scale.set(1.2, 1.2);

				iconArray[curSelected].updateHitbox();
			}
		}
	}

	override function sectionHit()
	{
		super.sectionHit();
		#if cpp
		if (!MainMenuState.freakyPlaying)
		{
			if (songStream != null)
				if (songStream.playing)
					if (FlxG.save.data.camzoom && FlxG.camera.zoom < 1.35)
					{
						FlxG.camera.zoom += 0.03 / rate;
					}
		}
		#end
	}

	function loadAnimDebug(dad:Bool = true)
	{
		// First, get the song data.
		var hmm;
		try
		{
			hmm = songData.get(songs[curSelected].songName)[curDifficulty];
			if (hmm == null)
				return;
		}
		catch (ex)
		{
			return;
		}
		PlayState.SONG = hmm;

		var character = dad ? PlayState.SONG.player2 : PlayState.SONG.player1;

		LoadingState.loadAndSwitchState(new AnimationDebug(character));
	}

	function loadSong(isCharting:Bool = false)
	{
		loadSongInFreePlay(songs[curSelected].songName, curDifficulty, isCharting);
	}

	/**
	 * Load into a song in free play, by name.
	 * This is a static function, so you can call it anywhere.
	 * @param songName The name of the song to load. Use the human readable name, with spaces.
	 * @param isCharting If true, load into the Chart Editor instead.
	 */
	public static function loadSongInFreePlay(songName:String, difficulty:Int, isCharting:Bool, reloadSong:Bool = false)
	{
		var currentSongData:SongData = null;

		try
		{
			if (instance.songs[curSelected].songCharacter == "sm")
			{
				currentSongData = Song.loadFromJsonRAW(File.getContent(instance.songs[curSelected].sm.jsonPath));
			}
			else
			{
				currentSongData = Song.loadFromJson(instance.songs[curSelected].songName,
					CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[CoolUtil.difficultyArray.indexOf(instance.songs[curSelected].diffs[difficulty])]));
			}
		}
		catch (ex)
		{
			Debug.logError(ex);
			return;
		}

		PlayState.SONG = currentSongData;
		PlayState.storyDifficulty = CoolUtil.difficultyArray.indexOf(instance.songs[curSelected].diffs[difficulty]);
		PlayState.storyWeek = instance.songs[curSelected].week;

		PlayState.isStoryMode = false;

		#if FEATURE_STEPMANIA
		if (instance.songs[curSelected].songCharacter == "sm")
		{
			PlayState.isSM = true;
			PlayState.sm = instance.songs[curSelected].sm;
			PlayState.pathToSm = instance.songs[curSelected].path;
		}
		else
			PlayState.isSM = false;
		#else
		PlayState.isSM = false;
		#end

		PlayState.rate = rate;

		lastRate = rate;

		PlayState.inDaPlay = true;

		if (isCharting)
			LoadingState.loadAndSwitchState(new ChartingState());
		else
			LoadingState.loadAndSwitchState(new PlayState());
	}

	function changeDiff(change:Int = 0)
	{
		if (songs[curSelected].diffs.length > 0)
		{
			curDifficulty += change;

			if (curDifficulty < 0)
				curDifficulty = songs[curSelected].diffs.length - 1;
			if (curDifficulty > songs[curSelected].diffs.length - 1)
				curDifficulty = 0;

			diffText.text = 'DIFFICULTY: < ' + songs[curSelected].diffs[curDifficulty].toUpperCase() + ' >';
			diffText.alpha = 1;
		}
		else
		{
			diffText.text = 'DIFFICULTY: < N/A >';
			diffText.alpha = 0.5;
		}

		diffText.updateHitbox();
		updateScoreText();
		updateDiffCalc();
	}

	public function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		changeDiff();

		/*if (songs[curSelected].songName.toLowerCase() == "tutorial")
			{
				rate = 1.0;
		}*/

		var newColor:Int = songs[curSelected].color;
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
		// selector.y = (70 * curSelected) + 30;

		// adjusting the highscore song name to be compatible (changeSelection)
		// would read original scores if we didn't change packages
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		switch (songHighscore)
		{
			case 'Dad-Battle':
				songHighscore = 'Dadbattle';
			case 'Philly-Nice':
				songHighscore = 'Philly';
			case 'M.I.L.F':
				songHighscore = 'Milf';
		}

		updateScoreText();

		/*diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			diffText.text = 'DIFFICULTY: < ' + CoolUtil.difficultyFromInt(curDifficulty).toUpperCase() + ' >'; */
		/*#if PRELOAD_ALL
			if (songs[curSelected].songCharacter == "sm")
			{
				var data = songs[curSelected];
				trace("Loading " + data.path + "/" + data.sm.header.MUSIC);
				var bytes = File.getBytes(data.path + "/" + data.sm.header.MUSIC);
				var sound = new Sound();
				sound.loadCompressedDataFromByteArray(bytes.getData(), bytes.length);
				FlxG.sound.playMusic(sound);
			}
			else
			{
				FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0.7);
			}
			#end */

		var hmm;
		try
		{
			hmm = songData.get(songs[curSelected].songName)[curDifficulty];
			/*if (hmm != null)
				GameplayCustomizeState.freeplayNoteStyle = hmm.noteStyle; */
		}
		catch (ex)
		{
		}

		var bullShit:Int = 0;

		if (!openMod && !MusicBeatState.switchingState)
		{
			for (i in 0...iconArray.length)
			{
				iconArray[i].alpha = 0.6;
			}

			iconArray[curSelected].alpha = 1;
		}

		for (item in grpSongs.members)
		{
			if (!openMod && !MusicBeatState.switchingState)
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
	}

	private function dotheMusicThing():Void
	{
		#if desktop
		try
		{
			FlxG.sound.music.stop();

			playinSong = Song.loadFromJson(songs[curSelected].songName,
				CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[CoolUtil.difficultyArray.indexOf(songs[curSelected].diffs[curDifficulty])]));

			activeSong = playinSong;

			if (songStream != null)
			{
				songStream.stop();
			}

			if (currentSongPlaying != songs[curSelected].songName)
			{
				if (songStream != null)
				{
					songStream.destroy();
					songStream = null;
				}

				var songPath:String = null;

				if (songs[curSelected].songCharacter == "sm")
					songPath = FileSystem.absolutePath(songs[curSelected].path + "/" + songs[curSelected].sm.header.MUSIC);
				else
					songPath = OpenFlAssets.getPath(Paths.inst(songs[curSelected].songName, true));

				songStream = new AudioStream(songPath);
				add(songStream);

				songPath = null;
			}
			else
			{
				add(songStream);
				songStream.stop();
				songStream.play();
				songStream.time = 0;
			}

			songStream.volume = 0;

			MainMenuState.freakyPlaying = false;

			TimingStruct.clearTimings();

			curTiming = null;

			var currentIndex = 0;
			for (event in playinSong.events)
			{
				switch (event.name)
				{
					case 'changeBPM':
						{
							var beat:Float = event.beat;
							var endBeat:Float = Math.POSITIVE_INFINITY;

							var bpm = event.args[0];
							TimingStruct.addTiming(beat, bpm, endBeat, 0); // offset in this case = start time since we don't have a offset

							if (currentIndex != 0)
							{
								var data = TimingStruct.AllTimings[currentIndex - 1];
								data.endBeat = beat;
								data.length = ((data.endBeat - (data.startBeat)) / (data.bpm / 60));
								var step = ((60 / (data.bpm)) * 1000) / 4;
								TimingStruct.AllTimings[currentIndex].startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step));
								TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
							}

							currentIndex++;
							recalculateAllSectionTimes();
						}
				}
			}
			rate = lastRate;

			songStream.play();

			currentSongPlaying = songs[curSelected].songName;
		}
		catch (e)
		{
			Debug.logError(e);
		}
		#end
	}

	override function destroy()
	{
		#if desktop
		if (songStream != null)
		{
			songStream.destroy();
			songStream = null;
		}
		#end
		instance = null;
		super.destroy();
	}

	override function startOutro(onOutroComplete:() -> Void)
	{
		MainMenuState.freakyPlaying = true;
		onOutroComplete();
	}

	public function updateDiffCalc():Void
	{
		if (songs[curSelected].diffs[curDifficulty] != null)
		{
			var toShow = 0.0;
			toShow = FlxG.save.data.opponent ? HelperFunctions.truncateFloat(songRatingOp.get(Highscore.formatSong(songs[curSelected].songName, curDifficulty,
				1)) * rate,
				2) : HelperFunctions.truncateFloat(songRating.get(Highscore.formatSong(songs[curSelected].songName, curDifficulty, 1)) * rate, 2);
			diffCalcText.text = 'RATING: ${toShow}';
			diffCalcText.alpha = 1;
		}
		else
		{
			Debug.logError('Error on calculating difficulty rate from song: ${songs[curSelected].songName}');
			diffCalcText.alpha = 0.5;
			diffCalcText.text = 'RATING: N/A';
		}
		diffCalcText.updateHitbox();
	}
}

class FreeplaySongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	#if FEATURE_STEPMANIA
	public var sm:SMFile;
	public var path:String;
	#end
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var diffs = [];

	#if FEATURE_STEPMANIA
	public function new(song:String, week:Int, songCharacter:String, ?color:FlxColor, ?sm:SMFile = null, ?path:String = "")
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.sm = sm;
		this.path = path;
	}
	#else
	public function new(song:String, week:Int, songCharacter:String, ?color:FlxColor)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
	}
	#end
}
