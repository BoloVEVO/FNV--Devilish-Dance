package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import LuaClass;
import PlayState;
import flixel.util.FlxDestroyUtil;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var baseStrum:Float = 0;

	public var charterSelected:Bool = false;

	public var rStrumTime:Float = 0;
	#if FEATURE_LUAMODCHART
	public var LuaNote:LuaNote;
	#end
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var rawNoteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var modifiedByLua:Bool = false;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var isSustainEnd:Bool = false;
	public var originColor:Int = 0; // The sustain note's original note's color
	public var noteSection:Int = 0;

	public var luaID:Int = 0;

	public var isAlt:Bool = false;

	public var noteCharterObject:FlxSprite;

	public var noteScore:Float = 1;

	public var noteYOff:Float = 0;

	public var beat:Float = 0;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var rating:String = "shit";

	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside Note.hx
	public var originAngle:Float = 0; // The angle the OG note of the sus note had (?)

	public var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];
	public var quantityColor:Array<Int> = [RED_NOTE, 2, BLUE_NOTE, 2, PURP_NOTE, 2, GREEN_NOTE, 2];
	public var arrowAngles:Array<Int> = [180, 90, 270, 0];

	public var noteType:String = 'normal';

	public var isParent:Bool = false;
	public var parent:Note = null;
	public var spotInLine:Int = 0;
	public var sustainActive:Bool = false;

	public var children:Array<Note> = [];

	public var stepHeight:Float = 0;

	var leSpeed:Float = 0;

	var leBpm:Float = 0;

	public var distance:Float = 2000;

	public var lowPriority:Bool = false;

	public var lateHitMult:Float = 0.5;
	public var earlyHitMult:Float = 1.0;

	public var insideCharter:Bool = false;

	public var noteLoaded:Bool = false;

	public var uniqueSkinType:Bool = false; // If the note type will have a unique sprite for all skins.

	public var followAngle:Bool = false;

	public var overrideDistance:Bool = false; // Set this to true if you know what are you doing.

	public var speedMultiplier:Float = 1.0;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inCharter:Bool = false, ?isAlt:Bool = false,
			?bet:Float = 0, ?noteType:String = 'normal', ?speedMultiplier:Float = 1.0)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		beat = bet;

		this.isAlt = isAlt;

		this.prevNote = prevNote;
		this.isSustainNote = sustainNote;
		insideCharter = inCharter;

		if (noteType == null || noteType == '0')
			noteType = 'normal';

		this.noteType = noteType;
		this.speedMultiplier = speedMultiplier;

		// HERE ESTABLISH IF YOUR NOTE TYPE
		switch (noteType)
		{
			case 'hurt':
				lowPriority = true;
				uniqueSkinType = false;
			default:
				lowPriority = false;
				uniqueSkinType = false;
		}

		lateHitMult = isSustainNote ? 0.5 : 1;

		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		if (inCharter)
		{
			this.strumTime = strumTime;
			rStrumTime = strumTime;
		}
		else
		{
			this.strumTime = strumTime;
			#if FEATURE_STEPMANIA
			if (PlayState.isSM)
			{
				rStrumTime = strumTime;
			}
			else
				rStrumTime = strumTime;
			#else
			rStrumTime = strumTime;
			#end
		}

		if (this.strumTime < 0)
			this.strumTime = 0;

		this.noteData = noteData;

		// YOOO WTF IT WORKED???!!!
		if (PlayStateChangeables.mirrorMode)
		{
			this.noteData = Std.int(Math.abs(3 - noteData));
			noteData = Std.int(Math.abs(3 - noteData));
		}

		if (!FlxG.save.data.postProcessNotes)
			loadNote();
	}

	public function loadNote():Void
	{
		// defaults if no noteStyle was found in chart
		var noteStyleCheck:String = 'normal';

		if (insideCharter)
		{
			switch (noteStyleCheck)
			{
				case 'pixel':
					loadGraphic(NoteskinHelpers.generatePixelSprite(FlxG.save.data.noteskin, noteType, false), true, 17, 17);
					if (isSustainNote)
						loadGraphic(NoteskinHelpers.generatePixelSprite(FlxG.save.data.noteskin, noteType, false, true), true, 7, 6);
				default:
					frames = NoteskinHelpers.generateNoteskinSprite(FlxG.save.data.noteskin, noteType, uniqueSkinType);
			}

			for (i in 0...4)
			{
				animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
				animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
				animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
			}

			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			antialiasing = FlxG.save.data.antialiasing;
		}
		else
		{
			if (PlayState.SONG.noteStyle == null)
			{
				switch (PlayState.storyWeek)
				{
					case 6:
						noteStyleCheck = 'pixel';
				}
			}
			else
			{
				noteStyleCheck = PlayState.SONG.noteStyle;
			}
		}

		switch (noteStyleCheck)
		{
			case 'pixel':
				loadGraphic(NoteskinHelpers.generatePixelSprite(FlxG.save.data.noteskin, noteType, uniqueSkinType), true, 17, 17);
				if (isSustainNote)
					loadGraphic(NoteskinHelpers.generatePixelSprite(FlxG.save.data.noteskin, noteType, uniqueSkinType, true), true, 7, 6);

				for (i in 0...4)
				{
					animation.add(dataColor[i] + 'Scroll', [i + 4]); // Normal notes
					animation.add(dataColor[i] + 'hold', [i]); // Holds
					animation.add(dataColor[i] + 'holdend', [i + 4]); // Tails
				}

				setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
				updateHitbox();
			default:
				frames = NoteskinHelpers.generateNoteskinSprite(FlxG.save.data.noteskin, noteType, uniqueSkinType);

				for (i in 0...4)
				{
					animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
					animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
					animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
				}

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();

				antialiasing = FlxG.save.data.antialiasing;
		}

		if (!insideCharter)
			x += swagWidth * (noteData % 4);

		animation.play(dataColor[noteData] + 'Scroll');
		originColor = noteData; // The note's origin color will be checked by its sustain notes

		if (FlxG.save.data.stepMania && !isSustainNote)
		{
			var col:Int = 0;

			var beatRow = Math.round(beat * 48);

			// STOLEN ETTERNA CODE (IN 2002)

			if (beatRow % (192 / 4) == 0)
				col = quantityColor[0];
			else if (beatRow % (192 / 8) == 0)
				col = quantityColor[2];
			else if (beatRow % (192 / 12) == 0)
				col = quantityColor[4];
			else if (beatRow % (192 / 16) == 0)
				col = quantityColor[6];
			else if (beatRow % (192 / 24) == 0)
				col = quantityColor[4];
			else if (beatRow % (192 / 32) == 0)
				col = quantityColor[4];

			animation.play(dataColor[col] + 'Scroll');
			if (FlxG.save.data.rotateSprites)
			{
				localAngle -= arrowAngles[col];
				localAngle += arrowAngles[noteData];
				originAngle = localAngle;
			}
			originColor = col;
		}

		stepHeight = (((0.45 * PlayState.instance.fakeNoteStepCrochet * PlayState.songMultiplier)) * FlxMath.roundDecimal(PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed,
			2) * speedMultiplier);

		if (isSustainNote && prevNote != null)
		{
			noteYOff = -stepHeight + swagWidth * 0.5;

			noteScore * 0.2;
			alpha = 0.6;

			if (FlxG.save.data.downscroll)
				flipY = true;

			x += width / 2;

			originColor = prevNote.originColor;
			originAngle = prevNote.originAngle;

			animation.play(dataColor[originColor] + 'holdend'); // This works both for normal colors and quantization colors
			updateHitbox();

			x -= width / 2;

			// if (noteStyleCheck == 'pixel')
			//	x += 30;

			if (insideCharter)
				x += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(dataColor[prevNote.originColor] + 'hold');
				prevNote.updateHitbox();

				prevNote.scale.y *= stepHeight / prevNote.height;
				prevNote.updateHitbox();

				if (antialiasing)
					switch (FlxG.save.data.noteskin)
					{
						case 0:
							prevNote.scale.y *= 1.0064 + (1.0 / prevNote.frameHeight);
						default:
							prevNote.scale.y *= 0.995 + (1.0 / prevNote.frameHeight);
					}
				prevNote.updateHitbox();
				updateHitbox();
			}
		}

		noteLoaded = true;
	}

	override function update(elapsed:Float)
	{
		// This updates hold notes height to current scroll Speed in case of scroll Speed changes.
		super.update(elapsed);

		var newStepHeight = (((0.45 * PlayState.instance.fakeNoteStepCrochet * PlayState.songMultiplier)) * FlxMath.roundDecimal(PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed,
			2) * speedMultiplier);

		if (stepHeight != newStepHeight)
		{
			stepHeight = newStepHeight;
			if (isSustainNote)
			{
				noteYOff = -stepHeight + swagWidth * 0.5;
			}
		}

		if (!modifiedByLua)
			angle = modAngle + localAngle;
		else
			angle = modAngle;

		if (!modifiedByLua)
		{
			if (!sustainActive && tooLate)
			{
				alpha = 0.3;
			}
		}

		if (!mustPress)
		{
			// CPU NOTES
			canBeHit = false;

			if (strumTime - Conductor.songPosition < (Ratings.timingWindows[0] * Conductor.timeScale) * earlyHitMult)
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}
		else
		{
			switch (noteType)
			{
				case 'hurt': // Really hard to hit
					if (strumTime - Conductor.songPosition <= ((Ratings.timingWindows[0] * Conductor.timeScale) * 0.2)
						&& strumTime - Conductor.songPosition >= (-Ratings.timingWindows[0] * Conductor.timeScale) * 0.4)
					{
						canBeHit = true;
					}
					else
					{
						canBeHit = false;
					}
					if (strumTime - Conductor.songPosition < -Ratings.timingWindows[0] && !wasGoodHit)
						tooLate = true;
				default:
					// PLAYER NOTES
					if (strumTime - Conductor.songPosition <= (((Ratings.timingWindows[0] * Conductor.timeScale) * lateHitMult))
						&& strumTime - Conductor.songPosition >= (((-Ratings.timingWindows[0] * Conductor.timeScale) * earlyHitMult)))
						canBeHit = true;
					else
						canBeHit = false;

					if (strumTime - Conductor.songPosition < (-Ratings.timingWindows[0] * Conductor.timeScale) && !wasGoodHit)
						tooLate = true;
			}
		}

		if (isSustainNote)
			isSustainEnd = spotInLine == parent.children.length - 1;

		if (tooLate && !wasGoodHit)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override function destroy()
	{
		super.destroy();

		if (noteCharterObject != null)
			noteCharterObject.destroy();
	}
}
