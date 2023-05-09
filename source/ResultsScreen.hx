package;

import flixel.util.FlxSpriteUtil;
import Modifiers.Modifier;
import haxe.Exception;
#if FEATURE_STEPMANIA
import smTools.SMFile;
#end
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import flixel.system.FlxSound;
import flixel.util.FlxAxes;
import flixel.FlxSubState;
import Options.Option;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxKeyManager;

using StringTools;

class ResultsScreen extends MusicBeatSubstate
{
	public var background:FlxSprite;
	public var text:FlxText;

	public var graph:HitGraph;
	public var graphSprite:OFLSprite;

	public var comboText:FlxText;
	public var contText:FlxText;
	public var settingsText:FlxText;

	public var songText:FlxText;
	public var music:FlxSound;

	public var modifiers:String;

	public var activeMods:FlxText;

	public var superMegaConditionShit:Bool;

	public static var instance:ResultsScreen = null;

	public function new()
	{
		super();
		instance = this;

		openCallback = refresh;

		background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.scrollFactor.set();

		#if !cpp
		music = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		#end

		if (!PlayState.isStoryMode)
		{
			modifiers = 'Active Modifiers:\n${(PlayStateChangeables.opponentMode ? '- Opponent Mode\n' : '')}${(PlayStateChangeables.mirrorMode ? '- Mirror Mode\n' : '')}${(PlayStateChangeables.practiceMode ? '- Practice Mode\n' : '')}${(PlayStateChangeables.skillIssue ? '- No Misses mode\n' : '')}${(!PlayStateChangeables.holds ? '- Hold Notes OFF\n' : '')}${(!PlayStateChangeables.modchart #if FEATURE_LUAMODCHART && FileSystem.exists(Paths.lua('songs/${PlayState.SONG.songId}/modchart')) #else && PlayState.instance.sourceModchart #end ? '- Song modchart OFF\n' : '')}${(PlayStateChangeables.healthDrain ? '- Health Drain ON\n' : '')}${(HelperFunctions.truncateFloat(PlayStateChangeables.healthGain,2) != 1 ? '- HP Gain ${HelperFunctions.truncateFloat(PlayStateChangeables.healthGain, 2)}x\n': '')}${(HelperFunctions.truncateFloat(PlayStateChangeables.healthLoss,2) != 1 ? '- HP Loss ${HelperFunctions.truncateFloat(PlayStateChangeables.healthLoss, 2)}x\n':'')}';
			if (modifiers == 'Active Modifiers:\n')
				modifiers = 'Active Modifiers: None';
			activeMods = new FlxText(FlxG.width - 500, FlxG.height - 450, FlxG.width, modifiers);
			activeMods.size = 24;
			activeMods.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
			activeMods.scrollFactor.set();
		}

		text = new FlxText(20, -55, 0, "Song Cleared!");
		text.size = 34;
		text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
		text.color = FlxColor.WHITE;
		text.scrollFactor.set();

		if (PlayState.isStoryMode)
		{
			text.text = 'Week Cleared on ${PlayState.instance.storyDifficultyText.toUpperCase()}!';
		}
		comboText = new FlxText(20, -75, 0, '');

		if (!PlayState.isStoryMode)
		{
			songText = new FlxText(20, -65, FlxG.width,
				'Played on ${PlayState.SONG.songName} - ${CoolUtil.difficultyFromInt(PlayState.storyDifficulty).toUpperCase()}');
			songText.size = 34;
			songText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
			songText.color = FlxColor.WHITE;
			songText.scrollFactor.set();
		}

		comboText.size = 28;
		comboText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
		comboText.color = FlxColor.WHITE;
		comboText.scrollFactor.set();

		contText = new FlxText(FlxG.width - 525, FlxG.height + 50, 0, 'Click or Press ${KeyBinds.gamepad ? 'A' : 'ENTER'} to continue.');

		contText.size = 24;
		contText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
		contText.color = FlxColor.WHITE;
		contText.scrollFactor.set();

		graph = new HitGraph(FlxG.width - 600, 45, 525, 180);

		settingsText = new FlxText(20, FlxG.height + 75, 0, '');
		settingsText.size = 16;
		settingsText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
		settingsText.color = FlxColor.WHITE;
		settingsText.scrollFactor.set();
	}

	var mean:Float = 0;

	override function create()
	{
		add(background);
		if (!PlayState.inResults)
		{
			#if !cpp
			music.volume = 0;
			music.play(false, FlxG.random.int(0, Std.int(music.length / 2)));
			FlxG.sound.list.add(music);
			#end
		}

		add(activeMods);

		background.alpha = 0;

		add(text);

		if (!PlayState.isStoryMode)
			add(songText);

		var score = PlayState.instance.songScore;
		var acc = PlayState.instance.accuracy;

		if (PlayState.isStoryMode)
		{
			acc = PlayState.campaignAccuracy;
			score = PlayState.campaignScore;
		}

		var judgeCounter:String = '';

		var timingWins = Ratings.timingWindows.copy();
		timingWins.reverse();

		for (rating in timingWins)
			judgeCounter += '${rating.name}s: ${rating.count}\n';

		comboText.text = 'Judgements:\n$judgeCounter\nCombo Breaks: ${(PlayState.isStoryMode ? PlayState.campaignMisses : PlayState.misses)}\nHighest Combo: ${PlayState.highestCombo + 1}\nScore: $score\n${(PlayState.isStoryMode ? 'Average Accuracy' : 'Accuracy')}: ${HelperFunctions.truncateFloat(acc, 2)}% ( ${(FlxG.save.data.accuracyMod == 0 ? 'Accurate' : 'Complex')} )\n\n${Ratings.GenerateComboRank(PlayState.instance.accuracy)} ${Ratings.GenerateLetterRank(PlayState.instance.accuracy)}\nRate: ${HelperFunctions.truncateFloat(PlayState.instance.songMultiplier, 2)}x';

		add(comboText);

		#if mobile
		contText.text = "Touch to continue";
		#end

		add(contText);

		graph.update();

		graphSprite = new OFLSprite(graph.xPos, graph.yPos, Std.int(graph._width), Std.int(graph._rectHeight), graph);
		FlxSpriteUtil.drawRect(graphSprite, 0, 0, graphSprite.width, graphSprite.height, FlxColor.TRANSPARENT, {thickness: 1.5, color: FlxColor.WHITE});

		graphSprite.scrollFactor.set();
		graphSprite.alpha = 0;

		add(graphSprite);

		var legitTimings:Bool = true;
		for (rating in Ratings.timingWindows)
		{
			if (rating.timingWindow != rating.defaultTimingWindow)
			{
				legitTimings = false;
				break;
			}
		}

		superMegaConditionShit = legitTimings
			&& !PlayState.usedBot
			&& !FlxG.save.data.practice
			&& PlayStateChangeables.holds
			&& !PlayState.wentToChartEditor
			&& HelperFunctions.truncateFloat(PlayStateChangeables.healthGain, 2) <= 1
			&& HelperFunctions.truncateFloat(PlayStateChangeables.healthLoss, 2) >= 1;

		if (PlayState.SONG.validScore && superMegaConditionShit)
		{
			Highscore.saveScore(PlayState.SONG.songId, Math.round(PlayState.instance.songScore), PlayState.storyDifficulty, PlayState.instance.songMultiplier);
			Highscore.saveCombo(PlayState.SONG.songId, Ratings.GenerateLetterRank(PlayState.instance.accuracy), PlayState.storyDifficulty,
				PlayState.instance.songMultiplier);
			Highscore.saveAcc(PlayState.SONG.songId, HelperFunctions.truncateFloat(PlayState.instance.accuracy, 2), PlayState.storyDifficulty,
				PlayState.instance.songMultiplier);
			Highscore.saveLetter(PlayState.SONG.songId, Ratings.GenerateLetterRank(PlayState.instance.accuracy), PlayState.storyDifficulty,
				PlayState.instance.songMultiplier);
		}

		mean = HelperFunctions.truncateFloat(mean / PlayState.instance.playerNotes, 2);
		var acceptShit:String = (superMegaConditionShit && FlxG.save.data.accuracyMod == 0 ? 'Accepted' : 'Rejected');

		if (!PlayStateChangeables.modchart #if FEATURE_LUAMODCHART
			&& FileSystem.exists(Paths.lua('songs/${PlayState.SONG.songId}/modchart')) #else && PlayState.instance.sourceModchart #end)
			acceptShit = 'Rejected';

		#if debug
		acceptShit = 'Debug';
		#end

		if (PlayState.isStoryMode)
			acceptShit = 'Rejected | Not In Freeplay Mode';

		settingsText.text = 'Mean: ${mean}ms \nJudgement config: (';
		var reverseWins = Ratings.timingWindows.copy();
		reverseWins.reverse();
		for (i in 0...reverseWins.length)
		{
			var timing = reverseWins[i];
			settingsText.text += '${timing.name.toUpperCase()}:${timing.timingWindow}ms';
			if (i != reverseWins.length - 1)
				settingsText.text += ',';
		}
		settingsText.text += ')\nStatus: $acceptShit';

		add(settingsText);

		FlxTween.tween(background, {alpha: 0.5}, 0.5);
		if (!PlayState.isStoryMode)
		{
			FlxTween.tween(songText, {y: 65}, 0.5, {ease: FlxEase.expoInOut});
			FlxTween.tween(activeMods, {y: FlxG.height - 400}, 0.5, {ease: FlxEase.expoInOut});
		}
		FlxTween.tween(text, {y: 20}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(comboText, {y: 145}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(contText, {y: FlxG.height - 45}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(settingsText, {y: FlxG.height - 65}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(graphSprite, {alpha: 1}, 1, {ease: FlxEase.expoInOut});

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}

	public function registerHit(note:NoteDef, isMiss:Bool = false)
	{
		var noteRating = note.rating;

		var noteDiff = note.strumTime - Conductor.songPosition;

		if (isMiss)
			noteDiff = Ratings.timingWindows[0].timingWindow;

		if (PlayStateChangeables.botPlay)
			noteDiff = 0;
		// judgement

		var strumTime = note.strumTime;

		if (noteDiff != Ratings.timingWindows[0].timingWindow)
			mean += noteDiff;

		graph.addToHistory(noteDiff, noteRating, strumTime);
	}

	var frames = 0;

	override function update(elapsed:Float)
	{
		#if !cpp
		if (music != null)
			if (music.volume < 0.5)
				music.volume += 0.01 * elapsed;
		#end

		// keybinds

		if ((PlayerSettings.player1.controls.ACCEPT && !FlxG.keys.pressed.ALT) || FlxG.mouse.pressed)
		{
			#if !cpp
			if (music != null)
				music.fadeOut(0.3);
			#end

			PlayState.loadRep = false;

			if (PlayState.isStoryMode)
			{
				FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "ke_freakyMenu" : "freakyMenu"));
				Conductor.changeBPM(102);
				MusicBeatState.switchState(new MainMenuState());
			}
			else
			{
				Conductor.changeBPM(102);
				MusicBeatState.switchState(new FreeplayState());
			}
		}

		if (FlxG.keys.justPressed.F1 && !PlayState.loadRep)
		{
			PlayState.loadRep = false;

			#if !cpp
			if (music != null)
				music.fadeOut(0.3);
			#end

			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = PlayState.storyDifficulty;
			LoadingState.loadAndSwitchState(new PlayState());
		}

		super.update(elapsed);
	}

	override function destroy()
	{
		instance = null;
		graph.destroy();
		graph = null;
		graphSprite.destroy();
		super.destroy();
	}

	private function refresh()
	{
	}
}
