package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxStrip;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import openfl.utils.Assets as OpenFlAssets;

class WaveformTestState extends MusicBeatState
{
	var waveformInst:Waveform;

	var waveformVoices:Waveform;

	override public function create()
	{
		super.create();

		// fuckin stupid ass bitch ass fucking waveform
		if (PlayState.isSM)
		{
			#if FEATURE_FILESYSTEM
			waveformInst = new Waveform(0, 0, PlayState.pathToSm + "/" + PlayState.sm.header.MUSIC, 720);
			#end
		}
		else
		{
			waveformInst = new Waveform(0, 0, OpenFlAssets.getPath(Paths.inst(PlayState.SONG.songId, true)), 720);
			if (PlayState.SONG.needsVoices)
				waveformVoices = new Waveform(0, 0, OpenFlAssets.getPath(Paths.voices(PlayState.SONG.songId, true)), 720);
		}
		waveformInst.drawWaveform(FlxColor.CYAN);
		waveformVoices.drawWaveform(FlxColor.YELLOW);
		add(waveformInst);
		add(waveformVoices);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.pressed.W)
			FlxG.camera.y += 1;
		if (FlxG.keys.pressed.S)
			FlxG.camera.y -= 1;
		if (FlxG.keys.pressed.A)
			FlxG.camera.x += 1;
		if (FlxG.keys.pressed.D)
			FlxG.camera.x -= 1;
	}
}
