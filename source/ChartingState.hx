package;

import SectionRender.EventRender;
import audio.AudioStreamThing;
import flixel.addons.ui.FlxUIRadioGroup;
import CoolUtil.CoolNumericStepper;
import CoolUtil.CoolText;
import flixel.addons.ui.FlxUIGroup;
import openfl.net.FileFilter;
import Song.SongMeta;
import openfl.system.System;
import lime.app.Application;
import flixel.FlxState;
#if FEATURE_FILESYSTEM
import sys.io.File;
import sys.FileSystem;
#end
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.StrNameLabel;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.addons.ui.FlxUIText;
import haxe.zip.Writer;
import Section.SwagSection;
import Song.SongData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import flixel.util.FlxSort;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.transition.FlxTransitionableState;
import openfl.Lib;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import lime.media.AudioBuffer;
import haxe.io.Bytes;
import flash.geom.Rectangle;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import flixel.util.FlxDirectionFlags;

using StringTools;

@:access(flixel.system.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState
{
	public static var _song:SongData;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;

	public static var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var camGrid:FlxCamera;
	var camHUD:FlxCamera;

	var curSelectedZoom:Int = 3;

	var zoomFactorList:Array<Float> = [0.25, 0.5, 0.75, 1, 2, 3, 4, 6, 8, 12, 16, 24];

	var strumLine:FlxSprite;

	var bpmTxt:CoolText;

	var sectionRenderes:FlxTypedGroup<SectionRender>;

	var lines:FlxTypedGroup<FlxSprite>;

	var eventRenders:FlxTypedGroup<EventRender>;

	var dummyArrow:FlxSprite;

	public static var snapToGrid:Bool = false;

	public static var snap:Int = 16;

	public static var curSnap:Int = 3;

	public static var swagSection:SwagSection;

	var strumLineNotes:FlxTypedGroup<StaticArrow>;

	public static var GRID_SIZE:Int = 40;

	var CAM_OFFSET:Int = 225;

	public var snapArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	var speed = 1.0;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	public static var currentSongName:String;

	private var typeables:Array<FlxUIInputText> = [];
	private var steppers:Array<FlxUINumericStepper> = [];
	private var dropMenus:Array<FlxUIDropDownMenu> = [];

	var camPos:FlxObject;

	var instStream:AudioStreamThing;

	var vocalsStream:AudioStreamThing;

	var blockInput:Bool = false;

	public static var lastSongPos:Float = 0;

	override function create()
	{
		camGrid = new FlxCamera();
		camGrid.bgColor.alpha = 0;
		camGrid.zoom = 1;
		FlxG.cameras.reset(camGrid);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		bpmTxt = new CoolText(150, 50, 16, 16, Paths.bitmapFont('fonts/vcr'));
		bpmTxt.autoSize = true;
		bpmTxt.antialiasing = true;
		bpmTxt.updateHitbox();
		bpmTxt.scrollFactor.set();
		bpmTxt.camera = camHUD;
		add(bpmTxt);

		if (PlayState.SONG != null)
		{
			if (PlayState.isSM)
			{
				#if FEATURE_STEPMANIA
				_song = Song.conversionChecks(Song.loadFromJsonRAW(File.getContent(PlayState.pathToSm + "/converted.json")));
				#end
			}
			else
			{
				_song = PlayState.SONG;
			}
		}
		else
		{
			_song = {
				chartVersion: "KE2",
				songId: 'test',
				songName: 'Test',
				notes: [newSection(16, true, false, false)],
				eventObjects: [],
				bpm: 95,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				noteStyle: 'normal',
				stage: 'stage',
				speed: 1,
				validScore: false
			};
		}

		if (_song.eventObjects == null)
			_song.eventObjects = [new Song.Event("Init BPM", 0, _song.bpm, "BPM Change")];

		if (_song.eventObjects.length == 0)
			_song.eventObjects = [new Song.Event("Init BPM", 0, _song.bpm, "BPM Change")];

		#if desktop
		PlayState.setupMusicStream();
		#end

		leCroissant = ((60 / _song.bpm) * 1000) / 4;

		setSongTimings();
		recalculateAllSectionTimes();

		Debug.logTrace("goin");

		instStream = PlayState.instStream;
		vocalsStream = PlayState.vocalsStream;

		if (_song.chartVersion == null)
			_song.chartVersion = "KE2";

		swagSection = getSectionByTime(0);
		curSection = 0;
		lastSection = 0;
		lastSongPos = 0;
		currentSongName = _song.songId;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

		sectionRenderes = new FlxTypedGroup<SectionRender>();
		sectionRenderes.camera = camGrid;
		add(sectionRenderes);
		reloadSectionRender();

		updateRenderProperties();

		lines = new FlxTypedGroup<FlxSprite>();
		lines.camera = camGrid;
		add(lines);
		loadSectionLines();

		eventRenders = new FlxTypedGroup<EventRender>();
		eventRenders.camera = camGrid;
		add(eventRenders);

		reloadEventObjects();
		updateEventObjectY();

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 8), 4);
		strumLine.camera = camGrid;
		add(strumLine);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		FlxG.camera.follow(camPos);

		add(instStream);
		add(vocalsStream);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		#if desktop
		Conductor.songPosition = instStream.time;
		#end

		if (curTiming != null)
		{
			var timingSegBpm = curTiming.bpm;

			if (timingSegBpm != Conductor.bpm)
			{
				Debug.logInfo("BPM CHANGE to " + timingSegBpm);
				Conductor.changeBPM(timingSegBpm);
				recalculateAllSectionTimes();
			}
		}

		#if desktop
		swagSection = getSectionByTime(Conductor.songPosition);
		#end

		if (_song.notes[curSection + 1] == null)
		{
			Debug.logTrace('OMG NULL SECTION, ADDING NEW SECTION YAY');
			_song.notes.push(newSection(16, true, false, false));
			//
		}

		curSection = _song.notes.indexOf(swagSection);

		for (render in sectionRenderes)
		{
			var index = sectionRenderes.members.indexOf(render);
			if (render.section == null)
			{
				render.visible = false;

				lines.members[index].visible = false;
			}
			else
			{
				render.visible = true;
				lines.members[index].visible = true;
			}
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			#if desktop
			if (instStream.playing)
			{
				instStream.pause();
				if (vocalsStream != null)
					vocalsStream.pause();
			}
			else
			{
				if (vocalsStream != null)
				{
					vocalsStream.play();
					vocalsStream.pause();

					vocalsStream.play();
				}
				instStream.play();
			}
			#end
		}

		#if desktop
		if (instStream.time >= instStream.length - 85)
		{
			instStream.time = 0;
			vocalsStream.time = 0;
			Conductor.songPosition = 0;
			swagSection = getSectionByTime(0);

			instStream.pause();
			vocalsStream.pause();

			vocalsStream.pause();

			setSongTimings();
			recalculateAllSectionTimes();
		}
		#end

		if (!blockInput)
		{
			if (controls.BACK)
			{
				LoadingState.loadAndSwitchState(new PlayState());

				lastSongPos = Conductor.songPosition;
				Debug.logInfo(lastSongPos);
			}

			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.mouse.wheel > 0 && curSelectedZoom < zoomFactorList.length - 1)
				{
					curSelectedZoom++;

					reloadSectionRender();
					updateRenderProperties();
					updateSectionLinesProperties();
				}
				if (FlxG.mouse.wheel < 0 && curSelectedZoom > 0)
				{
					curSelectedZoom--;

					reloadSectionRender();
					updateRenderProperties();
					updateSectionLinesProperties();
				}
			}
		}

		#if desktop
		if (FlxG.mouse.wheel != 0)
		{
			instStream.pause();
			vocalsStream.pause();
			instStream.time -= Std.int(FlxG.mouse.wheel * Conductor.stepCrochet * 0.8);
			if (vocalsStream != null)
				vocalsStream.time = instStream.time;
		}
		#end

		strumLineUpdateY();
		updateEventObjectY();

		#if desktop
		bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(instStream.length / 1000, 2))
			+ "\nCur Section: "
			+ curSection
			+ "\nCurBeat: "
			+ HelperFunctions.truncateFloat(curDecimalBeat, 3)
			+ "\nCurStep: "
			+ curStep
			+ "\nZoom: "
			+ HelperFunctions.truncateFloat(zoomFactorList[curSelectedZoom], 2);
		#end
		bpmTxt.updateHitbox();

		camPos.y = strumLine.y;

		super.update(elapsed);

		if (curSection != lastSection)
		{
			Debug.logInfo('Current Section: $curSection');
			updateSectionLinesProperties();
			updateRenderProperties();

			lastSection = curSection;
		}
	}

	function reloadEventObjects()
	{
		while (eventRenders.members.length > 0)
		{
			if (eventRenders.members[0] != null)
				eventRenders.members[0].destroy();
			eventRenders.members.remove(eventRenders.members[0]);
		}

		if (_song.eventObjects != null)
			for (i in _song.eventObjects)
			{
				// Figured it out, it took me a fucking week!

				var eventTime = TimingStruct.getTimeFromLastTimingAtBeat(0, i.position);

				var type = i.type;

				var eventRender = new EventRender(0, 0, i.name, type, i.value, eventTime);

				eventRenders.add(eventRender);
			}
	}

	private function updateEventObjectY()
	{
		for (eventRender in eventRenders)
		{
			if (sectionRenderes.members[3].section == swagSection)
				eventRender.y = getYfromStrumNotes(eventRender.eventTime) - (GRID_SIZE * 16 * curSection * zoomFactorList[curSelectedZoom]);
		}
	}

	private function getSectionFromBeat(beat:Float):SwagSection
	{
		for (i in _song.notes)
		{
			var start = TimingStruct.getTimeFromBeat(beat);

			if (start >= i.startTime && start < i.endTime)
			{
				return i;
			}
		}
		return null;
	}

	private function setSongTimings()
	{
		TimingStruct.clearTimings();
		curTiming = null;
		var currentIndex = 0;
		for (i in _song.eventObjects)
		{
			var name = Reflect.field(i, "name");
			var type = Reflect.field(i, "type");
			var pos = Reflect.field(i, "position");
			var value = Reflect.field(i, "value");

			if (type == "BPM Change")
			{
				var beat:Float = pos;

				var endBeat:Float = Math.POSITIVE_INFINITY;

				TimingStruct.addTiming(beat, value, endBeat, 0); // offset in this case = start time since we don't have a offset

				Debug.logInfo('Loading BPM CHANGE $value');

				if (currentIndex != 0)
				{
					var data = TimingStruct.AllTimings[currentIndex - 1];
					data.endBeat = beat;
					data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
					var step = ((60 / data.bpm) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
				}

				currentIndex++;
			}
		}
	}

	private function reloadSectionRender()
	{
		for (render in sectionRenderes.members)
		{
			if (render != null)
				render.destroy();
		}
		sectionRenderes.clear();
		for (i in 0...7)
		{
			var render:SectionRender = new SectionRender(0, -1920, GRID_SIZE,
				Std.int(GRID_SIZE * swagSection.lengthInSteps * zoomFactorList[curSelectedZoom]));
			render.y += render.height * i;

			sectionRenderes.add(render);
			Debug.logInfo('Render added');
		}
	}

	private function updateRenderProperties()
	{
		for (i in 0...7)
		{
			var leSection = [
				curSection - 3,
				curSection - 2,
				curSection - 1,
				curSection,
				curSection + 1,
				curSection + 2,
				curSection + 3
			]; // STFU RUDY I'M DUMB

			sectionRenderes.members[i].section = _song.notes[leSection[i]];
			if (sectionRenderes.members[i].section != null)
				sectionRenderes.members[i].mustHit = sectionRenderes.members[i].section.mustHitSection;
		}
	}

	private function loadSectionLines()
	{
		for (line in lines)
			if (line != null)
				line.destroy();

		lines.clear();

		for (render in sectionRenderes)
		{
			if (render != null)
			{
				var pos = (render.y + render.height);
				var line = new FlxSprite(0, pos).makeGraphic(Std.int(GRID_SIZE * 8), 4, FlxColor.ORANGE);
				line.camera = camGrid;
				lines.add(line);
			}
		}
	}

	private function updateSectionLinesProperties()
	{
		for (i in 0...7)
			if (lines.members[i] != null && sectionRenderes.members[i] != null)
				lines.members[i].y = (sectionRenderes.members[i].y + sectionRenderes.members[i].height);
	}

	private function newSection(lengthInSteps:Int = 16, mustHitSection:Bool = false, CPUAltAnim:Bool = true, playerAltAnim:Bool = true):SwagSection
	{
		var daPos:Float = 0;

		var currentSeg = TimingStruct.AllTimings[TimingStruct.AllTimings.length - 1];

		var currentBeat = 4;

		for (i in _song.notes)
			currentBeat += 4;

		if (currentSeg == null)
			return null;

		var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);

		daPos = (currentSeg.startTime + start) * 1000;

		var sec:SwagSection = {
			startTime: daPos,
			endTime: Math.POSITIVE_INFINITY,
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: mustHitSection,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			CPUAltAnim: CPUAltAnim,
			playerAltAnim: playerAltAnim
		};

		return sec;
	}

	function recalculateAllSectionTimes()
	{
		Debug.logTrace("RECALCULATING SECTION TIMES");

		var savedNotes:Array<Dynamic> = [];

		for (i in 0..._song.notes.length) // loops through sections
		{
			var section = _song.notes[i];

			var currentBeat = 4 * i;

			var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);

			if (currentSeg == null)
				return;

			var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);

			section.startTime = (currentSeg.startTime + start) * 1000;

			if (i != 0)
				_song.notes[i - 1].endTime = section.startTime;
			section.endTime = Math.POSITIVE_INFINITY;
		}
	}

	private function getSectionByTime(ms:Float):SwagSection
	{
		for (i in _song.notes)
		{
			if (ms >= i.startTime && ms < i.endTime)
			{
				return i;
			}
		}

		return null;
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, sectionRenderes.members[3].y, sectionRenderes.members[3].y + sectionRenderes.members[3].height, 0,
			16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, sectionRenderes.members[3].y,
			sectionRenderes.members[3].y + sectionRenderes.members[3].height * zoomFactorList[curSelectedZoom]);
	}

	var leCroissant:Float = 0.0;

	function getYfromStrumNotes(strumTime:Float):Float
	{
		/*Debug.logInfo(timing.bpm);
			Debug.logInfo('${Conductor.stepCrochet} | ${leCroissant}'); */

		var value:Float = strumTime / (16 * leCroissant);
		return GRID_SIZE * 16 * zoomFactorList[curSelectedZoom] * value + sectionRenderes.members[3].y;
	}

	function strumLineUpdateY()
	{
		if (sectionRenderes.members[3].section != null)
			strumLine.y = getYfromStrum((Conductor.songPosition - sectionRenderes.members[3].section.startTime) / zoomFactorList[curSelectedZoom] % (Conductor.stepCrochet * 16));
	}
}
