import haxe.Timer;
import openfl.display.FPS;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.Lib;
import flixel.math.FlxMath;
import haxe.Int64;
import openfl.system.System;

class StatsCounter extends TextField
{
	public var currentFPS(default, null):Int;

	private var times:Array<Float>;

	public var memoryMegas:Dynamic = 0;

	public var taskMemoryMegas:Dynamic = 0;

	public var memoryUsage:String = '';

	static var engineName = "KE ";

	private var cacheCount:Int;

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{
		super();

		x = inX;

		y = inY;

		selectable = false;

		defaultTextFormat = new TextFormat('VCR OSD Mono', 14, inCol);

		text = "FPS: ";

		currentFPS = 0;

		cacheCount = 0;

		times = [];

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 300;

		height = 70;
	}

	var array:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 255),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(255, 255, 0),
		FlxColor.fromRGB(255, 127, 0),
		FlxColor.fromRGB(255, 0, 0)
	];

	var skippedFrames = 0;

	public static var currentColor = 0;

	private function onEnter(_)
	{
		if (FlxG.save.data.fpsRain)
		{
			if (currentColor >= array.length)
				currentColor = 0;
			currentColor = Math.round(FlxMath.lerp(0, array.length, skippedFrames / (FlxG.save.data.fpsCap / 3)));
			(cast(Lib.current.getChildAt(0), Main)).changeFPSColor(array[currentColor]);
			currentColor++;
			skippedFrames++;
			if (skippedFrames > (FlxG.save.data.fpsCap / 3))
				skippedFrames = 0;
		}

		var now = Timer.stamp();

		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > FlxG.save.data.fpsCap)
			currentFPS = FlxG.save.data.fpsCap;

		if (visible)
		{
			memoryUsage = (FlxG.save.data.memoryDisplay ? "RAM: " : "");
			#if !html5
			memoryMegas = Int64.make(0, System.totalMemory);

			taskMemoryMegas = Int64.make(0, MemoryUtil.getMemoryfromProcess());

			if (FlxG.save.data.memoryDisplay)
			{
				if (memoryMegas >= 0x40000000)
					memoryUsage += (Math.round(cast(memoryMegas, Float) / 0x400 / 0x400 / 0x400 * 1000) / 1000) + " GB";
				else if (memoryMegas >= 0x100000)
					memoryUsage += (Math.round(cast(memoryMegas, Float) / 0x400 / 0x400 * 1000) / 1000) + " MB";
				else if (memoryMegas >= 0x400)
					memoryUsage += (Math.round(cast(memoryMegas, Float) / 0x400 * 1000) / 1000) + " KB";
				else
					memoryUsage += memoryMegas + " B";

				#if windows
				if (taskMemoryMegas >= 0x40000000)
					memoryUsage += " (" + (Math.round(cast(taskMemoryMegas, Float) / 0x400 / 0x400 / 0x400 * 1000) / 1000) + " GB)";
				else if (taskMemoryMegas >= 0x100000)
					memoryUsage += " (" + (Math.round(cast(taskMemoryMegas, Float) / 0x400 / 0x400 * 1000) / 1000) + " MB)";
				else if (taskMemoryMegas >= 0x400)
					memoryUsage += " (" + (Math.round(cast(taskMemoryMegas, Float) / 0x400 * 1000) / 1000) + " KB)";
				else
					memoryUsage += "(" + taskMemoryMegas + " B)";
				#end
			}

			/*if (FlxG.save.data.gpuRender)
					memoryUsage = (FlxG.save.data.memoryDisplay?"Memory Usage: " + memoryMegas + " MB / " + memoryTotal + " MB" + "\nGPU Usage: " + gpuMemory
						+ " MB" #if debug
						+ gpuInfo #end : "");
				else */
			#else
			memoryMegas = HelperFunctions.truncateFloat((MemoryUtil.getMemoryfromProcess() / (1024 * 1024)) * 10, 3);
			memoryUsage += memoryMegas + " MB";
			#end

			text = (FlxG.save.data.fps ? "FPS: "
				+ '${currentFPS}\n'
				+ '$memoryUsage'
				+ (Main.watermarks?'\n$engineName' + "v" + MainMenuState.kadeEngineVer + "\nFNV: Devilish Dance 1.0" #if debug
					+ "\nDEBUG MODE" #end : "") : memoryUsage
				+ (Main.watermarks?'\n$engineName' + "v" + MainMenuState.kadeEngineVer + "\nFNV: Devilish Dance 1.0" #if debug + "\nDEBUG MODE" #end : ""));
		}

		cacheCount = currentCount;
	}
}
