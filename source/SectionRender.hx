import ChartEventHandler.ChartEvent;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import Section.SwagSection;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import CoolUtil.CoolText;

@:deprecated
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
	public var attachedEvents:Array<ChartEvent>;

	public var beat:Float = 0;

	var text:CoolText;

	public function new(x:Float, y:Float, attachedEvents:Array<ChartEvent>)
	{
		super(x, y);

		this.attachedEvents = attachedEvents;
		beat = attachedEvents[0].beat;
		text = new CoolText(0, -35, 16, 16, Paths.bitmapFont('fonts/pixel'));
		text.autoSize = true;

		var arrow = new FlxSprite(-55, 0).loadGraphic(Paths.image('eventArrow', 'shared'));
		arrow.setGraphicSize(40, 40);
		arrow.updateHitbox();
		arrow.y = -15;
		var line = new FlxSprite(0, 0).makeGraphic(Std.int(320), 4, FlxColor.BLUE);

		add(text);
		add(arrow);
		add(line);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		beat = attachedEvents[0].beat;
	}

	public function updateText()
	{
		var rawText = '';
		for (event in attachedEvents)
		{
			var eventInfo = ChartingState.instance.chartEventHandler.chartEvents.get(event.name);
			rawText += (eventInfo == null ? event.name : eventInfo.displayName) + '\n';
		}
		text.text = 'Event Object - Beat: $beat\nEvents:\n' + rawText;

		text.x = -text.fieldWidth - 350;
		text.y = -50 - text.textHeight;
	}

	override function destroy()
	{
		attachedEvents.resize(0);
		super.destroy();
	}
}

class BeatLineRender extends FlxSprite
{
	public var strumTime:Float = 0;

	public var beat:Int = 0;

	var GRID_SIZE:Int = 0;

	public function new(GRID_SIZE:Int = 40, beat:Int)
	{
		super(x, y);
		this.beat = beat;
		this.GRID_SIZE = GRID_SIZE;
		strumTime = TimingStruct.getTimeFromBeat(beat);
	}

	public function load()
	{
		makeGraphic(Std.int(GRID_SIZE * 8), 2, FlxColor.ORANGE);
	}
}

class SustainRender extends FlxSprite
{
	public var parent:NoteSpr = null;

	public function new()
	{
		super(x, y);
	}

	override function destroy()
	{
		parent = null;
		super.destroy();
	}
}
