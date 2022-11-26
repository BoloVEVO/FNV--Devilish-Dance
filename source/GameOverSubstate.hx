package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	public var bf:Boyfriend;

	public var dad:Character;

	var camFollow:FlxObject;

	var stageSuffix:String = "";

	public static var instance:GameOverSubstate;

	override function create()
	{
		Paths.clearUnusedMemory();
		instance = this;

		super.create();
	}

	public function new(x:Float, y:Float)
	{
		var daStage = PlayState.Stage.curStage;
		var daBf:String = '';
		switch (PlayState.boyfriend.curCharacter)
		{
			case 'bf-pixel':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			case 'bf-holding-gf':
				daBf = 'bf-holding-gf-dead';
			default:
				daBf = 'bf';
		}

		super();

		Conductor.songPosition = 0;

		if (PlayStateChangeables.opponentMode)
		{
			dad = new Character(x, y, PlayState.dad.curCharacter);
			camFollow = new FlxObject(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y, 1, 1);
			add(dad);
		}
		else
		{
			bf = new Boyfriend(x, y, daBf);
			camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
			add(bf);
		}

		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		if (PlayStateChangeables.opponentMode)
		{
			dad.animation.curAnim.frameRate = 24; // Force default frameRate if bf dies in non 1x Formats.
			dad.playAnim('firstDeath');
		}
		else
		{
			bf.animation.curAnim.frameRate = 24; // Force default frameRate if bf dies in non 1x Formats.
			bf.playAnim('firstDeath');
		}
	}

	var startVibin:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
			{
				GameplayCustomizeState.freeplayNoteStyle = 'normal';
				MusicBeatState.switchState(new StoryMenuState());
			}
			else
				MusicBeatState.switchState(new FreeplayState());
			PlayState.loadRep = false;
		}

		if ((!PlayStateChangeables.opponentMode && bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
			|| (PlayStateChangeables.opponentMode && dad.animation.curAnim.name == 'firstDeath' && dad.animation.curAnim.curFrame == 12))
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		}

		if ((!PlayStateChangeables.opponentMode && bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
			|| (PlayStateChangeables.opponentMode && dad.animation.curAnim.name == 'firstDeath' && dad.animation.curAnim.finished))
		{
			if (PlayState.SONG.stage == 'tank' && !PlayStateChangeables.opponentMode)
			{
				FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix), 0.2);
				FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25), 'week7'), 1, false, null, true, function()
				{
					if (!isEnding)
					{
						FlxG.sound.music.fadeIn(0.2, 1, 4);
					}
				});
			}
			else
				FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));

			startVibin = true;
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (startVibin && !isEnding)
		{
			if (PlayStateChangeables.opponentMode)
			{
				dad.playAnim('deathLoop', true);
			}
			else
			{
				bf.playAnim('deathLoop', true);
			}
		}
		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			PlayState.startTime = 0;
			isEnding = true;
			if (PlayStateChangeables.opponentMode)
			{
				if (dad.animOffsets.exists('deathConfirm'))
					dad.playAnim('deathConfirm', true);
			}
			else
			{
				if (bf.animOffsets.exists('deathConfirm'))
					bf.playAnim('deathConfirm', true);
			}

			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
