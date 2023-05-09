import Ratings.RatingWindow;
import LuaClass;
import flixel.FlxG;

class NoteDef
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
	public var prevNote:NoteDef;
	public var modifiedByLua:Bool = false;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var isSustainEnd:Bool = false;

	public var noteSection:Int = 0;

	public var luaID:Int = 0;

	public var noteScore:Float = 1;

	public var noteYOff:Float = 0;

	public var beat:Float = 0;

	public var noteType:String = 'normal';

	public var isParent:Bool = false;
	public var parent:NoteDef = null;
	public var spotInLine:Int = 0;
	public var sustainActive:Bool = false;

	public var children:Array<NoteDef> = [];

	public var stepHeight:Float = 0;

	var leSpeed:Float = 0;

	var leBpm:Float = 0;

	public var rating:RatingWindow;

	public var distance:Float = 2000;

	public var lowPriority:Bool = false;

	public var lateHitMult:Float = 1.0;
	public var earlyHitMult:Float = 1.0;

	public var insideCharter:Bool = false;

	public var speedMultiplier:Float = 1.0;

	public var connectedNote:NoteSpr = null;

	public var noteStyle:String = 'default';

	public function new(strumTime:Float, noteData:Int, ?prevNote:NoteDef, ?sustainNote:Bool = false, ?inCharter:Bool = false, ?bet:Float = 0,
			?noteType:String = 'normal', ?speedMultiplier:Float = 1.0, ?noteStyle:String = 'default')
	{
		if (prevNote == null)
			prevNote = this;

		beat = bet;

		this.prevNote = prevNote;
		this.isSustainNote = sustainNote;
		this.noteStyle = noteStyle;
		insideCharter = inCharter;

		this.noteType = noteType;
		this.speedMultiplier = speedMultiplier;

		lateHitMult = isSustainNote ? 0.5 : 1;

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

		preloadNoteFrames();
	}

	function preloadNoteFrames()
	{
		if (PlayState.isPixelStage)
		{
			NoteskinHelpers.generatePixelSprite(FlxG.save.data.noteskin, false, noteType);
			NoteskinHelpers.generatePixelSprite(FlxG.save.data.noteskin, true, noteType);
		}
		else
			NoteskinHelpers.generateNoteskinSprite(FlxG.save.data.noteskin, noteType, noteStyle);

		var styleShit = PlayState.SONGStyle.replaceSplashTextures ? noteStyle : 'default';
		Paths.getSparrowAtlas('hud/$styleShit/noteskins/${NoteskinHelpers.getNoteskinByID(FlxG.save.data.noteskin)}/NOTESPLASH_${noteType.toUpperCase()}',
			'shared');
	}
}
