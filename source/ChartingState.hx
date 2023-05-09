package;

import SectionRender.SustainRender;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import flixel.util.FlxDestroyUtil;
import SectionRender.BeatLineRender;
import flixel.addons.ui.FlxUIBar;
import SectionRender.EventRender;
import audio.AudioStream;
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
import flixel.util.FlxPool;
import ChartEventHandler.ChartEvent;
import ChartEventHandler.ChartEventInfo;
import openfl.events.MouseEvent;
import flixel.util.FlxCollision;

using StringTools;

/*
	** Charting State rewritten from scratch using original kade engine code avoiding most of memory leaks and bugs.
 */
class ChartingState extends MusicBeatState
{
	public static var _song:SongData = null;

	var curRenderedSustains:FlxTypedGroup<SustainRender> = null;
	var curRenderedNotes:FlxTypedGroup<NoteSpr> = null;

	var noteSelectBoxes:FlxTypedGroup<ChartingBox> = null;

	var unspawnNotes:Array<NoteDef> = [];

	var unspawnSustains:Array<SustainRender> = [];

	var camGame:FlxCamera;
	var camGrid:FlxCamera;
	var camHUD:FlxCamera;

	var curSelectedZoom:Int = 7;

	var zoomFactorList:Array<Float> = [
		0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1, 2, 3, 4, 6, 8, 12, 16, 24
	];

	var strumLine:FlxSprite = null;

	var bpmTxt:CoolText;

	var ibeatLines:Array<BeatLineRender> = [];
	var beatLines:FlxTypedGroup<BeatLineRender>;

	var eventRenders:FlxTypedGroup<EventRender>;

	var ieventsRenders:Array<EventRender> = [];

	var dummyArrow:FlxSprite;

	public static var snapToGrid:Bool = false;

	public static var snap:Int = 16;

	public static var curSnap:Int = 3;

	var strumLineNotes:FlxTypedGroup<StaticArrow> = null;

	public static var GRID_SIZE:Int = 40;

	var CAM_OFFSET:Int = 165;

	var STRUM_OFFSET:Int = 100;

	public var snapArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	var speed = 1.0;

	var leftIcon:HealthIcon = null;
	var rightIcon:HealthIcon = null;

	var uiTabMenuPrimary:FlxUITabMenu;
	var uiTabMenuSecondary:FlxUITabMenu;

	var camHUD2:FlxCamera;

	public static var currentSongName:String;

	private var typeables:Array<FlxUIInputText> = [];
	private var steppers:Array<FlxUINumericStepper> = [];
	private var dropMenus:Array<FlxUIDropDownMenu> = [];

	var charList:Array<String> = [];

	var stageList:Array<String> = [];

	var camPos:FlxObject;

	var instStream:AudioStream = null;

	var vocalsStream:AudioStream = null;

	var blockInput:Bool = false;

	var snapped:Bool = true;

	var getSection:Bool = true;

	public static var mustCleanMem:Bool = false;

	public var susPool:FlxPool<SustainRender> = null;

	public var chartEventHandler:ChartEventHandler = null;

	var freeOverlap:Bool = true;

	public static var instance:ChartingState = null;

	override function create()
	{
		persistentUpdate = persistentDraw = true;
		if (mustCleanMem)
		{
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
			mustCleanMem = false;
		}

		instance = this;

		chartEventHandler = new ChartEventHandler(true, null);

		camGame = new FlxCamera();
		camGame.bgColor.alpha = 0;
		camGame.zoom = 1;
		FlxG.cameras.reset(camGame);

		camGrid = new FlxCamera();
		camGrid.bgColor.alpha = 0;
		camGrid.zoom = 1;
		FlxG.cameras.add(camGrid);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camHUD2 = new FlxCamera();
		camHUD2.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD2, false);

		bpmTxt = new CoolText(150, FlxG.height - 72, 16, 16, Paths.bitmapFont('fonts/vcr'));

		bpmTxt.autoSize = true;
		bpmTxt.antialiasing = true;
		bpmTxt.updateHitbox();
		bpmTxt.scrollFactor.set();
		bpmTxt.camera = camHUD;

		var textBG = new FlxSprite(0, bpmTxt.y - 13).makeGraphic(Std.int(FlxG.width), 45, FlxColor.BLACK);
		textBG.alpha = 0.5;
		textBG.camera = camHUD;
		add(textBG);
		add(bpmTxt);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		dummyArrow.camera = camGrid;
		dummyArrow.alpha = 0.5;

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
				events: [],
				bpm: 95,
				needsVoices: true,
				songStyle: 'default',
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				noteStyle: 'normal',
				stage: 'stage',
				speed: 1,
				validScore: false
			};
		}

		curDiff = CoolUtil.difficultyArray[PlayState.storyDifficulty];

		if (_song.events == null || _song.events.length == 0)
		{
			var initBPM:ChartEvent = {name: "changeBPM", beat: 0, args: [_song.bpm]};
			_song.events = [initBPM];
		}

		#if desktop
		PlayState.setupMusicStream();
		#end

		activeSong = _song;

		Debug.logTrace("goin");

		instStream = PlayState.instStream;
		vocalsStream = PlayState.vocalsStream;

		#if desktop
		instStream.play();
		instStream.pause();

		instStream.time = 0;
		#end

		setSongTimings();

		currentSection = getSectionByTime(0);

		recalculateAllSectionTimes();
		calculateMaxBeat();
		checkforSections();

		if (_song.chartVersion == null)
			_song.chartVersion = "KE2";

		currentSongName = _song.songId;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.camera = camGame;
		bg.color = 0xFF222222;
		add(bg);

		var bgGrid = new FlxSprite(475, 0).makeGraphic(Std.int(GRID_SIZE * 8), FlxG.height, FlxColor.BLACK);
		bgGrid.alpha = 0.7;
		bgGrid.scrollFactor.set(0, 0);
		bgGrid.camera = camGrid;
		add(bgGrid);

		var middleLine = new FlxSprite((bgGrid.x + bgGrid.width / 2) - 1.5, 0).makeGraphic(2, FlxG.height, FlxColor.WHITE);
		middleLine.scrollFactor.set(0, 0);
		middleLine.camera = camGrid;

		var leftIcon = new HealthIcon(_song.player2);

		leftIcon.setGraphicSize(Std.int(leftIcon.initialWidth * 0.5));
		leftIcon.scrollFactor.set(0, 0);
		leftIcon.updateHitbox();
		leftIcon.camera = camGrid;
		leftIcon.x = bgGrid.x + 50;

		var rightIcon = new HealthIcon(_song.player1);

		rightIcon.setGraphicSize(Std.int(rightIcon.initialWidth * 0.5));
		rightIcon.flipX = true;
		rightIcon.scrollFactor.set(0, 0);
		rightIcon.updateHitbox();
		rightIcon.camera = camGrid;

		rightIcon.x = bgGrid.x + (bgGrid.width / 2) + 45;

		leftIcon.y = rightIcon.y = FlxG.height - 700;

		noteSelectBoxes = new FlxTypedGroup<ChartingBox>();
		noteSelectBoxes.camera = camGrid;

		curRenderedSustains = new FlxTypedGroup<SustainRender>();

		curRenderedSustains.camera = camGrid;

		curRenderedNotes = new FlxTypedGroup<NoteSpr>();
		curRenderedNotes.camera = camGrid;

		generateNotes();
		updateNotes();
		updateSustains();
		updateSusProps();

		add(noteSelectBoxes);
		add(curRenderedSustains);
		add(curRenderedNotes);

		beatLines = new FlxTypedGroup<BeatLineRender>();
		beatLines.camera = camGrid;
		add(beatLines);

		setupLines();
		updateLines();
		checkSectionLines();

		eventRenders = new FlxTypedGroup<EventRender>();
		eventRenders.camera = camGrid;
		add(eventRenders);

		generateEvents();

		add(dummyArrow);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 8), 4);
		strumLine.camera = camGrid;
		add(strumLine);

		camPos = new FlxObject(0, 0, 1, 1);

		var offStrum = STRUM_OFFSET;
		if (FlxG.save.data.downscroll)
			offStrum = -STRUM_OFFSET;

		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y + offStrum);

		camGrid.follow(camPos);

		add(instStream);
		add(vocalsStream);

		var tabs = [
			{name: "Song", label: 'Song Data'},
			{name: "Song Section", label: 'Section Data'},
			{name: "Song Sevents", label: 'Events'},
			{name: "Song SMeta", label: 'Meta'}
		];

		add(leftIcon);
		add(rightIcon);
		add(middleLine);

		uiTabMenuPrimary = new FlxUITabMenu(null, tabs, true);
		uiTabMenuPrimary.resize(300, 400);
		uiTabMenuPrimary.x = FlxG.width / 2 + 200;
		uiTabMenuPrimary.y = 20;
		uiTabMenuPrimary.camera = camHUD;
		add(uiTabMenuPrimary);

		var editor_tabs = [
			{name: "Editor Settings", label: 'Editor Settings'},
			{name: "Hotkeys", label: 'Hotkeys'},

		];

		uiTabMenuSecondary = new FlxUITabMenu(null, editor_tabs, true);
		uiTabMenuSecondary.resize(300, 400);
		uiTabMenuSecondary.x = 80;
		uiTabMenuSecondary.y = 20;
		uiTabMenuSecondary.camera = camHUD2;
		add(uiTabMenuSecondary);

		listAssets();
		if (!PlayState.isSM)
			scanDifficulties(_song.songId);
		addPrimaryUI();
		addSectionUI();
		addEventsUI();
		addEditorOptionsUI();

		super.create();
	}

	override public function update(elapsed:Float)
	{#if desktop Conductor.songPosition = instStream.time; #end

		var accept = FlxG.keys.justPressed.ENTER;

		if (curDecimalBeat < 0)
			curDecimalBeat = 0;

		var currentSeg = TimingStruct.getTimingAtBeat(curDecimalBeat);
		if (currentSeg != null)
		{
			var timingSegBpm = currentSeg.bpm;

			if (timingSegBpm != Conductor.bpm)
			{
				Debug.logInfo("BPM CHANGE to " + timingSegBpm);
				Conductor.changeBPM(timingSegBpm);
				recalculateAllSectionTimes();
			}
		}

		/*if (_song.notes[curSection + 1] == null)
			{
				Debug.logInfo('OMG NULL SECTION, ADDING NEW SECTION YAY');
				_song.notes.push(newSection(16, true, false, false));
				recalculateAllSectionTimes();
				checkSectionLines();
		}*/

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
					if (vocalsStream.length >= instStream.time)
					{
						vocalsStream.play();
						vocalsStream.pause();

						vocalsStream.play();
					}
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

			instStream.pause();
			vocalsStream.pause();

			vocalsStream.pause();

			setSongTimings();
			recalculateAllSectionTimes();
		}
		#end

		if (!blockInput)
		{
			if (accept)
				LoadingState.loadAndSwitchState(new PlayState());

			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.mouse.wheel > 0 && curSelectedZoom < zoomFactorList.length - 1)
				{
					curSelectedZoom++;
					resizeSustains();
				}
				if (FlxG.mouse.wheel < 0 && curSelectedZoom > 0)
				{
					curSelectedZoom--;
					resizeSustains();
				}
			}
		}

		#if desktop
		if (!FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.mouse.wheel != 0)
			{
				instStream.pause();
				vocalsStream.pause();
				if (!snapped)
				{
					var leWheel = FlxG.save.data.downscroll ? -FlxG.mouse.wheel : FlxG.mouse.wheel;

					instStream.time -= Std.int(leWheel * 25);

					if (instStream.time < 0)
						instStream.time = 0;
				}

				if (snapped)
				{
					#if desktop
					var beat:Float = TimingStruct.getBeatFromTime(Conductor.songPosition);
					var snap:Float = snapArray[curSnap] / 4;
					var increase:Float = 1 / snap;
					var wheelShit = FlxG.save.data.downscroll?FlxG.mouse.wheel<0:FlxG.mouse.wheel>0;

					if (wheelShit)
					{
						var fuck:Float = (Math.fround(beat * snap) / snap) - increase;
						if (fuck < 0)
							fuck = 0;
						var data = TimingStruct.getTimingAtBeat(fuck);
						var lastDataIndex = TimingStruct.AllTimings.indexOf(data) - 1;
						if (lastDataIndex < 0)
							lastDataIndex = 0;

						var lastData = TimingStruct.AllTimings[lastDataIndex];

						var pog = 0.0;
						var shitPosition = 0.0;

						if (beat < data.startBeat)
						{
							pog = (fuck - lastData.startBeat) / (lastData.bpm / 60);
							shitPosition = (lastData.startTime + pog) * 1000;
						}
						else if (beat > data.startBeat)
						{
							pog = (fuck - data.startBeat) / (data.bpm / 60);
							shitPosition = (data.startTime + pog) * 1000;
						}
						else
						{
							pog = fuck / (Conductor.bpm / 60);
							shitPosition = pog * 1000;
						}

						instStream.time = shitPosition;
					}
					else
					{
						var fuck:Float = (Math.fround(beat * snap) / snap) + increase;
						if (fuck < 0)
							fuck = 0;
						var data = TimingStruct.getTimingAtBeat(fuck);
						var lastDataIndex = TimingStruct.AllTimings.indexOf(data) - 1;
						if (lastDataIndex < 0)
							lastDataIndex = 0;

						var lastData = TimingStruct.AllTimings[lastDataIndex];

						var pog = 0.0;
						var shitPosition = 0.0;
						if (beat < data.startBeat)
						{
							pog = (fuck - lastData.startBeat) / (lastData.bpm / 60);
							shitPosition = (lastData.startTime + pog) * 1000;
						}
						else if (beat > data.startBeat)
						{
							pog = (fuck - data.startBeat) / (data.bpm / 60);
							shitPosition = (data.startTime + pog) * 1000;
						}
						else
						{
							pog = fuck / (Conductor.bpm / 60);
							shitPosition = pog * 1000;
						}

						instStream.time = shitPosition;
					}
					#end
				}

				if (!(vocalsStream.length < instStream.time))
					vocalsStream.time = instStream.time;
			}
		}
		#end

		if (FlxG.mouse.getWorldPosition(dummyArrow.camera).x > 0 && FlxG.mouse.getWorldPosition(dummyArrow.camera).x < 320)
		{
			dummyArrow.visible = true;

			dummyArrow.x = Math.floor(FlxG.mouse.getWorldPosition(dummyArrow.camera).x / GRID_SIZE) * GRID_SIZE;
			var newDummyY = 0.0;

			if (snapped)
			{
				var time = 0.0;
				var rawTime = 0.0;
				var snap:Float = snapArray[curSnap];

				rawTime = getStrumTime(FlxG.mouse.getWorldPosition(dummyArrow.camera).y / zoomFactorList[curSelectedZoom]);

				if (FlxG.save.data.downscroll)
					rawTime = -rawTime;

				time = rawTime;

				var beat = TimingStruct.getBeatFromTime(time);
				var snapShit = Math.floor(beat * snap) / snap;

				newDummyY = getYfromStrum(TimingStruct.getTimeFromBeat(snapShit) * zoomFactorList[curSelectedZoom]) - (GRID_SIZE / 2);

				if (FlxG.save.data.downscroll)
					newDummyY = -newDummyY - GRID_SIZE;

				if (FlxG.save.data.downscroll)
				{
					if (newDummyY > -40)
						newDummyY = -40;
				}
				else if (newDummyY < 0)
					newDummyY = 0;

				dummyArrow.y = newDummyY;
			}
			else
			{
				newDummyY = FlxG.mouse.getWorldPosition(dummyArrow.camera).y - (GRID_SIZE / 2);

				if (FlxG.save.data.downscroll)
					newDummyY = newDummyY - GRID_SIZE;

				if (FlxG.save.data.downscroll)
				{
					if (newDummyY > -40)
						newDummyY = -40;
				}
				else if (newDummyY < 0)
					newDummyY = 0;

				dummyArrow.y = newDummyY;
			}
		}
		else
			dummyArrow.visible = false;

		if (FlxG.mouse.justPressed)
		{
			if (dummyArrow.visible)
			{
				checkGridNotes();

				if (freeOverlap)
				{
					curRenderedNotes.forEach(function(daNote:NoteSpr)
					{
						if (FlxCollision.pixelPerfectCheck(dummyArrow, daNote, 0))
						{
							deleteNote(daNote._def);
						}
					});
				}
			}
		}
		else if (FlxG.mouse.justPressedRight)
		{
			curRenderedNotes.forEach(function(daNote:NoteSpr)
			{
				if (freeOverlap)
				{
					if (FlxCollision.pixelPerfectCheck(dummyArrow, daNote, 0))
					{
						selectNote(daNote);
					}
				}
				else if (daNote._def.rawNoteData == Math.floor(FlxG.mouse.getWorldPosition(dummyArrow.camera).x / GRID_SIZE)
					&& daNote.y == dummyArrow.y)
				{
					selectNote(daNote);
				}
			});
		}

		var bpmRatio = Conductor.bpm / 100;
		camGame.zoom = FlxMath.lerp(1, camGame.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio), 0, 1));

		strumLineUpdateY();
		updateLines();
		// checkSectionLines();
		updateNotes();
		updateSustains();
		updateNoteProps();
		updateSusProps();
		updateEvents();
		// checkWaves();

		var stringBeat = Std.string(HelperFunctions.truncateFloat(curDecimalBeat, 3));
		if (stringBeat.indexOf(".") == -1)
			stringBeat += ".000";
		else if (stringBeat.split(".")[1].length == 2)
			stringBeat += "0";
		else if (stringBeat.split(".")[1].length == 1)
			stringBeat += "00";

		var stringPos = Std.string(HelperFunctions.truncateFloat(Conductor.songPosition / 1000, 3));
		if (stringPos.indexOf(".") == -1)
			stringPos += ".000";
		else if (stringPos.split(".")[1].length == 2)
			stringPos += "0";
		else if (stringPos.split(".")[1].length == 1)
			stringPos += "00";

		#if desktop
		bpmTxt.text = "BPM: "
			+ Conductor.bpm
			+ " | Snap: "
			+ snapArray[curSnap]
			+ "th | Time: "
			+ stringPos
			+ " / "
			+ Std.string(FlxMath.roundDecimal(instStream.length / 1000, 2))
			+ " | Section: "
			+ curSection
			+ " | Beat: "
			+ stringBeat
			+ " | Step: "
			+ curStep
			+ " | Zoom: "
			+ HelperFunctions.truncateFloat(zoomFactorList[curSelectedZoom], 2);
		#end

		bpmTxt.updateHitbox();
		bpmTxt.screenCenter(X);

		var offStrum = STRUM_OFFSET;
		if (FlxG.save.data.downscroll)
			offStrum = -STRUM_OFFSET;

		camPos.y = strumLine.y + offStrum;

		super.update(elapsed);
	}

	function checkforSections()
	{
		var totalBeats = maxBeat;

		var lastSecBeat = TimingStruct.getBeatFromTime(_song.notes[_song.notes.length - 1].endTime);

		while (lastSecBeat < totalBeats)
		{
			Debug.logTrace('LastBeat: $lastSecBeat | totalBeats: $totalBeats ');
			_song.notes.push(newSection(_song.notes[_song.notes.length - 1].lengthInSteps, true, false, false));
			recalculateAllSectionTimes();
			checkSectionLines();
			lastSecBeat = TimingStruct.getBeatFromTime(_song.notes[_song.notes.length - 1].endTime);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (metronomeActive)
			FlxG.sound.play(Paths.sound('Metronome_Tick'));
	}

	override function sectionHit()
	{
		super.sectionHit();

		stepsStepper.currentValue = currentSection.lengthInSteps;
		stepsStepper.inputText.text = Std.string(currentSection.lengthInSteps);
		#if cpp
		if (instStream.playing)
			camGame.zoom += 0.03;
		#end
	}

	function checkSectionLines()
	{
		for (line in ibeatLines)
		{
			var sec = getSectionByTime(line.strumTime);
			line.scale.set(1, 1);
			line.alpha = 0.5;

			if (sec != null)
			{
				if (line.strumTime == sec.startTime)
				{
					line.scale.set(1, 2);
					line.updateHitbox();
					line.alpha = 1;
				}
			}
		}
	}

	function updateLines()
	{
		if (getSection)
		{
			for (i in 0...ibeatLines.length)
			{
				var line = ibeatLines[i];
				if (line != null)
				{
					var pos = 0.0;

					if (FlxG.save.data.downscroll)
						pos = -getYfromStrum(TimingStruct.getTimeFromBeat(line.beat));
					else
						pos = getYfromStrum(TimingStruct.getTimeFromBeat(line.beat));

					line.y = pos * zoomFactorList[curSelectedZoom];
					var strumtime = TimingStruct.getTimeFromBeat(line.beat);
					var diff = strumtime - Conductor.songPosition;
					var range = [460, 290];

					if (diff <= range[0] / (zoomFactorList[curSelectedZoom]) && diff >= -range[1] / (zoomFactorList[curSelectedZoom]))
					{
						if (!line.alive)
						{
							beatLines.add(line);
							line.load();
							line.reset(0, pos * zoomFactorList[curSelectedZoom]);
						}
						line.visible = true;
						line.active = true;
					}
					else
					{
						if (line.alive)
						{
							line.graphic.dump();
							line.graphic = null;
							line.frames = null;

							beatLines.remove(line, true);
							line.kill();
						}
						line.active = false;
						line.visible = false;
					}
				}
			}
		}
	}

	var maxBeat = 0;

	function setupLines()
	{
		for (beat in beatLines)
		{
			if (beat != null)
				beat.destroy();
			beatLines.remove(beat, true);
		}

		beatLines.members.resize(0);

		beatLines.clear();

		for (beat in ibeatLines)
		{
			if (beat != null)
				beat.destroy();
		}

		ibeatLines.resize(0);

		var shitLine = new BeatLineRender(GRID_SIZE, 0);
		shitLine.load();
		beatLines.add(shitLine);

		for (i in 0...maxBeat)
		{
			var peepee = beatLines.recycle(BeatLineRender);
			peepee.beat = i;
			peepee.alpha = 0.5;
			peepee.strumTime = TimingStruct.getTimeFromBeat(peepee.beat);

			peepee.active = false;
			peepee.visible = false;

			peepee.load();

			ibeatLines.push(peepee);
		}
	}

	function calculateMaxBeat()
	{
		#if cpp
		maxBeat = Math.round(TimingStruct.getBeatFromTime(instStream.length));
		#end
	}

	function updateNoteProps()
	{
		for (i in 0...curRenderedNotes.members.length)
		{
			var note = curRenderedNotes.members[i];

			if (note != null)
			{
				note.x = Math.floor(note._def.rawNoteData * GRID_SIZE);

				if (FlxG.save.data.downscroll)
					note.y = (-getYfromStrum(note._def.strumTime) * zoomFactorList[curSelectedZoom]) - GRID_SIZE;
				else
					note.y = getYfromStrum(note._def.strumTime) * zoomFactorList[curSelectedZoom];
			}
		}
	}

	function sortByShit(Obj1:NoteDef, Obj2:NoteDef):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function generateEvents()
	{
		for (shit in ieventsRenders)
		{
			if (shit != null)
				shit.destroy();
		}

		for (otherShit in eventRenders)
			if (otherShit != null)
				otherShit.destroy();

		eventRenders.clear();

		eventRenders.members.resize(0);

		ieventsRenders.resize(0);
		var groupMap:Map<Dynamic, Array<ChartEvent>> = new Map<Dynamic, Array<ChartEvent>>();

		for (event in _song.events)
		{
			if (!groupMap.exists(event.beat))
			{
				groupMap.set(event.beat, []);
			}

			groupMap.get(event.beat).push(event);

			// Debug.logInfo('Pushing Event | Info - Name: ${eventThing.name} | Type: ${eventThing.type} | Value: ${eventThing.value} | Position: ${eventThing.beat}');
		}

		for (eventBeat in groupMap.keys())
		{
			var eventThing = new EventRender(0, 0, groupMap.get(eventBeat));
			eventThing.visible = false;
			eventThing.updateText();
			ieventsRenders.push(eventThing);
		}

		updateEvents();
	}

	function updateEvents()
	{
		for (event in ieventsRenders)
		{
			if (event != null)
			{
				var strumTime = TimingStruct.getTimeFromBeat(event.beat);
				var diff = strumTime - Conductor.songPosition;
				event.y = (FlxG.save.data.downscroll ? -getYfromStrum(strumTime) : getYfromStrum(strumTime)) * zoomFactorList[curSelectedZoom];
				var range = [460, 290];

				if (diff <= range[0] / (zoomFactorList[curSelectedZoom]) && diff >= -range[1] / (zoomFactorList[curSelectedZoom]))
				{
					if (!event.visible)
					{
						eventRenders.add(event);
						event.visible = true;
					}
				}
				else
				{
					if (event.visible)
					{
						eventRenders.remove(event, true);
						event.visible = false;
					}
				}
			}
		}
	}

	function updateSustains()
	{
		for (i in 0...unspawnSustains.length)
		{
			var sustain = unspawnSustains[i];
			if (sustain != null)
			{
				if (sustain.parent._def.sustainLength > 0)
				{
					var diff = sustain.parent._def.strumTime - Conductor.songPosition;

					var range = [450, 290 + sustain.parent._def.sustainLength];

					if (diff <= range[0] / (zoomFactorList[curSelectedZoom]) && diff >= -range[1] / (zoomFactorList[curSelectedZoom]))
					{
						if (!sustain.alive)
						{
							sustain.visible = true;

							curRenderedSustains.add(sustain);
							sustain.revive();
						}
					}
					else
					{
						if (sustain.alive)
						{
							sustain.visible = false;
							curRenderedSustains.remove(sustain, true);

							sustain.kill();
						}
					}
				}
			}
		}
	}

	function resizeSustains()
	{
		for (i in 0...unspawnSustains.length)
		{
			var sus = unspawnSustains[i];
			if (sus != null)
			{
				if (FlxG.save.data.downscroll)
					sus.parent.y = (-getYfromStrum(sus.parent._def.strumTime) * zoomFactorList[curSelectedZoom]);
				else
					sus.parent.y = getYfromStrum(sus.parent._def.strumTime) * zoomFactorList[curSelectedZoom];

				var height:Int = Math.floor((getYfromStrum(sus.parent._def.strumTime + sus.parent._def.sustainLength) * zoomFactorList[curSelectedZoom])
					- Math.abs(sus.parent.y));

				if (height < 1)
					height = 1;

				sus.makeGraphic(8, height);

				sus.updateHitbox();
			}
		}
	}

	function updateSusProps()
	{
		for (i in 0...curRenderedSustains.members.length)
		{
			var sus = curRenderedSustains.members[i];
			if (sus != null)
			{
				// we need to update Y stats for parent because it doesn't update with noteUpdateProps. I'm too stupid sorry.
				if (FlxG.save.data.downscroll)
					sus.parent.y = (-getYfromStrum(sus.parent._def.strumTime) * zoomFactorList[curSelectedZoom]) - GRID_SIZE;
				else
					sus.parent.y = getYfromStrum(sus.parent._def.strumTime) * zoomFactorList[curSelectedZoom];

				sus.parent.x = Math.floor(sus.parent._def.rawNoteData * GRID_SIZE);

				sus.visible = sus.parent._def.sustainLength > 0;

				if (FlxG.save.data.downscroll)
					sus.setPosition(sus.parent.x + ((GRID_SIZE - sus.width) / 2), (sus.parent.y - sus.height + GRID_SIZE / 2));
				else
					sus.setPosition(sus.parent.x + ((GRID_SIZE - sus.width) / 2), (sus.parent.y + GRID_SIZE / 2));
			}
		}
	}

	function updateNotes()
	{
		for (i in 0...unspawnNotes.length)
		{
			var noteDef = unspawnNotes[i];
			if (noteDef != null)
			{
				var diff = noteDef.strumTime - Conductor.songPosition;

				var range = [450, 290];

				if (diff <= range[0] / (zoomFactorList[curSelectedZoom]) && diff >= -range[1] / (zoomFactorList[curSelectedZoom]))
				{
				}
			}
		}
	}

	function generateNotes()
	{
		susPool = new FlxPool<SustainRender>(SustainRender);

		for (sec in _song.notes)
		{
			if (sec != null)
			{
				for (i in sec.sectionNotes)
				{
					var daNoteInfo = i[1];
					var daStrumTime = i[0];
					var daSus = i[2];
					var daNoteType = i[3];
					var daBeat = TimingStruct.getBeatFromTime(daStrumTime);

					var note:NoteDef = new NoteDef(daStrumTime, daNoteInfo % 4, null, false, true, daBeat, daNoteType, i[4], 'default');

					note.rawNoteData = daNoteInfo;
					note.sustainLength = daSus;
					note.strumTime = daStrumTime;

					/*var sustainVis:SustainRender = susPool.get();
							sustainVis.parent = note;
							var height:Int = Math.floor((getYfromStrum(sustainVis.parent.strumTime + sustainVis.parent.sustainLength) * zoomFactorList[curSelectedZoom])
								- Math.abs(sustainVis.parent.y));

							if (height < 1)
								height = 1;
							sustainVis.makeGraphic(8, height);

							sustainVis.setPosition(note.x + (GRID_SIZE / 2), note.y + GRID_SIZE / 2);

							if (FlxG.save.data.downscroll)
								sustainVis.y = note.y - sustainVis.height + GRID_SIZE;

							note.noteCharterObject = sustainVis;

							sustainVis.visible = false;
							sustainVis.kill(); 

						unspawnSustains.push(sustainVis); */

					unspawnNotes.push(note);
				}
			}
		}

		unspawnNotes.sort(sortByShit);
	}

	override function destroy()
	{
		susPool = null;

		curRenderedNotes.clear();
		curRenderedSustains.clear();
		beatLines.clear();

		/*for (sus in unspawnSustains)
			if (sus != null)
				sus.destroy(); */

		super.destroy();
	}

	private function setSongTimings()
	{
		TimingStruct.clearTimings();

		var currentIndex = 0;
		for (event in _song.events)
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

		// sort events by beat
		if (_song.events != null)
		{
			_song.events.sort(function(a, b)
			{
				if (a.beat < b.beat)
					return -1
				else if (a.beat > b.beat)
					return 1;
				else
					return 0;
			});
		}
	}

	private function newSection(lengthInSteps:Int = 16, mustHitSection:Bool = false, CPUAltAnim:Bool = true, playerAltAnim:Bool = true):SwagSection
	{
		var sec:SwagSection = {
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

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, currentSection.lengthInSteps, 0, currentSection.lengthInSteps);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, currentSection.lengthInSteps, 0, currentSection.lengthInSteps);
	}

	function strumLineUpdateY()
	{
		if (FlxG.save.data.downscroll)
			strumLine.y = -getYfromStrum(Conductor.songPosition) * zoomFactorList[curSelectedZoom];
		else
			strumLine.y = getYfromStrum(Conductor.songPosition) * zoomFactorList[curSelectedZoom];
	}

	var difficultiesThatExists = [];

	var curDiff:String = "";

	function scanDifficulties(songName:String, ?Callback:Void->Void = null)
	{
		difficultiesThatExists = [];
		for (i in 0...CoolUtil.difficultyArray.length)
		{
			var leDiff = CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[i]);
			if (Paths.doesTextAssetExist(Paths.json('songs/${songName}/${songName}$leDiff')))
				difficultiesThatExists.push(CoolUtil.difficultyArray[i]);
		}
		if (Callback != null)
			Callback();
	}

	var UI_songTitle:FlxUIInputText;

	var newBPM:Float = 0;

	var metronomeActive:Bool = false;

	function addEditorOptionsUI()
	{
		var metronomeChecker = new FlxUICheckBox(14, 43, null, null, "Metronome", 75);
		metronomeChecker.checked = metronomeActive;
		metronomeChecker.callback = function()
		{
			metronomeActive = metronomeChecker.checked;
		};

		var snapChecker = new FlxUICheckBox(14, 73, null, null, "Snap to Grid", 75);
		snapChecker.checked = snapped;
		snapChecker.callback = function()
		{
			snapped = snapChecker.checked;
		};

		var snapStepper = new CoolNumericStepper(14, 120, 55, Std.string(snapArray[curSnap]), 4, 8, 'Snap', null);
		snapStepper.canInput = false;
		snapStepper.callback = function(value:Float)
		{
			switch (value)
			{
				case 24:
					snapStepper.stepperAddValue = 8;
					snapStepper.stepperSubstractValue = 4;
				case 32:
					snapStepper.stepperAddValue = 16;
					snapStepper.stepperSubstractValue = 8;
				case 64:
					snapStepper.stepperAddValue = 32;
					snapStepper.stepperSubstractValue = 16;
				case 96:
					snapStepper.stepperAddValue = 96;
					snapStepper.stepperSubstractValue = 32;
				default: // Yandere Dev type shit
					if (value > 24 && value < 32)
						snapStepper.stepperAddValue = snapStepper.stepperSubstractValue = 8;
					if (value > 32 && value < 64)
						snapStepper.stepperAddValue = snapStepper.stepperSubstractValue = 16;
					if (value >= 4 && value < 24)
						snapStepper.stepperAddValue = snapStepper.stepperSubstractValue = 4;
					if (value == 192)
						snapStepper.stepperAddValue = snapStepper.stepperSubstractValue = 96;
			}

			if (value > 192)
			{
				value = 192;
				snapStepper.inputText.text = '192';
			}

			if (value < 4)
			{
				value = 4;
				snapStepper.inputText.text = '4';
			}

			curSnap = snapArray.indexOf(Std.int(value));
		}

		var overlapChecker = new FlxUICheckBox(14, 175, null, null, "Free Overlap", 75);
		overlapChecker.checked = freeOverlap;
		overlapChecker.callback = function()
		{
			freeOverlap = overlapChecker.checked;
		};

		var tab_group_editor = new FlxUI(null, uiTabMenuSecondary);
		tab_group_editor.name = "Editor Settings";
		tab_group_editor.add(metronomeChecker);
		tab_group_editor.add(snapChecker);
		tab_group_editor.add(snapStepper);
		tab_group_editor.add(overlapChecker);

		uiTabMenuSecondary.addGroup(tab_group_editor);
	}

	function addPrimaryUI()
	{
		var songIdLabel = new FlxUIText(14, 10, 125, "Song ID", 8);
		UI_songTitle = new FlxUIInputText(15, 25, 150, _song.songId, 8);
		typeables.push(UI_songTitle);

		var check_voices = new FlxUICheckBox(14, 43, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
		};

		var saveButton:FlxUIButton = new FlxUIButton(190, 21, "Save", function()
		{
			saveLevel();
		});

		var diffLabel = new FlxUIText(14, 140, 64, 'Difficulty');

		var diffsDropDown:FlxUIDropDownMenu = null;

		if (!PlayState.isSM)
		{
			diffsDropDown = new FlxUIDropDownMenu(15, 155, FlxUIDropDownMenu.makeStrIdLabelArray(difficultiesThatExists, true), function(diff:String)
			{
				var leDiff = difficultiesThatExists[Std.parseInt(diff)];

				curDiff = leDiff;
			});

			dropMenus.push(diffsDropDown);

			diffsDropDown.selectedId = Std.string(PlayState.storyDifficulty);
		}

		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
		var noteStyles:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/noteStyleList'));

		var assetsLabel = new FlxUIText(14, 195, 100, 'Song Assets', 9);

		var player1Label = new FlxUIText(14, 210, 64, 'Player 1');

		var player1DropDown:FlxUIDropDownMenu = new FlxUIDropDownMenu(15, 225, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true),
			function(character:String)
			{
				_song.player1 = charList[Std.parseInt(character)];
			});

		dropMenus.push(player1DropDown);
		player1DropDown.selectedLabel = _song.player1;

		var player2Label = new FlxUIText(140, 210, 64, 'Player 2');

		var player2DropDown = new FlxUIDropDownMenu(140, 225, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String)
		{
			_song.player2 = charList[Std.parseInt(character)];
		});
		dropMenus.push(player2DropDown);
		player2DropDown.selectedLabel = _song.player2;

		var gfVersionLabel = new FlxUIText(14, 275, 64, 'Girlfriend');

		var gfVersionDropDown = new FlxUIDropDownMenu(14, 290, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(gfVersion:String)
		{
			_song.gfVersion = charList[Std.parseInt(gfVersion)];
		});

		dropMenus.push(gfVersionDropDown);
		gfVersionDropDown.selectedLabel = _song.gfVersion;

		var stageLabel = new FlxUIText(140, 275, 64, 'Stage');

		var stageDropDown = new FlxUIDropDownMenu(140, 290, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(stage:String)
		{
			_song.stage = stages[Std.parseInt(stage)];
		});

		dropMenus.push(stageDropDown);
		stageDropDown.selectedLabel = _song.stage;

		var refreshDiffs:FlxUIButton = null;

		if (!PlayState.isSM)
			refreshDiffs = new FlxUIButton(175, 155, "Refresh", function()
			{
				scanDifficulties(UI_songTitle.text, function()
				{
					try
					{
						diffsDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(difficultiesThatExists, true));
						diffsDropDown.selectedLabel = difficultiesThatExists[0];

						var leDiff = diffsDropDown.selectedLabel;

						curDiff = leDiff;
					}
					catch (e)
					{
						Debug.logError('Something went wrong... Error: $e');
					}
				});
			});

		var reloadSongJson:FlxUIButton = new FlxUIButton(190, 47, "Reload JSON", function()
		{
			loadJson(UI_songTitle.text);
		});

		var speedStepper:CoolNumericStepper = new CoolNumericStepper(15, 80, 65, Std.string(_song.speed), 0.1, 8, 'Scroll Speed', function(value:Float)
		{
			if (value == 0 || Math.isNaN(value))
				_song.speed = 0.1;
			else
				_song.speed = value;
		});

		var bpmStepper:CoolNumericStepper = new CoolNumericStepper(15, 115, 65, Std.string(_song.bpm), 0.1, 8, 'Song BPM', function(value:Float)
		{
			if (value == 0 || Math.isNaN(value))
				newBPM = 0.1;
			else
				newBPM = value;
		});

		var bpmChangeButton:FlxUIButton = new FlxUIButton(150, 110, 'Change BPM', function()
		{
			if (_song.bpm != newBPM)
			{
				_song.bpm = newBPM;
				Conductor.changeBPM(newBPM);

				_song.events[0].args[0] = newBPM;

				setSongTimings();

				recalculateAllSectionTimes();

				calculateMaxBeat();
				checkforSections();

				setupLines();
				checkSectionLines();

				generateEvents();
			}
		});

		var tab_group_song = new FlxUI(null, uiTabMenuPrimary);
		tab_group_song.name = "Song";
		tab_group_song.add(songIdLabel);
		tab_group_song.add(UI_songTitle);
		tab_group_song.add(check_voices);
		tab_group_song.add(speedStepper);
		tab_group_song.add(bpmStepper);
		tab_group_song.add(bpmChangeButton);
		tab_group_song.add(saveButton);
		if (!PlayState.isSM)
			tab_group_song.add(refreshDiffs);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(assetsLabel);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(gfVersionLabel);
		tab_group_song.add(stageDropDown);
		tab_group_song.add(stageLabel);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(player2DropDown);
		tab_group_song.add(player1Label);
		tab_group_song.add(player2Label);
		tab_group_song.add(diffLabel);
		if (!PlayState.isSM)
			tab_group_song.add(diffsDropDown);

		uiTabMenuPrimary.addGroup(tab_group_song);
	}

	var currentSelectedEventName:String = "";
	var savedType:String = "BPM Change";
	var savedValue:String = "100";
	var currentEventPosition:Float = 0;

	var listOfEvents:FlxUIDropDownMenu;

	var eventsInSong:Map<String, ChartEvent> = [];
	var eventsInSongArray:Array<String> = [''];

	function regenerateLists(?initialize:Bool = true)
	{
		// Gotta use this function to refresh
		// the lists for the event system
		eventsInSongArray = [];
		eventsInSong = [];

		if (_song.events == null)
		{
			Debug.logTrace("There are no events in this song.");
		}
		else
		{
			for (event in _song.events)
			{
				var eventInfo = chartEventHandler.chartEvents.get(event.name);
				var label:String = '${eventInfo == null ? eventInfo.displayName : event.name}: ${event.beat}';
				eventsInSong.set(label, event);
				eventsInSongArray.push(label);
			}
		}

		if (initialize)
			return;
		else
		{
			var meta = chartEventHandler.chartEvents;
			var array:Array<String> = [];
			for (string in meta.keys())
			{
				array.push(string);
			}
			array = CoolUtil.sortByAlphabet(array);
			typeList.setData(FlxUIDropDownMenu.makeStrIdLabelArray(array, true));

			if (eventsInSongArray == null)
			{
				Debug.logTrace("No events in the song array. Returning...");
				return;
			}
			else
			{
				eventList.setData(FlxUIDropDownMenu.makeStrIdLabelArray(eventsInSongArray, true));
			}
		}
	}

	var descLabel:FlxText;
	var beatInput:FlxUIInputText;

	var typeList:FlxUIDropDownMenu;
	var eventList:FlxUIDropDownMenu;

	var value1Label:FlxUIText;
	var value1Input:FlxUIInputText;
	var value2Label:FlxUIText;
	var value2Input:FlxUIInputText;

	function addEventsUI()
	{
		var eventMeta = chartEventHandler.chartEvents;
		var eventArray:Array<String> = [];
		for (string in eventMeta.keys())
		{
			eventArray.push(string);
		}

		// Sorting array alphabetically because
		// maps are unordered by default. ~Codexes
		eventArray = CoolUtil.sortByAlphabet(eventArray);

		value1Label = new FlxUIText(10, 70, 250, "Value 1:");
		value1Input = new FlxUIInputText(10, 90, 100, "");
		typeables.push(value1Input);

		value2Label = new FlxUIText(10, 110, 250, "Value 2:");
		value2Input = new FlxUIInputText(10, 130, 100, "");
		typeables.push(value2Input);

		var beatLabel = new FlxText(150, 70, 150, "Event Pos (In Beats):");
		beatInput = new FlxUIInputText(150, 90, 100, "");

		var listLabel = new FlxUIText(10, 10, 100, "List of Events");

		var descLabel = new FlxUIText(10, 150, 250, "");
		descLabel.autoSize = true;

		regenerateLists();

		var typeLabel = new FlxText(150, 10, 100, "Type of Event");

		// This list is for all the events from the chart meta
		typeList = new FlxUIDropDownMenu(150, 30, FlxUIDropDownMenu.makeStrIdLabelArray(eventArray, true), function(selected:String)
		{
			var event = eventArray[Std.parseInt(selected)];
			descLabel.text = 'Description:\n' + eventMeta[event].description;
			Debug.logTrace('Event: ${event}, Values: ${eventMeta[event]}');
			if (eventMeta[event].args[0] == null)
			{
				Debug.logTrace('Event has no arguments. Resetting values.');
				value1Label.text = "Value 1: NULL";
				value2Label.text = "Value 2: NULL";
			}
			else
			{
				Debug.logTrace('Event has arguments. Changing a few values.');
				value1Label.text = '${eventMeta[event].args[0].name}: ${eventMeta[event].args[0].type}';

				if (eventMeta[event].args[1] == null)
				{
					Debug.logTrace('Event does not have a second argument.');
					value2Label.text = "Value 2: NULL";
				}
				else
				{
					value2Label.text = '${eventMeta[event].args[1].name}: ${eventMeta[event].args[1].type}';
				}
			}
		});

		// This list is for all events within the song.
		eventList = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray(eventsInSongArray, true), function(selected:String)
		{
			Debug.logTrace(selected);
			var selectedEvent:ChartEvent = eventsInSong[eventsInSongArray[Std.parseInt(selected)]];
			var splitString:String = eventsInSongArray[Std.parseInt(selected)].split(":")[0];
			var eventTypeID:String = selectedEvent.name;
			var selectedEventType:ChartEventInfo = eventMeta[eventTypeID];

			descLabel.text = 'Description:\n' + eventMeta[eventTypeID].description;

			Debug.logTrace('Event: ${selectedEvent.name}, Values: ${selectedEvent.args}');
			if (selectedEvent.args[0] == null)
			{
				Debug.logTrace('Event has no arguments. Resetting values.');
				value1Label.text = "Value 1: NULL";
				value1Input.text = "";
				value2Label.text = "Value 2: NULL";
				value2Input.text = "";
			}
			else
			{
				if (selectedEventType == null)
				{
					Debug.logWarn('Warning: selectedEventType is null. Reference: ${splitString}');
					return;
				}

				Debug.logTrace('Event has arguments. Changing a few values.');

				value1Label.text = '${selectedEventType.args[0].name}: ${selectedEventType.args[0].type}';
				value1Input.text = selectedEvent.args[0];

				if (selectedEvent.args[1] == null)
				{
					Debug.logTrace('Event does not have a second argument.');
					value2Label.text = "Value 2: NULL";
					value2Input.text = "";
				}
				else
				{
					value2Label.text = '${selectedEventType.args[1].name}: ${selectedEventType.args[1].type}';
					value2Input.text = selectedEvent.args[1];
				}

				beatInput.text = Std.string(selectedEvent.beat);
			}

			var buttonTypeToFind:FlxUIButton = null;

			for (otherBtn in typeList.list)
				if (otherBtn.label.text == eventTypeID)
					buttonTypeToFind = otherBtn;

			var typeIndex = Std.string(typeList.list.indexOf(buttonTypeToFind));

			typeList.callback(typeIndex);

			typeList.selectedId = typeIndex;
		});

		if (eventsInSongArray[0] != null)
			eventList.callback('0');

		var updateButton = new FlxUIButton(350, 130, "Update Event", function()
		{
			Debug.logTrace("Updating event...");

			var toUpdate:ChartEvent = eventsInSong[eventsInSongArray[Std.parseInt(eventList.selectedId)]];

			var eventInfo = chartEventHandler.chartEvents.get(toUpdate.name);

			var selectedEvent = eventList.selectedId;

			var updated:Bool = false;

			var eventIndexinSong:Int = 0;

			for (event in _song.events)
			{
				if (event == toUpdate)
				{
					eventIndexinSong = _song.events.indexOf(event);
					var pog:ChartEvent = {beat: -1, args: [], name: toUpdate.name}
					Debug.logTrace(event);
					if (beatInput.text != null && beatInput.text != '')
					{
						Debug.logTrace("Beat input text detected. Changing...");
						pog.beat = Std.parseFloat(beatInput.text);
					}
					else
					{
						Debug.logTrace("Beat input is null. Using innate event Beat.");
						pog.beat = toUpdate.beat;
					}

					pog.name = toUpdate.name;

					switch (event.args.length)
					{
						case 0:
							pog.args = [];
						case 1:
							pog.args.push(CoolUtil.parseType(value1Input.text, eventInfo.args[0].type));
						case 2:
							pog.args.push(CoolUtil.parseType(value1Input.text, eventInfo.args[0].type));
							pog.args.push(CoolUtil.parseType(value2Input.text, eventInfo.args[1].type));
					}

					toUpdate = pog;

					updated = true;
				}
			}

			Debug.logInfo(toUpdate);

			for (rendy in ieventsRenders)
			{
				if (rendy.attachedEvents.contains(_song.events[eventIndexinSong]))
				{
					Debug.logTrace('Removing event line with the event we want to update.');
					ieventsRenders.remove(rendy);
				}
			}

			for (rendy in eventRenders.members)
			{
				if (rendy.attachedEvents.contains(_song.events[eventIndexinSong]))
				{
					Debug.logTrace('Removing event line with the event we want to update.');
					eventRenders.remove(rendy, true);
				}
			}

			_song.events[eventIndexinSong] = toUpdate;

			var foundEventRender:Bool = false;
			for (eventRender in ieventsRenders)
			{
				if (eventRender.beat == toUpdate.beat)
				{
					foundEventRender = true;
					break;
				}
			}

			if (foundEventRender)
			{
				for (eventRender in ieventsRenders)
				{
					if (eventRender.beat == toUpdate.beat)
					{
						eventRender.attachedEvents.push(toUpdate);
						eventRender.updateText();
					}
				}
			}
			else
			{
				var newEventRender = new EventRender(0, 0, [toUpdate]);
				newEventRender.visible = false;
				newEventRender.updateText();
				ieventsRenders.push(newEventRender);
			}

			if (!updated)
				Debug.logTrace('Event was not updated. Something went wrong.');
			else
				Debug.logTrace('Event updated.');

			regenerateLists(false);
			eventList.callback(selectedEvent);

			eventList.selectedId = selectedEvent;
		});

		// Add function
		var addButton = new FlxUIButton(350, 160, "Add Event", function()
		{
			if (beatInput.text.length == 0)
			{
				Debug.logTrace("Beat value is null.");
			}
			else if (Std.parseFloat(beatInput.text) == Math.NaN)
			{
				Debug.logTrace("Cannot parse text; likely a string value.");
			}
			else
			{
				Debug.logTrace("Beat value is valid. Processing event addition...");

				var typeIndex = typeList.selectedId;

				var eventName = eventArray[Std.parseInt(typeIndex)];

				Debug.logTrace('Event: ${eventName}');
				Debug.logTrace('Init: ${eventMeta[eventName]}');
				Debug.logTrace('Length: ${eventMeta[eventName].args.length}');

				// poggers
				var pog:ChartEvent = {beat: -1, args: [], name: eventName};
				pog.beat = Std.parseFloat(beatInput.text);
				pog.name = eventName;

				switch (eventMeta[eventName].args.length)
				{
					case 0:
						pog.args = [];
					case 1:
						pog.args.push(CoolUtil.parseType(value1Input.text, eventMeta[eventName].args[0].type));
					case 2:
						pog.args.push(CoolUtil.parseType(value1Input.text, eventMeta[eventName].args[0].type));
						pog.args.push(CoolUtil.parseType(value2Input.text, eventMeta[eventName].args[1].type));
				}

				Debug.logTrace('Event created: ${pog}');
				_song.events.push(pog);

				if (pog.name == 'changeBPM')
				{
					setSongTimings();
					recalculateAllSectionTimes();
					checkforSections();
					setupLines();
					checkSectionLines();
					generateEvents();
				}

				var foundEventRender:Bool = false;
				for (eventRender in ieventsRenders)
				{
					if (eventRender.beat == pog.beat)
					{
						foundEventRender = true;
						break;
					}
				}

				if (foundEventRender)
				{
					for (eventRender in ieventsRenders)
					{
						if (eventRender.beat == pog.beat)
						{
							eventRender.attachedEvents.push(pog);
							eventRender.updateText();
						}
					}
				}
				else
				{
					var newEventRender = new EventRender(0, 0, [pog]);
					newEventRender.visible = false;
					newEventRender.updateText();
					ieventsRenders.push(newEventRender);
				}

				regenerateLists(false);

				var nameToFind = '${eventMeta[pog.name].displayName}: ${pog.beat}';
				var buttonNameToFind:FlxUIButton = null;
				var buttonTypeToFind:FlxUIButton = null;

				Debug.logInfo(nameToFind);
				for (btn in eventList.list)
					if (btn.label.text == nameToFind)
						buttonNameToFind = btn;

				for (otherBtn in typeList.list)
					if (otherBtn.label.text == pog.name)
						buttonTypeToFind = otherBtn;

				var eventIndex = Std.string(eventList.list.indexOf(buttonNameToFind));
				var typeIndex = Std.string(typeList.list.indexOf(buttonTypeToFind));
				eventList.callback(eventIndex);

				typeList.callback(typeIndex);

				eventList.selectedId = eventIndex;
				typeList.selectedId = typeIndex;
			}
		});

		// Remove function
		var removeButton = new FlxUIButton(350, 190, "Remove Event", function()
		{
			// Select the event from the list and press remove button

			Debug.logTrace("Processing event deletion...");

			var toRemove:ChartEvent = eventsInSong[eventsInSongArray[Std.parseInt(eventList.selectedId)]];

			var deleted:Bool = false;

			for (event in _song.events)
			{
				if (toRemove.name == "changeBPM" && event.beat == 0)
				{
					Debug.logTrace("Init BPM event processed. Unable to delete this event.");
					continue;
				}
				else if (event == toRemove)
				{
					_song.events.remove(event);
					if (toRemove.name == 'changeBPM')
					{
						setSongTimings();
						recalculateAllSectionTimes();
						checkforSections();
						setupLines();
						checkSectionLines();
						generateEvents();
					}

					for (eventRender in ieventsRenders)
					{
						if (eventRender.beat == toRemove.beat)
						{
							if (eventRender.attachedEvents.length > 1)
							{
								eventRender.attachedEvents.remove(toRemove);
							}
							else
							{
								ieventsRenders.remove(eventRender);
								eventRender.destroy();
							}
						}
					}

					for (ev in eventRenders.members)
					{
						eventRenders.remove(ev, true);
					}

					deleted = true;
					break;
				}
			}

			if (!deleted)
				Debug.logTrace('Event not found. Deletion process terminated.');
			else
				Debug.logTrace('Event deleted.');

			// Reset lines to show new (possible) change.

			value1Input.text = '';
			value2Input.text = '';
			beatInput.text = '';

			regenerateLists(false);

			var eventIndex = Std.string(eventList.list.length - 1);

			eventList.callback(eventIndex);

			eventList.selectedId = eventIndex;
		});

		var tab_group_events = new FlxUI(null, uiTabMenuSecondary);
		tab_group_events.name = "Song Sevents";
		tab_group_events.add(descLabel);

		tab_group_events.add(listLabel);
		tab_group_events.add(typeLabel);
		tab_group_events.add(value1Label);
		tab_group_events.add(value2Label);

		tab_group_events.add(value1Label);
		tab_group_events.add(value1Input);
		tab_group_events.add(value2Label);
		tab_group_events.add(value2Input);
		tab_group_events.add(beatLabel);
		tab_group_events.add(beatInput);
		tab_group_events.add(typeList);
		tab_group_events.add(eventList);
		tab_group_events.add(addButton);
		tab_group_events.add(removeButton);
		tab_group_events.add(updateButton);

		uiTabMenuPrimary.addGroup(tab_group_events);
	}

	var stepsStepper:CoolNumericStepper = null;

	function addSectionUI()
	{
		stepsStepper = new CoolNumericStepper(15, 80, 65, Std.string(currentSection.lengthInSteps), 1, 8, 'Section Length (In Steps)', function(value:Float)
		{
			if (value < 0)
			{
				value = 1;
				stepsStepper.inputText.text = '1';
			}

			currentSection.lengthInSteps = Std.int(value);

			recalculateAllSectionTimes(curSection);
			checkSectionLines();
		});
		var tab_group_sec = new FlxUI(null, uiTabMenuPrimary);
		tab_group_sec.name = "Song Section";

		tab_group_sec.add(stepsStepper);
		uiTabMenuPrimary.addGroup(tab_group_sec);
	}

	function listAssets()
	{
		var chars:Array<String> = CoolUtil.readAssetsDirectoryFromLibrary('assets/data/characters', 'TEXT');
		var finalArray = [];
		for (sub in chars)
		{
			var hmm = sub.substring(sub.indexOf('characters/') + 11, sub.indexOf('.'));
			if (!hmm.endsWith('-dead')) // Exclude dead characters
				finalArray.push(hmm);
		}

		charList = finalArray;
	}

	private function checkGridNotes(?n:NoteDef):Void
	{
		clearBoxSelections();

		var scrollOffset = FlxG.save.data.downscroll ? 40 : 0;
		var strum = getStrumTime(Math.abs(dummyArrow.y + scrollOffset)) / zoomFactorList[curSelectedZoom];

		var section = getSectionByTime(strum);

		if (section == null)
			return;

		Debug.logTrace(strum + " from " + dummyArrow.y);

		var noteStrum = strum;
		var noteData = Math.floor(FlxG.mouse.getWorldPosition(dummyArrow.camera).x / GRID_SIZE);
		var noteSus = 0;

		for (note in section.sectionNotes)
		{
			if (note[0] == noteStrum && note[1] == noteData)
			{
				Debug.logWarn('A note is already in this place. Deleting...');

				for (otherNote in unspawnNotes)
				{
					if (otherNote.strumTime == noteStrum && otherNote.rawNoteData == noteData)
						deleteNote(otherNote);
				}
				return;
			}
		}

		Debug.logInfo("Adding note with " + strum + " from dummyArrow with data " + noteData);

		if (n != null)
			section.sectionNotes.push([
				n.strumTime,
				n.noteData,
				n.sustainLength,
				false,
				TimingStruct.getBeatFromTime(n.strumTime)
			]);
		else
			section.sectionNotes.push([noteStrum, noteData, noteSus, false, TimingStruct.getBeatFromTime(noteStrum)]);

		if (n == null)
		{
			var note:NoteDef = new NoteDef(noteStrum, noteData % 4, null, false, true, TimingStruct.getBeatFromTime(noteStrum));

			note.rawNoteData = noteData;
			note.sustainLength = noteSus;
			/*note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
				note.updateHitbox();
				note.x = Math.floor(noteData * GRID_SIZE);

				note.charterSelected = true;

				if (FlxG.save.data.downscroll)
					note.y = (-getYfromStrum(note.strumTime) * zoomFactorList[curSelectedZoom]);
				else
					note.y = getYfromStrum(note.strumTime) * zoomFactorList[curSelectedZoom];

				note.visible = false;
				note.kill(); */

			unspawnNotes.push(note);
			unspawnNotes.sort(sortByShit);

			selectNote(note.connectedNote);
		}
		else
		{
			var note:NoteDef = new NoteDef(n.strumTime, n.noteData % 4, null, false, true);

			note.beat = TimingStruct.getBeatFromTime(n.strumTime);
			note.rawNoteData = n.noteData;
			note.sustainLength = noteSus;
			/*note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
				note.updateHitbox();
				note.x = Math.floor(n.noteData * GRID_SIZE);

				note.charterSelected = true;

				if (FlxG.save.data.downscroll)
					note.y = (-getYfromStrum(note.strumTime) * zoomFactorList[curSelectedZoom]);
				else
					note.y = getYfromStrum(note.strumTime) * zoomFactorList[curSelectedZoom];

				note.visible = false;
				note.kill(); */

			unspawnNotes.push(note);
			unspawnNotes.sort(sortByShit);

			selectNote(note.connectedNote);
		}
	}

	private function deleteNote(note:NoteDef)
	{
		Debug.logInfo('Tryin to delete note');

		var section = getSectionByTime(note.strumTime);

		var found = false;

		if (section != null)
		{
			for (i in section.sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == note.rawNoteData)
				{
					section.sectionNotes.remove(i);
					found = true;
				}
			}
		}

		if (!found) // backup check
		{
			for (i in _song.notes)
			{
				for (n in i.sectionNotes)
					if (n[0] == note.strumTime && n[1] == note.rawNoteData)
						i.sectionNotes.remove(n);
			}
		}

		unspawnNotes.remove(note);
		if (curRenderedNotes.members.contains(note.connectedNote))
			curRenderedNotes.remove(note.connectedNote, true);

		if (note.sustainLength > 0)
		{
			unspawnSustains.remove(note.connectedNote.noteCharterObject);
			if (curRenderedSustains.members.contains(note.connectedNote.noteCharterObject))
				curRenderedSustains.remove(note.connectedNote.noteCharterObject, true);
		}
	}

	private function clearBoxSelections()
	{
		while (noteSelectBoxes.length > 0)
		{
			var box = noteSelectBoxes.members[0];
			noteSelectBoxes.remove(box, true);
			box.destroy();
		}

		for (note in unspawnNotes)
		{
			if (note != null)
			{
				note.connectedNote.selectedBox = null;
				note.charterSelected = false;
			}
		}
	}

	private function selectNote(note:NoteSpr)
	{
		Debug.logInfo('Selecting note');
		clearBoxSelections();

		noteSelectBoxes.clear();

		if (note == null)
			return;

		note._def.charterSelected = true;
		note.selectedBox = new ChartingBox(note.x, note.y);
		noteSelectBoxes.add(note.selectedBox);
	}

	function loadJson(songId:String):Void
	{
		try
		{
			getSection = false;
			PlayState.storyDifficulty = CoolUtil.difficultyArray.indexOf(curDiff);
			PlayState.SONG = Song.loadFromJson(songId, CoolUtil.getSuffixFromDiff(curDiff));

			mustCleanMem = true;

			MusicBeatState.switchState(new ChartingState());
		}
		catch (e)
		{
			Debug.logError('Something went wrong... Error: $e');
		}
	}

	var _file:FileReference;

	// This recalculates the section the note needs to be if we change bpm.
	function recalculateNoteSections()
	{
		for (note in unspawnNotes)
		{
			var noteSection = getSectionByTime(note.strumTime);
			var noteType = note.noteType;
			var noteData = note.rawNoteData;
			var susLength = note.sustainLength;
			var noteStrum = note.strumTime;

			for (i in _song.notes)
			{
				if (i == noteSection)
				{
					i.sectionNotes = [];
					i.sectionNotes.push([noteStrum, noteData, susLength, noteType]);
				}
			}
		}
	}

	private function saveEvents()
	{
		var eventJson = {
			"events": _song.events
		};

		var data:String = Json.stringify(eventJson, null, " ");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}

	private function saveLevel()
	{
		var toRemove = [];

		#if cpp
		for (i in _song.notes)
		{
			if (i.startTime > instStream.length)
				toRemove.push(i);
		}
		#end

		for (i in toRemove)
			_song.notes.remove(i);

		toRemove = []; // clear memory

		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, null, " ");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.songId.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}
