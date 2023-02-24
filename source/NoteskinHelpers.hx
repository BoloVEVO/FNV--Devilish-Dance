#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;

using StringTools;

class NoteskinHelpers
{
	public static var noteskinArray = [];

	public static function updateNoteskins()
	{
		noteskinArray = [];

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

	static public function generateNoteskinSprite(id:Int, type:String, unique:Bool)
	{
		// Debug.logTrace("bruh momento");

		if (type == null)
			type = '';

		var suffix = '_$type';

		if (type == '')
			suffix = '';

		var atlas = null;

		if (unique)
			atlas = Paths.getSparrowAtlas('noteskins/NOTE$suffix', 'shared');
		else
			atlas = Paths.getSparrowAtlas('noteskins/${NoteskinHelpers.getNoteskinByID(FlxG.save.data.noteskin)}$suffix', 'shared');

		return atlas;
	}

	static public function generatePixelSprite(id:Int, type:String, unique:Bool, ends:Bool = false)
	{
		if (type == null)
			type = '';

		var suffix = '_$type';

		if (type == '')
			suffix = '';

		var image = null;
		if (unique)
			image = Paths.image('noteskins/NOTE-pixel${(ends ? '-ends' : '')}$suffix', "shared");
		else
			image = Paths.image('noteskins/${NoteskinHelpers.getNoteskinByID(FlxG.save.data.noteskin)}-pixel${(ends ? '-ends' : '')}$suffix', "shared");
		return image;
	}
}
