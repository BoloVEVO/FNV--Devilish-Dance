package;

import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import haxe.Json;
import haxe.format.JsonParser;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

using StringTools;

typedef ChartEvent =
{
	var name:String;
	var beat:Float;
	var args:Array<Dynamic>;
}

typedef ChartEventArg =
{
	var name:String;
	var type:String;
}

typedef ChartEventInfo =
{
	var func:Array<Dynamic>->Void;
	// Desc can be null because it's only needed for chartEventMeta
	var ?displayName:String;

	var ?description:String;
	var args:Array<ChartEventArg>;
}

class ChartEventHandler
{
	var playState:PlayState;

	public var chartEvents:Map<String, ChartEventInfo> = null;

	var parsedEvents:Array<ChartEvent> = [];

	public function new(inEditor:Bool = false, ?state:PlayState = null)
	{
		if (!inEditor)
			playState = state;

		chartEvents = [
			"changeBPM" => {
				func: changeBPM,
				displayName: "Change BPM",
				description: "Change Song BPM",
				args: [{name: "bpm", type: "Float"}]
			},
			"changeScrollSpeed" => {
				func: changeScrollSpeed,
				displayName: "Change Scroll Speed",
				description: "Change how fast notes scroll\n\nValue 1: new Velocity, Duration it takes to completelty change.",
				args: [
					{
						name: "Velocity,Duration",
						type: "Array"
					}
				]
			},
			"changeChar" => {
				func: changeCharacter,
				displayName: "Change Character",
				description: "",
				args: [
					{
						name: "Target",
						type: "String"
					},
					{
						name: "New Character Name",
						type: "String"
					}
				]
			}
		];

		if (inEditor)
		{
			for (event in chartEvents)
			{
				event.func = null;
			}
		}
	}

	public function processChartEvent(event:ChartEvent):Void
	{
		if (!parsedEvents.contains(event))
			return;

		Debug.logTrace('BEAT ${event.beat}: Executing Chart Event ${event.name} with arguments ${event.args}');
		chartEvents[event.name].func(event.args);
	}

	public function checkChartEvent(event:ChartEvent):Void
	{
		var eventExists:Bool = false;
		for (key => value in chartEvents)
		{
			if (key == event.name)
			{
				eventExists = true;
				break;
			}
		}
		if (!eventExists)
		{
			Debug.logError('Error: Chart Event ${event.name} does not exist!');
			return;
		}

		if (event.args.length < chartEvents[event.name].args.length)
		{
			Debug.logError('Error: Insufficient arguments for Chart Event ${event.name} (Found: ${event.args.length}, Expected: ${chartEvents[event.name].args.length})');
			return;
		}
		for (i in 0...chartEvents[event.name].args.length)
		{
			if (!isExpectedClass(event.args[i], chartEvents[event.name].args[i].type))
			{
				Debug.logError('Error: Chart Event ${event.name} argument ${event.args[i]} is of unexpected type ${Type.getClassName(event.args[i])}! Expected: ${chartEvents[event.name].args[i].type}');
				return;
			}
		}

		parsedEvents.push(event);
	}

	function isExpectedClass(arg:Dynamic, className:String):Bool
	{
		if (className == "Bool")
			return Std.isOfType(arg, Bool);
		else if (className == "Array")
			return arg.length != null && !Std.isOfType(arg, String);
		return Std.isOfType(arg, Type.resolveClass(className));
	}

	function changeBPM(args:Array<Dynamic>):Void
	{
		Debug.logTrace('BPM changed to ${args[0]}');
	}

	function changeScrollSpeed(args:Array<Dynamic>):Void
	{
		playState.changeScrollSpeed(args[0][0], args[0][1], FlxEase.linear);
	}

	function changeCharacter(args:Dynamic):Void
	{
		playState.changeChar(args[0], args[1]);
	}

	public function destroy()
	{
		chartEvents = null;
		parsedEvents.resize(0);
	}
}
