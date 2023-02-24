package;

import Song.SongData;
import flixel.FlxG;
import flixel.util.FlxAxes;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxSpriteGroup;
import Options.AccuracyDOption;
import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;
import flixel.text.FlxText; #if FEATURE_FILESYSTEM import sys.io.File; #end

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['Easy', "Normal", "Hard", "Novice", "Advanced", "Exhaust", "Maximum", "Heavenly"];

	public static var suffixDiffsArray:Array<String> = [
		'-easy',
		"",
		"-hard",
		"-novice",
		"-advanced",
		"-exhaust",
		"-maximum",
		"-heavenly"
	];

	public static var pauseMenuItems:Array<String> = ['Resume', 'Restart Song', 'Options', 'Exit to menu'];

	public static var daPixelZoom:Float = 6;

	public static var noteTypes = ['normal', 'hurt'];

	public static function difficultyFromInt(difficulty:Int):String
	{
		return difficultyArray[difficulty];
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String>;

		try
		{
			daList = OpenFlAssets.getText(path).trim().split('\n');
		}
		catch (e)
		{
			daList = null;
		}

		if (daList != null)
			for (i in 0...daList.length)
			{
				daList[i] = daList[i].trim();
			}

		return daList;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function dashToSpace(string:String):String
	{
		return string.replace("-", " ");
	}

	public static function spaceToDash(string:String):String
	{
		return string.replace(" ", "-");
	}

	public static function swapSpaceDash(string:String):String
	{
		return StringTools.contains(string, '-') ? dashToSpace(string) : spaceToDash(string);
	}

	public static function coolStringFile(path:String):Array<String>
	{
		var daList:Array<String> = path.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function destroySong(daSong:SongData)
	{
		for (section in daSong.notes)
			for (songNotes in section.sectionNotes)
			{
				songNotes = [];
				songNotes = null;
			}

		daSong.notes = [];
		daSong.notes = null;

		daSong.eventObjects = [];
		daSong.eventObjects = null;

		daSong = null;
	}

	public static function getVariableName(v:Dynamic):String
	{
		for (fieldName in Reflect.fields(v))
		{
			if (Reflect.field(v, fieldName) == v)
			{
				return fieldName;
			}
		}
		return null;
	}
}

/*
	For some reason Flixel doesn't like FlxUINumericSteppers in multiple FlxUI boxes. So I have to replicate a new one.
 */
class CoolNumericStepper extends FlxSpriteGroup
{
	var currentValue:Float;

	public var stepperValue:Float;

	public var inputText:FlxUIInputText;

	public function new(x:Float, y:Float, width:Int, currentValue:String, stepperValue:Float, textSize:Int, name:String)
	{
		super(x, y);
		this.currentValue = Std.parseFloat(currentValue);
		this.stepperValue = stepperValue;

		var inputText:FlxUIInputText = new FlxUIInputText(0, 0, width, currentValue, textSize);
		this.inputText = inputText;
		add(inputText);
		var plusButton:FlxUIButton = new FlxUIButton(width, -3, "+", function()
		{
			this.currentValue += stepperValue;
			currentValue = Std.string(this.currentValue);
			inputText.text = Std.string(this.currentValue);
		});

		add(plusButton);
		plusButton.resize(20, plusButton.height);
		var minusButton:FlxUIButton = new FlxUIButton(plusButton.x + (plusButton.width / 2) - 1, -3, "-", function()
		{
			this.currentValue -= stepperValue;
			currentValue = Std.string(this.currentValue);
			inputText.text = Std.string(this.currentValue);
		});
		minusButton.resize(20, plusButton.height);

		add(minusButton);

		var nameText:FlxUIText = new FlxUIText(0, -17, name);
		add(nameText);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		currentValue = Std.parseFloat(inputText.text);
	}
}

/**
 * Edited of an Enhanced Bitmap Text class that doesn't consume memory because of modified properties.
 * WARNING: NON-LEFT ALIGNMENT might break some position properties such as X,Y and functions like screenCenter()
 * @param 	size	Be aware that this size property can could be not equal to FlxText size.
 * @param 	bitmapFont	Optional parameter for component's font prop
 */
class CoolText extends FlxBitmapText
{
	public function new(xPos:Float, yPos:Float, sizeX:Float, sizeY:Float, ?bitmapFont:FlxBitmapFont)
	{
		super(bitmapFont);
		x = xPos;
		y = yPos;
		scale.set(sizeX / 29.35, sizeY / 29.35);
	}

	override function destroy()
	{
		super.destroy();
	}

	override function update(elapsed)
	{
		super.update(elapsed);
	}
	/*public function centerXPos()
		{
			var offsetX = 0;
			if (alignment == FlxTextAlign.LEFT)
				x = ((FlxG.width - textWidth) / 2);
			else if (alignment == FlxTextAlign.CENTER)
				x = ((FlxG.width - (frameWidth - textWidth)) / 2) - frameWidth;
				
	}*/
}
