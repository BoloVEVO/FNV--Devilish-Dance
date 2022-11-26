import flixel.input.gamepad.FlxGamepad;
import openfl.Lib;
import flixel.FlxG;

class KadeEngineData
{
	public static function initSave()
	{
		if (FlxG.save.data.weekUnlocked == null)
			FlxG.save.data.weekUnlocked = 7;

		if (FlxG.save.data.newInput == null)
			FlxG.save.data.newInput = true;

		if (FlxG.save.data.downscroll == null)
			FlxG.save.data.downscroll = false;

		if (FlxG.save.data.autoSaveChart == null)
			FlxG.save.data.autoSaveChart = false;
		if (FlxG.save.data.hitSound == null)
			FlxG.save.data.hitSound = 0;

		if (FlxG.save.data.hitVolume == null)
			FlxG.save.data.hitVolume = 0.5;

		if (FlxG.save.data.antialiasing == null)
			FlxG.save.data.antialiasing = true;

		if (FlxG.save.data.missSounds == null)
			FlxG.save.data.missSounds = true;

		if (FlxG.save.data.dfjk == null)
			FlxG.save.data.dfjk = false;

		if (FlxG.save.data.accuracyDisplay == null)
			FlxG.save.data.accuracyDisplay = true;

		if (FlxG.save.data.offset == null)
			FlxG.save.data.offset = 0;

		if (FlxG.save.data.songPosition == null)
			FlxG.save.data.songPosition = true;

		if (FlxG.save.data.fps == null)
			FlxG.save.data.fps = true;

		if (FlxG.save.data.memoryDisplay == null)
			FlxG.save.data.memoryDisplay = true;

		if (FlxG.save.data.lerpScore == null)
			FlxG.save.data.lerpScore = false;

		if (FlxG.save.data.rotateSprites == null)
			FlxG.save.data.rotateSprites = true;

		if (FlxG.save.data.fpsRain == null)
			FlxG.save.data.fpsRain = false;

		if (FlxG.save.data.fpsCap == null)
			FlxG.save.data.fpsCap = 120;

		if (FlxG.save.data.fpsCap < 60)
			FlxG.save.data.fpsCap = 120; // baby proof so you can't hard lock ur copy of kade engine

		if (FlxG.save.data.scrollSpeed == null)
			FlxG.save.data.scrollSpeed = 1;

		if (FlxG.save.data.npsDisplay == null)
			FlxG.save.data.npsDisplay = true;

		if (FlxG.save.data.frames == null)
			FlxG.save.data.frames = 10;

		if (FlxG.save.data.accuracyMod == null)
			FlxG.save.data.accuracyMod = 1;

		if (FlxG.save.data.watermark == null)
			FlxG.save.data.watermark = true;

		if (FlxG.save.data.ghost == null)
			FlxG.save.data.ghost = true;

		if (FlxG.save.data.distractions == null)
			FlxG.save.data.distractions = true;

		if (FlxG.save.data.colour == null)
			FlxG.save.data.colour = true;

		if (FlxG.save.data.stepMania == null)
			FlxG.save.data.stepMania = false;

		if (FlxG.save.data.flashing == null)
			FlxG.save.data.flashing = true;

		if (FlxG.save.data.resetButton == null)
			FlxG.save.data.resetButton = false;

		if (FlxG.save.data.InstantRespawn == null)
			FlxG.save.data.InstantRespawn = false;

		if (FlxG.save.data.botplay == null)
			FlxG.save.data.botplay = false;

		if (FlxG.save.data.cpuStrums == null)
			FlxG.save.data.cpuStrums = true;

		if (FlxG.save.data.strumline == null)
			FlxG.save.data.strumline = false;

		if (FlxG.save.data.customStrumLine == null)
			FlxG.save.data.customStrumLine = 0;

		if (FlxG.save.data.camzoom == null)
			FlxG.save.data.camzoom = true;

		if (FlxG.save.data.scoreScreen == null)
			FlxG.save.data.scoreScreen = true;

		if (FlxG.save.data.inputShow == null)
			FlxG.save.data.inputShow = false;

		if (FlxG.save.data.optimize == null)
			FlxG.save.data.optimize = false;

		if (FlxG.save.data.discordMode == null)
			FlxG.save.data.discordMode = 1;

		if (FlxG.save.data.roundAccuracy == null)
			FlxG.save.data.roundAccuracy = false;

		FlxG.save.data.cacheImages = false;

		if (FlxG.save.data.middleScroll == null)
			FlxG.save.data.middleScroll = false;

		if (FlxG.save.data.editorBG == null)
			FlxG.save.data.editor = false;

		if (FlxG.save.data.zoom == null)
			FlxG.save.data.zoom = 1;

		if (FlxG.save.data.judgementCounter == null)
			FlxG.save.data.judgementCounter = true;

		if (FlxG.save.data.laneUnderlay == null)
			FlxG.save.data.laneUnderlay = true;

		if (FlxG.save.data.healthBar == null)
			FlxG.save.data.healthBar = true;

		if (FlxG.save.data.laneTransparency == null)
			FlxG.save.data.laneTransparency = 0;

		if (FlxG.save.data.shitMs == null)
			FlxG.save.data.shitMs = 160.0;

		if (FlxG.save.data.badMs == null)
			FlxG.save.data.badMs = 135.0;

		if (FlxG.save.data.goodMs == null)
			FlxG.save.data.goodMs = 90.0;

		if (FlxG.save.data.sickMs == null)
			FlxG.save.data.sickMs = 45.0;

		Ratings.timingWindows = [
			FlxG.save.data.shitMs,
			FlxG.save.data.badMs,
			FlxG.save.data.goodMs,
			FlxG.save.data.sickMs
		];

		if (FlxG.save.data.background == null)
			FlxG.save.data.background = true;

		if (FlxG.save.data.noteskin == null)
			FlxG.save.data.noteskin = 0;

		if (FlxG.save.data.hgain == null)
			FlxG.save.data.hgain = 1;

		if (FlxG.save.data.hloss == null)
			FlxG.save.data.hloss = 1;

		if (FlxG.save.data.hdrain == null)
			FlxG.save.data.hdrain = false;

		if (FlxG.save.data.sustains == null)
			FlxG.save.data.sustains = true;

		if (FlxG.save.data.noMisses == null)
			FlxG.save.data.noMisses = false;

		if (FlxG.save.data.modcharts == null)
			FlxG.save.data.modcharts = true;

		if (FlxG.save.data.practice == null)
			FlxG.save.data.practice = false;

		if (FlxG.save.data.opponent == null)
			FlxG.save.data.opponent = false;

		if (FlxG.save.data.mirror == null)
			FlxG.save.data.mirror = false;

		if (FlxG.save.data.noteSplashes == null)
			FlxG.save.data.noteSplashes = false;

		if (FlxG.save.data.strumHit == null)
			FlxG.save.data.strumHit = true;

		if (FlxG.save.data.showCombo == null)
			FlxG.save.data.showCombo = true;

		if (FlxG.save.data.showComboNum == null)
			FlxG.save.data.showComboNum = true;

		if (FlxG.save.data.showMs == null)
			FlxG.save.data.showMs = true;

		// Gonna make this an option on another PR
		if (FlxG.save.data.overrideNoteskins == null)
			FlxG.save.data.overrideNoteskins = false;

		if (FlxG.save.data.gpuRender == null)
		{
			#if html5
			FlxG.save.data.gpuRender = false;
			#else
			FlxG.save.data.gpuRender = true;
			#end
		}

		if (FlxG.save.data.postProcessNotes == null)
		{
			FlxG.save.data.postProcessNotes = true;
		}

		if (FlxG.save.data.volume == null)
			FlxG.save.data.volume = 1;

		if (FlxG.save.data.mute == null)
			FlxG.save.data.mute = false;

		if (FlxG.save.data.changedHitX == null)
			FlxG.save.data.changedHitX = FlxG.width * 0.55 - 135;

		if (FlxG.save.data.changedHitY == null)
			FlxG.save.data.changedHitY = FlxG.height / 2 - 50;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		KeyBinds.gamepad = gamepad != null;

		Conductor.recalculateTimings();
		PlayerSettings.player1.controls.loadKeyBinds();
		KeyBinds.keyCheck();

		if (FlxG.save.data.watermark == null)
			FlxG.save.data.watermark = true;
	}

	public static function resetModifiers():Void
	{
		FlxG.save.data.hgain = 1;
		FlxG.save.data.hloss = 1;
		FlxG.save.data.hdrain = false;
		FlxG.save.data.sustains = true;
		FlxG.save.data.noMisses = false;
		FlxG.save.data.modcharts = true;
		FlxG.save.data.practice = false;
		FlxG.save.data.opponent = false;
		FlxG.save.data.mirror = false;
	}
}
