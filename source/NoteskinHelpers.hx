#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;

using StringTools;

class NoteskinHelpers
{
	public static var noteskinArray = ["Arrows", "Circles", "Voltex-Arrows", "Voltex-Circles", "Voltex-Bars"];

	public static function getNoteskins()
	{
		return noteskinArray;
	}

	public static function getNoteskinByID(id:Int)
	{
		return noteskinArray[id];
	}

	static public function generateNoteskinSprite(id:Int, type:String, style:String = 'default')
	{
		// Debug.logTrace("bruh momento");

		if (type == null)
			type = '';

		var suffix = '_${type.toUpperCase()}';

		if (type == '')
			suffix = '_NORMAL';

		var atlas = null;

		atlas = Paths.getSparrowAtlas('hud/$style/noteskins/${NoteskinHelpers.getNoteskinByID(FlxG.save.data.noteskin)}/NOTE_ASSETS$suffix', 'shared');

		return atlas;
	}

	static public function generatePixelSprite(id:Int, ends:Bool = false, type:String)
	{
		var suffix = '_${type.toUpperCase()}';

		if (type == '')
			suffix = '_NORMAL';

		return Paths.image('hud/pixel/noteskins/${NoteskinHelpers.getNoteskinByID(FlxG.save.data.noteskin)}/NOTE_ASSETS$suffix${(ends ? '_ENDS' : '')}',
			"shared");
	}
}
