package audio;

import flixel.FlxBasic;
#if desktop
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import lime.media.openal.ALFilter;
import flixel.FlxG;
import flixel.FlxGame;
import haxe.io.Bytes;
import lime.utils.UInt8Array;
import lime.media.vorbis.VorbisFile;
import lime.media.openal.AL;
import lime.media.vorbis.VorbisInfo;
#end

// Made by doggyventures and edited by BoloVEVO
class AudioStreamThing extends FlxBasic
{
	#if desktop
	var vorb:VorbisFile;
	var _length:Float;
	var _volume:Float = 1.0;
	var audioSource = null;
	var audioBuffer = null;

	public var fadeTween:FlxTween;

	public var persist:Bool = false;

	public var volume(get, set):Float;
	public var time(get, set):Float;
	public var speed(get, set):Float;
	public var playing(get, never):Bool;
	public var stopped(get, never):Bool;
	public var length(get, never):Float;

	var _lostFocus:Bool = false;

	public var lostFocus(get, never):Bool;

	public var gamePaused:Bool = false;

	public override function new(file:Dynamic, ?useBytes:Bool = false)
	{
		audioSource = AL.createSource();
		audioBuffer = AL.createBuffer();
		if (!useBytes)
		{
			if (sys.FileSystem.exists(file))
			{
				vorb = VorbisFile.fromFile(file);
			}
			else
			{
				Debug.logInfo("AUDIO " + file + " DOESN'T EXIST");
				return;
			}
		}
		else
		{
			try
			{
				vorb = VorbisFile.fromBytes(file);
			}
			catch (e)
			{
				Debug.logInfo(e);
			}
		}
		var sndData = readVorbisFileBuffer(vorb);
		var vorbInfo:VorbisInfo = vorb.info();
		var vorbChannels = AL.FORMAT_STEREO16;
		if (vorbInfo.channels <= 1)
			vorbChannels = AL.FORMAT_MONO16;
		var vorbRate = vorbInfo.rate;
		_length = vorb.timeTotal() * 1000;
		AL.bufferData(audioBuffer, vorbChannels, sndData, sndData.length, vorbRate);
		AL.sourcei(audioSource, AL.BUFFER, audioBuffer);

		super();
	}

	public function dispose()
	{
		#if cpp
		AL.deleteSource(audioSource);
		AL.deleteBuffer(audioBuffer);
		fadeTween = null;
		vorb = null;
		_length = 0;
		_volume = 0.0;
		audioSource = null;
		audioBuffer = null;
		onComplete = null;
		#end
	}

	public override function destroy()
	{
		if (!persist)
		{
			dispose();
			super.destroy();
		}
	}

	public override function update(elapsed:Float):Void
	{
		if (audioSource != null)
		{
			if (FlxG.sound.muted)
				AL.sourcef(audioSource, AL.GAIN, 0);
			else
				AL.sourcef(audioSource, AL.GAIN, _volume * FlxG.sound.volume);
		}

		super.update(elapsed);
	}

	public var onComplete:Void->Void;

	public function play()
	{
		if (audioSource != null)
			AL.sourcePlay(audioSource);
	}

	public function pause()
	{
		if (audioSource != null)
			AL.sourcePause(audioSource);
	}

	public function paused():Bool
	{
		return AL.getSourcei(audioSource, AL.PAUSED);
	}

	public function stop()
	{
		if (audioSource != null)
			AL.sourceStop(audioSource);
	}

	public inline function muteAfterTimeElapsed(Duration:Float = 1):Void
	{
		if (fadeTween != null)
			fadeTween.cancel();
		fadeTween = FlxTween.num(1, 1, Duration, {
			onComplete: function(_)
			{
				volume = 0;
			}
		});

		return;
	}

	inline function get_playing():Bool
	{
		if (audioSource != null)
			return (AL.getSourcei(audioSource, AL.SOURCE_STATE) == AL.PLAYING);

		return false;
	}

	inline function get_stopped():Bool
	{
		if (audioSource != null)
			return (AL.getSourcei(audioSource, AL.SOURCE_STATE) == AL.STOPPED);

		return false;
	}

	inline function get_length():Float
	{
		if (audioSource != null)
			return _length;

		return 0;
	}

	inline function get_volume():Float
	{
		if (audioSource != null)
			return _volume;

		return 1.0;
	}

	inline function set_volume(newVol:Float):Float
	{
		if (audioSource != null)
			_volume = newVol;

		return newVol;
	}

	inline function get_time():Float
	{
		if (audioSource != null)
			return AL.getSourcef(audioSource, AL.SEC_OFFSET) * 1000;

		return 0;
	}

	function set_time(newTime:Float):Float
	{
		if (audioSource != null)
			AL.sourcef(audioSource, AL.SEC_OFFSET, newTime / 1000);

		return newTime;
	}

	inline function get_speed():Float
	{
		if (audioSource != null)
			return AL.getSourcef(audioSource, AL.PITCH);

		return 0;
	}

	function set_speed(newSpeed:Float):Float
	{
		if (audioSource != null)
		{
			AL.sourcef(audioSource, AL.PITCH, newSpeed);
		}
		return newSpeed;
	}

	inline function get_lostFocus():Bool
	{
		return _lostFocus;
	}

	// public function loseFocus()
	// {
	// 	_lostFocus = true;
	// 	if (!gamePaused)
	// 		pause();
	// }
	// public function regainFocus()
	// {
	// 	_lostFocus = false;
	// 	if (!gamePaused)
	// 		play();
	// }

	public static function readVorbisFileBuffer(vorbisFile:VorbisFile):UInt8Array
	{
		var vorbInfo:VorbisInfo = vorbisFile.info();
		var vorbChannels = AL.FORMAT_STEREO16;
		if (vorbInfo.channels <= 1)
			vorbChannels = AL.FORMAT_MONO16;
		var vorbRate = vorbInfo.rate;

		var length = Std.int(vorbRate * vorbInfo.channels * 16 * vorbisFile.timeTotal() / 8);
		var buffer = Bytes.alloc(length);
		var read = 0, total = 0, readMax;

		while (total < length)
		{
			readMax = 4096;

			if (readMax > length - total)
			{
				readMax = length - total;
			}

			read = vorbisFile.read(buffer, total, readMax);

			if (read > 0)
			{
				total += read;
			}
			else
			{
				break;
			}
		}

		var realbuffer = new UInt8Array(total);
		realbuffer.buffer.blit(0, buffer, 0, total);

		return realbuffer;
	}
	#end
}
