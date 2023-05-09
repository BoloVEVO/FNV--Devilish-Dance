import flixel.util.FlxColor;
import flixel.FlxSprite;

class ChartingBox extends FlxSprite
{
	public function new(x, y)
	{
		super(x, y);

		makeGraphic(40, 40, FlxColor.fromRGB(173, 216, 230));
		alpha = 0.4;
	}
}
