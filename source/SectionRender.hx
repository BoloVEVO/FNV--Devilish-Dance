import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import Section.SwagSection;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

class SectionRender extends FlxSpriteGroup
{
	public var section:SwagSection;

	public var sectionID:Int;
	public var mustHit:Bool;

	var gridBF:FlxSprite;

	var gridDAD:FlxSprite;

	var gridBlackLine:FlxSprite;

	public var songEvents:Array<Song.Event> = [];

	public function new(x:Float, y:Float, GRID_SIZE:Int, Height:Int, ?sectionID:Int)
	{
		super(x, y);

		this.sectionID = sectionID;

		gridBF = FlxGridOverlay.create(GRID_SIZE, Std.int(GRID_SIZE), GRID_SIZE * 4, Height, true);

		gridDAD = FlxGridOverlay.create(GRID_SIZE, Std.int(GRID_SIZE), GRID_SIZE * 4, Height, true);
		gridDAD.x += GRID_SIZE * 4;

		gridBlackLine = new FlxSprite(gridBF.width).makeGraphic(2, Math.floor(Math.abs(Height)), FlxColor.BLACK);

		add(gridBF);
		add(gridDAD);
		add(gridBlackLine);
	}

	override function update(elapsed)
	{
		super.update(elapsed);
		if (!mustHit)
		{
			gridBF.alpha = 1;
			gridDAD.alpha = 0.5;
		}
		else
		{
			gridBF.alpha = 0.5;
			gridDAD.alpha = 1;
		}
	}

	override function destroy()
	{
		gridDAD.graphic.bitmap.dispose();
		gridBF.graphic.bitmap.dispose();
		super.destroy();

		gridBF.destroy();
		gridDAD.destroy();
		gridBlackLine.destroy();
		section = null;
	}
}

class EventRender extends FlxSpriteGroup
{
	public var eventTime:Float = 0;

	public var showing:Bool = false;

	public function new(x:Float, y:Float, name:String, type:String, value:Dynamic, time:Float)
	{
		super(x, y);
		eventTime = time;
		var text = new FlxText(-190, 0, 0, name + "\n" + type + "\n" + value, 12);
		var line = new FlxSprite(0, 0).makeGraphic(Std.int(320), 4, FlxColor.BLUE);
		add(text);
		add(line);
	}
}
