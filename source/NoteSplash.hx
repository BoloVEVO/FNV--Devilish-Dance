package;

import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
	public var noteType:String = '';
	public var noteData:Int = 0;

	public function new(x:Float = 0, y:Float = 0, noteType:String, noteData:Int)
	{
		super(x, y);

		this.noteType = noteType;
		this.noteData = noteData;

		antialiasing = FlxG.save.data.antialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float)
	{
		visible = true;
		setPosition(x - NoteSpr.swagWidth * 0.95, y - NoteSpr.swagWidth);

		switch (noteData)
		{
			default:
				this.x += 20;
				this.y += 10;
		}
		alpha = 0.6;

		loadAnims(noteType, noteData);

		var animNum:Int = FlxG.random.int(0, 1);

		animation.play('splash ' + animNum + " " + noteData);

		animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);

		animation.finishCallback = function(name:String)
		{
			visible = false;
			kill();
		}
	}

	function loadAnims(noteType:String, noteData:Int)
	{
		var styleShit = PlayState.SONGStyle.replaceSplashTextures ? PlayState.SONG.songStyle : 'default';
		var shit = 'hud/$styleShit/noteskins/${NoteskinHelpers.getNoteskinByID(FlxG.save.data.noteskin)}/NOTESPLASH_${noteType.toUpperCase()}';

		frames = Paths.getSparrowAtlas(shit, 'shared');

		animation.addByPrefix('splash 0 0', 'note splash 1 purple', 24, false);
		animation.addByPrefix('splash 0 1', 'note splash 1  blue', 24, false);
		animation.addByPrefix('splash 0 2', 'note splash 1 green', 24, false);
		animation.addByPrefix('splash 0 3', 'note splash 1 red', 24, false);
		animation.addByPrefix('splash 1 0', 'note splash 2 purple', 24, false);
		animation.addByPrefix('splash 1 1', 'note splash 2 blue', 24, false);
		animation.addByPrefix('splash 1 2', 'note splash 2 green', 24, false);
		animation.addByPrefix('splash 1 3', 'note splash 2 red', 24, false);

		animation.followGlobalSpeed = false;
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null)
		{
			if (animation.curAnim.finished)
				kill();
		}

		super.update(elapsed);
	}
}
