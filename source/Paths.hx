package;

import flixel.util.FlxDestroyUtil;
import flash.media.Sound;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import animateatlas.AtlasFrameMaker;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import lime.utils.Assets;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display3D.textures.Texture;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxBitmapFont;
#if cpp
import cpp.NativeGc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	inline public static var VIDEO_EXT = "mp4";

	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, ?library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);

			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static var currentTrackedSounds:Map<String, Sound> = [];

	// Sprite content caching with GPU based on Forever Engine texture compression.

	/**
	 * For a given key and library for an image, returns the corresponding BitmapData.
	 		* We can probably move the cache handling here.
	 * @param key 
	 * @param library 
	 * @return BitmapData
	 */
	static function loadImage(key:String, ?library:String, ?gpuRender:Bool)
	{
		var path:String = '';

		path = getPath('images/$key.png', IMAGE, library);

		// Debug.logTrace(path);
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;

		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var bitmap:BitmapData = OpenFlAssets.getBitmapData(path, false);

				var graphic:FlxGraphic = null;
				if (gpuRender)
				{
					bitmap.lock();
					var texture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
					texture.uploadFromBitmapData(bitmap);

					bitmap.disposeImage();

					FlxDestroyUtil.dispose(bitmap);

					bitmap = null;

					bitmap = BitmapData.fromTexture(texture);

					bitmap.unlock();
				}
				graphic = FlxGraphic.fromBitmapData(bitmap, false, path, false);

				graphic.persist = true;
				currentTrackedAssets.set(path, graphic);
			}
			else
			{
				// Get data from cache.
				// Debug.logTrace('Loading existing image from cache: $key');
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}

		Debug.logWarn('Could not find image at path $path');
		return null;
	}

	public static function loadSound(path:String, key:String, ?library:String)
	{
		// I hate this so god damn much

		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		var folder:String = '';

		if (path == 'songs')
			folder = 'songs:';

		// trace(gottenPath);
		if (OpenFlAssets.exists(folder + gottenPath, SOUND))
		{
			if (!currentTrackedSounds.exists(gottenPath))
			{
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + gottenPath));
			}
		}
		else
		{
			Debug.logWarn('Could not find sound at ${folder + gottenPath}');
		}

		localTrackedAssets.push(gottenPath);

		return currentTrackedSounds.get(gottenPath);
	}

	static public function getHaxeScript(string:String)
	{
		return Assets.getText('assets/data/$string/HaxeModchart.hx');
	}

	static public function loadJSON(key:String, ?library:String):Dynamic
	{
		var rawJson = '';

		try
		{
			rawJson = OpenFlAssets.getText(Paths.json(key, library)).trim();
			Debug.logTrace('Found $key');
		}
		catch (e)
		{
			Debug.logError('Error loading JSON. $e');
			rawJson = null;
		}

		// Perform cleanup on files that have bad data at the end.
		if (rawJson != null)
		{
			while (!rawJson.endsWith("}"))
			{
				rawJson = rawJson.substr(0, rawJson.length - 1);
			}
		}

		try
		{
			// Attempt to parse and return the JSON data.
			if (rawJson != null)
			{
				Debug.logTrace('JSON $key parsed successfully');
				return Json.parse(rawJson);
			}

			return null;
		}
		catch (e)
		{
			Debug.logError("AN ERROR OCCURRED parsing a JSON file.");
			Debug.logError(e.message);

			// Return null.
			return null;
		}
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';

		return returnPath;
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, ?library:String, type:AssetType = TEXT)
	{
		return getPath(file, type, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('data/$key.lua', TEXT, library);
	}

	inline static public function luaImage(key:String, ?library:String)
	{
		return getPath('data/$key.png', IMAGE, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function bitmapFont(key:String, ?library:String):FlxBitmapFont
	{
		return FlxBitmapFont.fromAngelCode(image(key, library), fontXML(key, library));
	}

	inline static public function fontXML(key:String, ?library:String):Xml
	{
		return Xml.parse(OpenFlAssets.getText(getPath('images/$key.fnt', TEXT, library)));
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline static public function animJson(key:String, ?library:String)
	{
		return getPath('images/$key/Animation.json', TEXT, library);
	}

	inline static public function spriteMapJson(key:String, ?library:String)
	{
		return getPath('images/$key/spritemap.json', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String):Any
	{
		var sound:Sound = loadSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?returnString:Bool = false, ?library:String):Any
	{
		var file:Dynamic;
		if (!returnString)
			file = loadSound('music', key, library);
		else
			file = getPath('music/$key.$SOUND_EXT', SOUND, library);
		return file;
	}

	inline static public function voices(song:String, ?returnString:Bool = false):Any
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase() + '/Voices';
		switch (songLowercase)
		{
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
			case 'm.i.l.f':
				songLowercase = 'milf';
		}

		var file:Dynamic;
		#if PRELOAD_ALL
		if (!returnString)
			file = loadSound('songs', songLowercase);
		else
			file = 'songs:assets/songs/$songLowercase.$SOUND_EXT';
		#else
		file = 'songs:assets/songs/$songLowercase.$SOUND_EXT';
		#end
		return file;
	}

	inline static public function inst(song:String, ?returnString:Bool = false):Any
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase() + '/Inst';
		switch (songLowercase)
		{
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
			case 'm.i.l.f':
				songLowercase = 'milf';
		}
		var file:Dynamic;
		#if PRELOAD_ALL
		if (!returnString)
			file = loadSound('songs', songLowercase);
		else
			file = 'songs:assets/songs/$songLowercase.$SOUND_EXT';
		#else
		file = 'songs:assets/songs/$songLowercase.$SOUND_EXT';
		#end

		return file;
	}

	/*static public function listSongsToCache()
		{
			// We need to query OpenFlAssets, not the file system, because of Polymod.
			var soundAssets = OpenFlAssets.list(AssetType.MUSIC).concat(OpenFlAssets.list(AssetType.SOUND));

			// TODO: Maybe rework this to pull from a text file rather than scan the list of assets.
			var songNames = [];

			for (sound in soundAssets)
			{
				// Parse end-to-beginning to support mods.
				var path = sound.split('/');
				path.reverse();

				var fileName = path[0];
				var songName = path[1];

				if (path[2] != 'songs')
					continue;

				// Remove duplicates.
				if (songNames.indexOf(songName) != -1)
					continue;

				songNames.push(songName);
			}

			return songNames;
	}*/
	static public function doesSoundAssetExist(path:String)
	{
		if (path == null || path == "")
			return false;
		return OpenFlAssets.exists(path, AssetType.SOUND) || OpenFlAssets.exists(path, AssetType.MUSIC);
	}

	inline static public function doesTextAssetExist(path:String)
	{
		return OpenFlAssets.exists(path, AssetType.TEXT);
	}

	static public function video(key:String, type:String = VIDEO_EXT)
	{
		return 'assets/videos/$key.$type';
	}

	inline static public function image(key:String, ?library:String, ?gpuRender:Bool):FlxGraphic
	{
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;
		var image:FlxGraphic = loadImage(key, library, gpuRender);
		return image;
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/music/freakyMenu.$SOUND_EXT', 'assets/music/ke_freakyMenu.$SOUND_EXT'];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		var counter:Int = 0;
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				// get rid of it
				var obj = cast(currentTrackedAssets.get(key), FlxGraphic);
				@:privateAccess
				if (obj != null)
				{
					obj.persist = false;
					obj.destroyOnNoUse = true;
					OpenFlAssets.cache.removeBitmapData(key);

					FlxG.bitmap._cache.remove(key);
					FlxG.bitmap.removeByKey(key);

					if (obj.bitmap.__texture != null)
					{
						obj.bitmap.__texture.dispose();
						obj.bitmap.__texture = null;
					}

					FlxG.bitmap.remove(obj);

					obj.dump();
					obj.bitmap.disposeImage();
					FlxDestroyUtil.dispose(obj.bitmap);

					obj.bitmap = null;

					obj.destroy();

					obj = null;

					currentTrackedAssets.remove(key);
					counter++;
					Debug.logTrace('Cleared $key form RAM');
					Debug.logTrace('Cleared and removed $counter assets.');
				}
			}
		}

		// run the garbage collector for good measure lmfao
		runGC();
	}

	public static function runGC()
		System.gc();

	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		// clear anything not in the tracked assets list

		var counterAssets:Int = 0;

		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = cast(FlxG.bitmap._cache.get(key), FlxGraphic);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				obj.persist = false;
				obj.destroyOnNoUse = true;

				OpenFlAssets.cache.removeBitmapData(key);

				FlxG.bitmap._cache.remove(key);

				FlxG.bitmap.removeByKey(key);

				if (obj.bitmap.__texture != null)
				{
					obj.bitmap.__texture.dispose();
					obj.bitmap.__texture = null;
				}

				FlxG.bitmap.remove(obj);

				obj.dump();

				obj.bitmap.disposeImage();
				FlxDestroyUtil.dispose(obj.bitmap);
				obj.bitmap = null;

				obj.destroy();
				obj = null;
				counterAssets++;
				Debug.logTrace('Cleared $key from RAM');
				Debug.logTrace('Cleared and removed $counterAssets cached assets.');
			}
		}

		#if PRELOAD_ALL
		// clear all sounds that are cached
		var counterSound:Int = 0;
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				// trace('test: ' + dumpExclusions, key);
				OpenFlAssets.cache.clear(key);
				OpenFlAssets.cache.removeSound(key);
				currentTrackedSounds.remove(key);
				counterSound++;
				Debug.logTrace('Cleared $key from RAM');
				Debug.logTrace('Cleared and removed $counterSound cached sounds.');
			}
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
		#end

		runGC();
	}

	inline static public function fileExists(key:String, type:AssetType, ?library:String)
	{
		if (OpenFlAssets.exists(getPath(key, type)))
			return true;

		return false;
	}

	static public function getSparrowAtlas(key:String, ?library:String, ?isCharacter:Bool = false, ?gpuRender:Bool)
	{
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;
		if (isCharacter)
		{
			return FlxAtlasFrames.fromSparrow(image('characters/$key', library, gpuRender), file('images/characters/$key.xml', library));
		}
		return FlxAtlasFrames.fromSparrow(image(key, library, gpuRender), file('images/$key.xml', library));
	}

	/**
	 * Senpai in Thorns uses this instead of Sparrow and IDK why.
	 */
	inline static public function getPackerAtlas(key:String, ?library:String, ?isCharacter:Bool = false, ?gpuRender:Bool)
	{
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;
		if (isCharacter)
		{
			return FlxAtlasFrames.fromSpriteSheetPacker(image('characters/$key', library, gpuRender), file('images/characters/$key.txt', library));
		}
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, gpuRender), file('images/$key.txt', library));
	}

	inline static public function getTextureAtlas(key:String, ?library:String, ?isCharacter:Bool = false, ?excludeArray:Array<String>):FlxFramesCollection
	{
		if (isCharacter)
			return AtlasFrameMaker.construct('characters/$key', library, excludeArray);

		return AtlasFrameMaker.construct(key, library, excludeArray);
	}

	inline static public function getJSONAtlas(key:String, ?library:String, ?isCharacter:Bool = false, ?gpuRender:Bool)
	{
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;
		if (isCharacter)
			return FlxAtlasFrames.fromTexturePackerJson(image('characters/$key', library, gpuRender), file('images/characters/$key.json', library));

		return FlxAtlasFrames.fromTexturePackerJson(image(key, library), file('images/$key.json', library));
	}
}
