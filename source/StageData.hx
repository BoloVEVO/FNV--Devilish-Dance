package;

typedef StageData =
{
	var ?staticCam:Bool;
	var ?camZoom:Float;
	var ?camPosition:Array<Float>;
	var ?loadGF:Bool;
	var ?charPositions:Map<String, Array<Float>>;
	var ?spritesPositions:Map<String, Array<Float>>;
	var ?spriteGroupPositions:Map<String, Map<Int, Array<Float>>>;
}

class StageJSON
{
	public static function loadJSONFile(stage:String):StageData
	{
		var rawJson = Paths.loadJSON('stages/$stage/$stage');
		return parseWeek(rawJson);
	}

	public static function parseWeek(json:Dynamic):StageData
	{
		var weekData:StageData = cast json;

		return weekData;
	}
}
