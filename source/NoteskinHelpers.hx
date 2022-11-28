#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;

using StringTools;

class NoteskinHelpers
{
	public static var noteskinArray = [];
	public static var xmlData = [];

	public static function updateNoteskins()
	{
		noteskinArray = [];
		xmlData = [];

		noteskinArray = ["Arrows", "Circles", "Voltex-Arrows", "Voltex-Circles", "Voltex-Bars"];

		return noteskinArray;
	}

	public static function getNoteskins()
	{
		return noteskinArray;
	}

	public static function getNoteskinByID(id:Int)
	{
		return noteskinArray[id];
	}

	static public function generateNoteskinSprite(id:Int)
	{
		Debug.logTrace("bruh momento");

		return Paths.getSparrowAtlas('noteskins/${NoteskinHelpers.getNoteskinByID(FlxG.save.data.noteskin)}', 'shared');
	}

	static public function generatePixelSprite(id:Int, ends:Bool = false)
	{
		return Paths.image('noteskins/${NoteskinHelpers.getNoteskinByID(FlxG.save.data.noteskin)}-pixel${(ends ? '-ends' : '')}', "shared");
	}
}
