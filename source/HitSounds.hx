using StringTools;

class HitSounds
{
	public static var soundArray:Array<String> = [
		'None',
		'Quaver',
		'Osu',
		'Clap',
		'Camellia',
		'StepMania',
		'21st Century Humor',
		'Vine BOOM'
	];

	public static function getSound()
	{
		return soundArray;
	}

	public static function getSoundByID(id:Int)
	{
		return soundArray[id];
	}
}
