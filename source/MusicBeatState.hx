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
import audio.AudioStreamThing;
import flixel.input.keyboard.FlxKey;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var curDecimalBeat:Float = 0;

	public static var switchingState:Bool = false;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public static var initSave:Bool = false;

	public static var songStream:AudioStreamThing;

	var dumped:Bool = false;

	public static var subStates:Array<FlxSubState> = [];

	private var curTiming:TimingStruct = null;

	var fullscreenBind:FlxKey;

	override function destroy()
	{
		/*Application.current.window.onFocusIn.remove(onWindowFocusOut);
			Application.current.window.onFocusIn.remove(onWindowFocusIn); */

		curTiming = null;

		for (substate in subStates)
		{
			if (substate != null)
				substate.destroy();
			subStates.remove(substate);
		}

		super.destroy();
	}

	override function create()
	{
		subStates = [];
		destroySubStates = false;

		Paths.runGC();

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
			openSubState(new PsychTransition(0.85, true));
		}
		FlxTransitionableState.skipNextTransOut = false;

		super.create();
		(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
	}

	var step = 0.0;
	var startInMS = 0.0;

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

				if (curTiming.endBeat < curDecimalBeat)
				{
					Debug.logTrace('Current Timing ended, checking for next Timing...');
					curTiming = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
					step = ((60 / curTiming.bpm) * 1000) / 4;
					startInMS = (curTiming.startTime * 1000);
				}

				#if debug
				FlxG.watch.addQuick("Current Conductor Timing Seg", curTiming.bpm);
				#end

				curDecimalBeat = curTiming.startBeat + ((((Conductor.songPosition / 1000)) - curTiming.startTime) * (curTiming.bpm / 60));
				var ste:Int = Math.floor(curTiming.startStep + ((Conductor.songPosition) - startInMS) / step);
				if (ste >= 0)
				{
					if (ste > curStep)
					{
						for (i in curStep...ste)
						{
							curStep++;
							updateBeat();
							stepHit();
						}
					}
					else if (ste < curStep)
					{
						trace("reset steps for some reason?? at " + Conductor.songPosition);
						// Song reset?
						curStep = ste;
						updateBeat();
						stepHit();
					}
				}
			}
			else
			{
				curDecimalBeat = (((Conductor.songPosition / 1000))) * (Conductor.bpm / 60);
				var nextStep:Int = Math.floor((Conductor.songPosition) / Conductor.stepCrochet);
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
						// Song reset?
						trace("(no bpm change) reset steps for some reason?? at " + Conductor.songPosition);
						curStep = nextStep;
						updateBeat();
						stepHit();
					}
				}
			}
		}

		(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
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
			leState.openSubState(new PsychTransition(0.75, false));
			if (nextState == FlxG.state)
			{
				PsychTransition.finishCallback = function()
				{
					MusicBeatState.switchingState = false;
					FlxG.resetState();
				};
				// trace('resetted');
			}
			else
			{
				PsychTransition.finishCallback = function()
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

	private function updateBeat():Void
	{
		lastBeat = curBeat;
		curBeat = Math.floor(curStep / 4);
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
}
