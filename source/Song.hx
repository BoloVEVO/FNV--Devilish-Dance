package;

import Section.SwagSection;
import haxe.Json;
import ChartEventHandler;

using StringTools;

@:deprecated
class Event
{
	public var name:String;
	public var position:Float;

	public var value:String;
	public var type:String;

	public var args:Array<Dynamic> = [];

	public var active:Bool = true;

	public function new(name:String, pos:Float, value:Dynamic, type:String)
	{
		this.name = name;
		this.position = pos;

		this.value = Std.string(value);

		if (this.value.indexOf(',') == -1)
			args[0] = this.value;
		else
			args = this.value.split(',');

		this.type = type;
	}
}

typedef StyleData =
{
	var styleName:String;
	var replaceNoteTextures:Bool;
	var replaceSplashTextures:Bool;
	var replaceHUDAssets:Bool;
	var replaceSounds:Bool;
	var replaceMusic:Bool;
	var antialiasing:Bool;
	var scaleFactor:Float;
}

class Style
{
	public static function loadJSONFile(style:String):StyleData
	{
		var rawJson = Paths.loadJSON('styles/$style');
		return parseWeek(rawJson);
	}

	public static function parseWeek(json:Dynamic):StyleData
	{
		var styleData:StyleData = cast json;

		return styleData;
	}
}

typedef EventData =
{
	var events:Array<ChartEvent>;
}

typedef SongData =
{
	@:deprecated
	var ?song:String;

	/**
	 * The readable name of the song, as displayed to the user.
	 		* Can be any string.
	 */
	var songName:String;

	/**
	 * The internal name of the song, as used in the file system.
	 */
	var songId:String;

	var chartVersion:String;
	var notes:Array<SwagSection>;
	var events:Array<ChartEvent>;
	var bpm:Float;
	var ?judgeStyle:Null<String>;
	var needsVoices:Bool;
	@:deprecated
	var ?eventObjects:Array<Event>;
	var speed:Float;
	var player1:String;
	var player2:String;
	var gfVersion:String;
	@:deprecated
	var noteStyle:String;
	var stage:String;
	var songStyle:String;
	var ?validScore:Bool;
	var ?offset:Int;
}

typedef SongMeta =
{
	var ?offset:Int;
	var ?name:String;
}

class Song
{
	public static var latestChart:String = "KE2";

	public static function loadFromJsonRAW(rawJson:String)
	{
		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var jsonData = Json.parse(rawJson);

		return parseJSONshit('rawsong', jsonData, 'rawname');
	}

	public static function loadFromJson(songId:String, difficulty:String):SongData
	{
		var songFile = '$songId/$songId$difficulty';

		Debug.logInfo('Loading song JSON: $songFile');

		var rawJson = Paths.loadJSON('songs/$songFile');
		var rawMetaJson = Paths.loadJSON('songs/$songId/_meta');

		return parseJSONshit(songId, rawJson, rawMetaJson);
	}

	public static function conversionChecks(song:SongData):SongData
	{
		var ba = song.bpm;

		var index = 0;
		trace("conversion stuff " + song.songId + " " + song.notes.length);

		if (song.eventObjects != null)
		{
			var convertedStuff:Array<Song.Event> = [];

			for (i in song.eventObjects)
			{
				var name = Reflect.field(i, "name");
				var type = Reflect.field(i, "type");
				var pos = Reflect.field(i, "position");
				var value = Reflect.field(i, "value");

				convertedStuff.push(new Song.Event(name, pos, value, type));
			}

			song.eventObjects = convertedStuff;

			if (song.eventObjects.length > 0)
			{
				if (song.events == null)
					song.events = [];
				for (i in song.eventObjects)
				{
					if (i.type == "BPM Change")
					{
						var newEvent:ChartEvent = {name: "changeBPM", beat: i.position, args: [CoolUtil.parseType(i.args[0], 'Float')]};
						Debug.logTrace(newEvent);
						song.events.push(newEvent);
					}
				}
			}
		}

		if (song.events == null)
		{
			var initBPM:ChartEvent = {name: "changeBPM", beat: 0, args: [song.bpm]};
			song.events = [initBPM];
		}

		if (song.events.filter(function(e:ChartEvent)
		{
			return e.name == 'changeBPM' && e.beat == 0;
		}).length == 0)
		{
			var initBPM:ChartEvent = {name: "changeBPM", beat: 0, args: [song.bpm]};
			song.events.push(initBPM);
		}

		if (song.noteStyle == null)
			song.noteStyle = "normal";

		if (song.gfVersion == null)
			song.gfVersion = "gf";

		TimingStruct.clearTimings();

		var currentIndex = 0;

		for (event in song.events)
		{
			if (event.name == "changeBPM")
			{
				var beat:Float = event.beat;
				var endBeat:Float = Math.POSITIVE_INFINITY;
				var bpm = event.args[0];

				TimingStruct.addTiming(beat, bpm, endBeat, 0);
				if (currentIndex != 0)
				{
					var data = TimingStruct.AllTimings[currentIndex - 1];
					data.endBeat = beat;
					data.length = ((data.endBeat - data.startBeat) / (data.bpm / 60));
					var step = ((60 / data.bpm) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step));
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
				}
				currentIndex++;
			}
		}

		// If the song has null sections.
		if (song.notes == null)
		{
			song.notes = [];

			song.notes.push(newSection(song));
		}

		if (song.notes.length == 0)
			song.notes.push(newSection(song));

		for (i in song.notes)
		{
			if (i.altAnim)
				i.CPUAltAnim = i.altAnim;

			var currentBeat = 4 * index;

			var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);

			if (currentSeg == null)
				continue;

			var beat:Float = currentSeg.startBeat + (currentBeat - currentSeg.startBeat);

			if (i.changeBPM && i.bpm != ba)
			{
				trace("converting changebpm for section " + index);
				ba = i.bpm;
				var bpmChangeEvent:ChartEvent = {name: "changeBPM", beat: beat, args: [i.bpm]};
				song.events.push(bpmChangeEvent);
			}

			index++;
		}

		// Convert old charts to new KE2 chart version
		/*if (song.chartVersion != 'KE2')
			{ */
		for (section in song.notes)
		{
			for (notes in section.sectionNotes)
			{
				if (section.mustHitSection)
				{
					var bool = false;
					if (notes[1] <= 3)
					{
						notes[1] += 4;
						bool = true;
					}
					if (notes[1] > 3)
						if (!bool)
							notes[1] -= 4;
				}

				if (notes[2] == -1) // REMOVE EVENT NOTES FROM OTHER ENGINES
					section.sectionNotes.remove(notes);

				if (notes[3] == null
					|| notes[3] == 'true'
					|| notes[3] == 'false'
					|| Std.isOfType(Std.parseInt(notes[3]), Int)
					|| Std.isOfType(Std.parseFloat(notes[3]), Float)
					|| Math.isNaN(notes[3]))
					notes[3] = 'normal';

				if (notes[4] == null
					|| notes[4] == 0
					|| notes[4] == 0.0
					|| Std.isOfType(Std.parseInt(notes[4]), Int)
					|| Std.isOfType(Std.parseFloat(notes[4]), Float)
					|| Math.isNaN(notes[4]))
					notes[4] = 1.0;

				if (song.chartVersion != 'KE2')
				{
					notes[3] = 'normal';
					notes[4] = 1.0;
				}
			}

			if (section.lengthInSteps == null)
				section.lengthInSteps = 16;
		}

		if (song.noteStyle == null || song.noteStyle == 'normal')
			song.songStyle = 'default';
		else
			song.songStyle = song.noteStyle;

		// }

		// sort events by beat
		if (song.events != null)
		{
			song.events.sort(function(a, b)
			{
				if (a.beat < b.beat)
					return -1
				else if (a.beat > b.beat)
					return 1;
				else
					return 0;
			});
		}

		song.chartVersion = latestChart;
		return song;
	}

	public static function parseJSONshit(songId:String, jsonData:Dynamic, jsonMetaData:Dynamic):SongData
	{
		var songData:SongData = cast jsonData.song;

		if (songData.songId == null)
			songData.songId = songId;

		if (songData.songName == null)
			songData.songName = songId;

		// Enforce default values for optional fields.
		if (songData.validScore == null)
			songData.validScore = true;

		// Inject info from _meta.json.
		var songMetaData:SongMeta = cast jsonMetaData;
		if (songMetaData != null)
		{
			if (songMetaData.name != null)
			{
				songData.songName = songMetaData.name;
			}
			else
			{
				songData.songName = songData.songName.split('-').join(' ');
			}

			songData.offset = songMetaData.offset != null ? songMetaData.offset : 0;
		}
		else
		{
			songData.songName = songData.songName.split('-').join(' ');
		}

		return Song.conversionChecks(songData);
	}

	private static function newSection(song:SongData, lengthInSteps:Int = 16, mustHitSection:Bool = false, CPUAltAnim:Bool = true,
			playerAltAnim:Bool = true):SwagSection
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: song.bpm,
			changeBPM: false,
			mustHitSection: mustHitSection,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			CPUAltAnim: CPUAltAnim,
			playerAltAnim: playerAltAnim
		};

		return sec;
	}

	public static function sortSectionNotes(song:SongData)
	{
		var newNotes:Array<Array<Dynamic>> = [];

		for (section in song.notes)
		{
			if (section.sectionNotes != null)
			{
				for (songNotes in section.sectionNotes)
				{
					newNotes.push(songNotes);
				}
			}
			section.sectionNotes.resize(0);
		}

		for (section in song.notes)
		{
			for (sortedNote in newNotes)
			{
				if (sortedNote[0] >= section.startTime && sortedNote[0] < section.endTime)
					section.sectionNotes.push(sortedNote);
			}
		}
	}
}
