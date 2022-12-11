package;

import LuaClass;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import PlayState;
import flixel.util.FlxColor;

using StringTools;

class StaticArrow extends FlxSprite
{
	#if FEATURE_LUAMODCHART
	public var luaObject:LuaReceptor;
	#end
	public var modifiedByLua:Bool = false;
	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside here

	public var direction:Float = 90;

	public var downScroll:Bool = false;

	public var bgLane:FlxSprite;

	public function new(xx:Float, yy:Float)
	{
		x = xx;
		y = yy;
		super(x, y);
		updateHitbox();

		bgLane = new FlxSprite(0, 0).makeGraphic(112, 2160);
		bgLane.antialiasing = FlxG.save.data.antialiasing;
		bgLane.color = FlxColor.BLACK;
		bgLane.visible = true;
		bgLane.alpha = FlxG.save.data.laneTransparency * alpha;
		bgLane.x = x;
		bgLane.y += -300;
		bgLane.updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (!modifiedByLua)
			angle = localAngle + modAngle;
		else
			angle = modAngle;
		super.update(elapsed);

		/*if (FlxG.keys.justPressed.THREE)
			{
				localAngle += 10;
		}*/

		// bgLane.angle = direction;
		bgLane.angle = direction - 90 + modAngle;
		bgLane.x = x;
		bgLane.alpha = FlxG.save.data.laneTransparency * alpha;
		bgLane.visible = visible;
	}

	public function playAnim(AnimName:String, ?force:Bool = false):Void
	{
		animation.play(AnimName, force);

		if (!AnimName.startsWith('dirCon'))
		{
			localAngle = 0;
		}
		updateHitbox();
		offset.set(frameWidth / 2, frameHeight / 2);

		offset.x -= 54;
		offset.y -= 56;

		angle = localAngle + modAngle;
	}
}
