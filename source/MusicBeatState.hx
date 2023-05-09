package;

import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import lime.app.Application;
import openfl.Lib;
import flixel.addons.ui.FlxUI;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIState;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import audio.AudioStream;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDestroyUtil;
import Song.SongData;
import Section.SwagSection;

class MusicBeatState extends FlxUIState
{
	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curSection:Int = 0;

	private var currentSection:SwagSection = null;

	private var curDecimalBeat:Float = 0;

	private var oldSection:Int = -1;

	public static var switchingState:Bool = false;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public static var initSave:Bool = false;

	public var songStream:AudioStream;

	var dumped:Bool = false;

	public static var subStates:Array<MusicBeatSubstate> = [];

	public static var transSubstate:PsychTransition;

	private var curTiming:TimingStruct = null;

	var fullscreenBind:FlxKey;

	var activeSong:SongData = null;

	override function destroy()
	{
		/*Application.current.window.onFocusIn.remove(onWindowFocusOut);
			Application.current.window.onFocusIn.remove(onWindowFocusIn); */

		if (!PlayState.inDaPlay)
		{
			for (rateData in FreeplayState.songRating.keys())
				rateData = null;

			for (opRateData in FreeplayState.songRatingOp.keys())
				opRateData = null;

			FreeplayState.songRating.clear();
			FreeplayState.songRatingOp.clear();

			FreeplayState.loadedSongData = false;
		}

		curTiming = null;

		if (subStates != null)
		{
			while (subStates.length > 5)
			{
				var subState:MusicBeatSubstate = subStates[0];
				if (subState != null)
				{
					Debug.logTrace('Destroying Substates!');
					subStates.remove(subState);
					subState.destroy();
				}
				subState = null;
			}

			subStates.resize(0);
		}

		if (transSubstate != null)
		{
			transSubstate.destroy();
			transSubstate = null;
		}

		super.destroy();
	}

	override function create()
	{
		transSubstate = new PsychTransition(0.85);

		destroySubStates = false;

		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;

		if (initSave)
		{
			if (FlxG.save.data.laneTransparency < 0)
				FlxG.save.data.laneTransparency = 0;

			if (FlxG.save.data.laneTransparency > 1)
				FlxG.save.data.laneTransparency = 1;
		}

		/*Application.current.window.onFocusIn.add(onWindowFocusIn);
			Application.current.window.onFocusOut.add(onWindowFocusOut); */
		// TimingStruct.clearTimings();

		KeyBinds.keyCheck();

		if (transIn != null)
			trace('reg ' + transIn.region);

		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		super.create();

		if (!skip)
		{
			transSubstate.isTransIn = true;
			openSubState(transSubstate);
		}
		FlxTransitionableState.skipNextTransOut = false;

		super.create();
		Main.gameContainer.setFPSCap(FlxG.save.data.fpsCap);
	}

	var step = 0.0;
	var startInMS = 0.0;

	var oldStep:Int = -1;

	override function update(elapsed:Float)
	{
		// everyStep();
		/*var nextStep:Int = updateCurStep();

			if (nextStep >= 0)
			{
				if (nextStep > curStep)
				{
					for (i in curStep...nextStep)
					{
						curStep++;
						updateBeat();
						stepHit();
					}
				}
				else if (nextStep < curStep)
				{
					//Song reset?
					curStep = nextStep;
					updateBeat();
					stepHit();
				}
		}*/

		fullscreenBind = FlxKey.fromString(FlxG.save.data.fullscreenBind);

		if (FlxG.keys.anyJustPressed([fullscreenBind]))
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		if (curDecimalBeat < 0)
			curDecimalBeat = 0;

		if (Conductor.songPosition < 0)
			curDecimalBeat = 0;
		else
		{
			if (curTiming == null)
			{
				setFirstTiming();
			}

			if (curTiming != null)
			{
				/* Not necessary to get a timing every frame if it's the same one. Instead if the current timing endBeat is equal or greater
					than the current Beat meaning that the timing ended the game will check for a new timing (for bpm change events basically), 
					and also to get a lil more of performance */

				if (curDecimalBeat > curTiming.endBeat)
				{
					Debug.logTrace('Current Timing ended, checking for next Timing...');
					curTiming = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
					step = ((60 / curTiming.bpm) * 1000) / 4;
					startInMS = (curTiming.startTime * 1000);
				}

				#if debug
				FlxG.watch.addQuick("Current Conductor Timing Seg", curTiming.bpm);
				#end

				curDecimalBeat = TimingStruct.getBeatFromTime(Conductor.songPosition);

				curBeat = Math.floor(curDecimalBeat);
				curStep = Math.floor(curDecimalBeat * 4);

				// Bromita uwu
				try
				{
					if (currentSection == null)
					{
						currentSection = getSectionByTime(Conductor.songPosition);
						if (activeSong != null)
							curSection = activeSong.notes.indexOf(currentSection);
					}

					if (currentSection != null)
					{
						if (Conductor.songPosition >= currentSection.endTime || Conductor.songPosition < currentSection.startTime)
						{
							currentSection = getSectionByTime(Conductor.songPosition);
							if (activeSong != null)
								curSection = activeSong.notes.indexOf(currentSection);
						}
					}
				}
				catch (e)
				{
					// Debug.logError('Section is null you fucking dumbass uninstall Flixel and kys');
				}

				if (oldSection != curSection)
				{
					sectionHit();
					oldSection = curSection;
				}

				if (oldStep != curStep)
				{
					stepHit();
					oldStep = curStep;
				}
			}
			else
			{
				curDecimalBeat = (((Conductor.songPosition / 1000))) * (Conductor.bpm / 60);

				curBeat = Math.floor(curDecimalBeat);
				curStep = Math.floor(curDecimalBeat * 4);

				// Bromita uwu
				try
				{
					if (currentSection == null)
					{
						currentSection = getSectionByTime(0);
						curSection = 0;
					}

					if (currentSection != null)
					{
						if (Conductor.songPosition >= currentSection.endTime || Conductor.songPosition < currentSection.startTime)
						{
							currentSection = getSectionByTime(Conductor.songPosition);

							curSection = activeSong.notes.indexOf(currentSection);
						}
					}
				}
				catch (e)
				{
					// Debug.logError('Section is null you fucking dumbass uninstall Flixel and kys');
				}

				if (oldSection != curSection)
				{
					sectionHit();
					oldSection = curSection;
				}

				if (oldStep != curStep)
				{
					stepHit();
					oldStep = curStep;
				}
			}
		}

		Main.gameContainer.setFPSCap(FlxG.save.data.fpsCap);
		super.update(elapsed);
	}

	// ALL CREDITS TO SHADOWMARIO
	public static function switchState(nextState:FlxState)
	{
		MusicBeatState.switchingState = true;
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			transSubstate.isTransIn = false;
			leState.openSubState(transSubstate);

			if (nextState == FlxG.state)
			{
				transSubstate.finishCallback = function()
				{
					MusicBeatState.switchingState = false;
					FlxG.resetState();
				};
				// trace('resetted');
			}
			else
			{
				transSubstate.finishCallback = function()
				{
					MusicBeatState.switchingState = false;
					FlxG.switchState(nextState);
				};
				// trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}

	public function sectionHit():Void
	{
		// do literally nothing dumbass
	}

	public function fancyOpenURL(schmancy:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [schmancy, "&"]);
		#else
		FlxG.openURL(schmancy);
		#end
	}

	private function setFirstTiming()
	{
		curTiming = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
		if (curTiming != null)
		{
			step = ((60 / curTiming.bpm) * 1000) / 4;
			startInMS = (curTiming.startTime * 1000);
		}
	}

	/*function onWindowFocusOut():Void
		{
			if (PlayState.inDaPlay)
			{
				if (PlayState.instance.vocals != null)
					PlayState.instance.vocals.pause();
				if (FlxG.sound.music != null)
					FlxG.sound.music.pause();
				if (!PlayState.instance.paused && !PlayState.instance.endingSong && PlayState.instance.songStarted)
				{
					Debug.logTrace("Lost Focus");
					PlayState.instance.openSubState(new PauseSubState());
					PlayState.boyfriend.stunned = true;

					PlayState.instance.persistentUpdate = false;
					PlayState.instance.persistentDraw = true;
					PlayState.instance.paused = true;
				}
			}
		}

		function onWindowFocusIn():Void
		{
			Debug.logTrace("IM BACK!!!");
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
			if (PlayState.inDaPlay)
			{
				if (PlayState.boyfriend.stunned)
					PlayState.boyfriend.stunned = false;
			}
	}*/
	function getSectionLength()
	{
		var val:Null<Int> = 16;
		if (activeSong != null && activeSong.notes[curSection] != null)
			val = activeSong.notes[curSection].lengthInSteps;

		return val == null ? 16 : val;
	}

	function getSectionByTime(ms:Float):SwagSection
	{
		if (activeSong == null)
			return null;

		if (activeSong.notes == null)
			return null;

		for (i in activeSong.notes)
		{
			if (ms >= i.startTime && ms < i.endTime)
			{
				return i;
			}
		}
		return null;
	}

	function recalculateAllSectionTimes(startIndex:Int = 0)
	{
		trace("RECALCULATING SECTION TIMES");

		if (activeSong == null)
			return;

		for (i in startIndex...activeSong.notes.length) // loops through sections
		{
			var section:SwagSection = activeSong.notes[i];

			var currentBeat:Float = 0.0;

			currentBeat = (section.lengthInSteps / 4) * (i + 1);

			for (k in 0...i)
				currentBeat -= ((section.lengthInSteps / 4) - (activeSong.notes[k].lengthInSteps / 4));

			section.endTime = TimingStruct.getTimeFromBeat(currentBeat);

			if (i != 0)
				section.startTime = activeSong.notes[i - 1].endTime;
			else
				section.startTime = 0;

			Debug.logTrace('Section #$i StartTime: ${section.startTime} | EndTime: ${section.endTime}');
		}
	}
}
