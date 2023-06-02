package;

import flixel.animation.FlxAnimationController;
import flixel.tweens.FlxEase;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Stage extends MusicBeatState
{
	public var stageJSON:StageData;

	var pos:Float = 0;

	public var curStage:String = '';
	public var camZoom:Float = 1.05; // The zoom of the camera to have at the start of the game
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String,
		Dynamic> = []; // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
	public var layInFront:Array<Array<FlxSprite>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment)

	public var staticCam:Bool = false;

	// All of the above must be set or used in your stage case code block!!
	public var positions:Map<String, Map<String, Array<Float>>> = [
		// Assign your characters positions on stage here!
		'halloween' => ['spooky' => [100, 300], 'monster' => [100, 200]],
		'philly' => ['pico' => [100, 400]],
		'limo' => ['bf-car' => [1030, 230]],
		'mall' => ['bf-christmas' => [970, 450], 'parents-christmas' => [-400, 100]],
		'mallEvil' => ['bf-christmas' => [1090, 450], 'monster-christmas' => [100, 150]],
		'school' => [
			'gf-pixel' => [580, 430],
			'bf-pixel' => [970, 670],
			'senpai' => [250, 460],
			'senpai-angry' => [250, 460]
		],
		'schoolEvil' => ['gf-pixel' => [580, 430], 'bf-pixel' => [970, 670], 'spirit' => [-50, 200]],
		'tank' => [
			'pico-speaker' => [307, 97],
			'bf' => [810, 500],
			'bf-holding-gf' => [807, 479],
			'gf-tankmen' => [200, 85],
			'tankman' => [20, 100]
		]
	];

	public var camPosition:Array<Float> = [];

	public var loadGF:Bool = true;

	public function new(daStage:String)
	{
		super();

		if (daStage == null)
			daStage = 'stage';

		this.curStage = daStage;

		stageJSON = StageData.StageJSON.loadJSONFile(daStage);
	}

	// STAGE SETTINGS BEFORE LOADING ANY SPRITE
	public function initStageProperties()
	{
		switch (curStage)
		{
			default:
				camZoom = 0.9;
		}

		overridePropertiesFromJSON();
	}

	// Initial and default Camera position, needs to be called after initStageProperties because of loading GF property.
	public function initCamPos()
	{
		if (camPosition.length == 0)
		{
			if (PlayState.instance.gf != null)
				camPosition = [
					PlayState.instance.gf.getGraphicMidpoint().x + PlayState.instance.gf.camPos[0],
					PlayState.instance.gf.getGraphicMidpoint().y + PlayState.instance.gf.camPos[1]
				];
			else
				camPosition = [0, 0];
		}
	}

	// LOADS STAGE SPRITES (SHOULD BE LOADED AFTER DEFINING STAGE PROPERTIES)
	public function initStageSprites(?forceLoad:Bool = false)
	{
		if (!FlxG.save.data.background && !forceLoad)
			return;

		switch (curStage)
		{
			case 'voltexStage':
				camZoom = 0.65;
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(PlayState.SONG.songId.toLowerCase(), 'voltex'));

				bg.antialiasing = FlxG.save.data.antialiasing;

				swagBacks['bg'] = bg;

				toAdd.push(bg);

				switch (PlayState.SONG.songId)
				{
					case '666':
						var stageFront:FlxSprite = new FlxSprite().loadGraphic(Paths.image('BG_floor_symmetrical', 'voltex'));
						stageFront.alpha = 1;
						stageFront.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['stageFront'] = stageFront;
						toAdd.push(stageFront);

						var lateStageFront:FlxSprite = new FlxSprite().loadGraphicFromSprite(stageFront);
						lateStageFront.antialiasing = FlxG.save.data.antialiasing;
						lateStageFront.alpha = 0.0001;
						swagBacks['lateStageFront'] = lateStageFront;

						layInFront[1].push(lateStageFront);

						var sword:FlxSprite = new FlxSprite();
						sword.frames = Paths.getSparrowAtlas('pussy_destroyer', 'voltex');
						sword.animation.addByPrefix('slice', 'slice', 24, false);
						sword.alpha = 0.0001;
						sword.scale.set(1.5, 1.5);
						swagBacks['sword'] = sword;
						layInFront[2].push(sword);
					case 'i':
						var stageFront:FlxSprite = new FlxSprite().loadGraphic(Paths.image('BG_floor_symmetrical', 'voltex'));

						stageFront.antialiasing = FlxG.save.data.antialiasing;
						stageFront.alpha = 0.0001;
						swagBacks['stageFront'] = stageFront;

						Paths.image('BG_back_finale', 'voltex');

						if (FlxG.save.data.distractions)
						{
							var hotGirlBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('dualrasis_glow', 'voltex'));
							hotGirlBG.screenCenter();
							hotGirlBG.antialiasing = FlxG.save.data.antialiasing;
							swagBacks['hotGirlBG'] = hotGirlBG;

							var coolCatBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('dualtama_glow', 'voltex'));
							coolCatBG.screenCenter();
							coolCatBG.antialiasing = FlxG.save.data.antialiasing;
							swagBacks['coolCatBG'] = coolCatBG;
							hotGirlBG.alpha = 0.001;
							coolCatBG.alpha = 0.001;

							hotGirlBG.x += 75;
							hotGirlBG.y -= 75;
							coolCatBG.x += 75;
							coolCatBG.y -= 75;
							pos = hotGirlBG.y;
							toAdd.push(coolCatBG);
							toAdd.push(hotGirlBG);
						}

						toAdd.push(stageFront);

						if (FlxG.save.data.distractions)
						{
							var lightsWentBRRR = new FlxSprite();
							lightsWentBRRR.frames = Paths.getSparrowAtlas('Sex', 'voltex');
							lightsWentBRRR.animation.addByPrefix('Sex', 'sex', 60, false);
							lightsWentBRRR.scrollFactor.set();
							lightsWentBRRR.updateHitbox();
							lightsWentBRRR.screenCenter();
							lightsWentBRRR.camera = PlayState.instance.mainCam;
							swagBacks['lightsWentBRRR'] = lightsWentBRRR;

							var littleLight = new FlxSprite();
							littleLight.frames = Paths.getSparrowAtlas('Sex2', 'voltex');
							littleLight.animation.addByPrefix('Sex2', 'sex 2, the squeakquel', 60, false);
							littleLight.scrollFactor.set();
							littleLight.updateHitbox();
							littleLight.screenCenter();
							littleLight.camera = PlayState.instance.mainCam;
							swagBacks['littleLight'] = littleLight;

							var lightsWentBRRRnt = new FlxSprite();
							lightsWentBRRRnt.frames = Paths.getSparrowAtlas('Sex3', 'voltex');
							lightsWentBRRRnt.animation.addByPrefix('Sex3', 'sex 3, the enemy returns', 60, false);
							lightsWentBRRRnt.scrollFactor.set();
							lightsWentBRRRnt.updateHitbox();
							lightsWentBRRRnt.screenCenter();
							lightsWentBRRRnt.camera = PlayState.instance.mainCam;
							swagBacks['lightsWentBRRRnt'] = lightsWentBRRRnt;

							lightsWentBRRR.alpha = 0.001;
							littleLight.alpha = 0.001;
							lightsWentBRRRnt.alpha = 0.001;
							toAdd.push(lightsWentBRRRnt);
							toAdd.push(lightsWentBRRR);
							toAdd.push(littleLight);
						}
						else
						{
							var conalep_pc = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
							conalep_pc.screenCenter();
							conalep_pc.camera = PlayState.instance.mainCam;
							conalep_pc.alpha = 0.001;
							swagBacks['conalep_pc'] = conalep_pc;
							toAdd.push(conalep_pc);
						}
				}

			case 'void': // In case you want to do chart with videos.

				var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
				black.scrollFactor.set(0, 0);
				toAdd.push(black);

			default:
				{
					camZoom = 0.9;
					var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback', 'shared'));
					bg.antialiasing = FlxG.save.data.antialiasing;
					bg.scrollFactor.set(0.9, 0.9);
					bg.active = false;
					swagBacks['bg'] = bg;
					toAdd.push(bg);

					var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront', 'shared'));
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					stageFront.antialiasing = FlxG.save.data.antialiasing;
					stageFront.scrollFactor.set(0.9, 0.9);
					stageFront.active = false;
					swagBacks['stageFront'] = stageFront;
					toAdd.push(stageFront);

					if (FlxG.save.data.distractions)
					{
						var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains', 'shared'));
						stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
						stageCurtains.updateHitbox();
						stageCurtains.antialiasing = FlxG.save.data.antialiasing;
						stageCurtains.scrollFactor.set(1.3, 1.3);
						stageCurtains.active = false;

						swagBacks['stageCurtains'] = stageCurtains;
						toAdd.push(stageCurtains);
					}
				}
		}

		overrideStageSpritesPosFromJSON();
	}

	private function overridePropertiesFromJSON()
	{
		if (stageJSON != null)
		{
			if (stageJSON.staticCam != null)
				if (Std.isOfType(stageJSON.staticCam, Bool))
					staticCam = stageJSON.staticCam;

			if (stageJSON.camZoom != null)
				if (Std.isOfType(stageJSON.camZoom, Type.resolveClass('Float')))
					camZoom = stageJSON.camZoom;

			if (stageJSON.camPosition != null)
				if (Std.isOfType(stageJSON.camPosition, Type.resolveClass('Array')))
					camPosition = stageJSON.camPosition;

			if (stageJSON.loadGF != null)
				if (Std.isOfType(stageJSON.loadGF, Bool))
					loadGF = stageJSON.loadGF;

			if (stageJSON.charPositions != null)
			{
				var posesMap:DynamicAccess<Array<Float>> = haxe.Json.parse(haxe.Json.stringify(stageJSON.charPositions));
				var charMap:Map<String, Array<Float>> = [];
				for (char in posesMap.keys())
				{ // Don't use get(char) method because it crashes the game without any log
					charMap.set(char, posesMap[char]);
					positions.set(curStage, charMap);
				}
			}
		}
	}

	private function overrideStageSpritesPosFromJSON()
	{
		if (stageJSON != null)
		{
			if (stageJSON.spritesPositions != null)
			{
				var spritesMap:DynamicAccess<Array<Float>> = haxe.Json.parse(haxe.Json.stringify(stageJSON.spritesPositions));

				for (sprite in spritesMap.keys())
				{
					if (spritesMap[sprite].length >= 2)
						if (swagBacks[sprite] != null)
							swagBacks[sprite].setPosition(spritesMap[sprite][0], spritesMap[sprite][1]);
				}
			}

			if (stageJSON.spriteGroupPositions != null)
			{
				var groupMap:DynamicAccess<Map<Int, Array<Float>>> = haxe.Json.parse(haxe.Json.stringify(stageJSON.spriteGroupPositions));

				for (group in groupMap.keys())
				{
					if (swagGroup[group] != null)
					{
						var memberMap = groupMap[group];

						for (memberIndex in memberMap.keys())
						{
							if (memberMap[memberIndex].length >= 2)
								swagGroup[group].members[memberIndex].setPosition(memberMap[memberIndex][0], memberMap[memberIndex][1]);
						}
					}
				}
			}
		}
	}

	override public function update(elapsed:Float)
	{
		if (!FlxG.save.data.background)
			return;

		super.update(elapsed);
	}

	override function stepHit()
	{
		super.stepHit();
		if (!FlxG.save.data.background)
			return;

		switch (curStage)
		{
			case 'voltexStage':
				switch (PlayState.SONG.songId)
				{
					case 'i':
						switch (curStep)
						{
							case 1304:
								swagBacks['bg'].loadGraphic(Paths.image('BG_back_finale', 'voltex'));

								// Using cast method to interpret them as FlxSprite because too many var defining

								cast(swagBacks['stageFront'], FlxSprite).alpha = 1;

								if (FlxG.save.data.distractions)
								{
									cast(swagBacks['coolCatBG'], FlxSprite).alpha = 1;
									cast(swagBacks['hotGirlBG'], FlxSprite).alpha = 1;

									epicCatSpin();
									verticalSway();

									cast(swagBacks['lightsWentBRRR'], FlxSprite).alpha = 1;
									cast(swagBacks['littleLight'], FlxSprite).alpha = 1;
									cast(swagBacks['lightsWentBRRRnt'], FlxSprite).alpha = 1;
									cast(swagBacks['lightsWentBRRR'], FlxSprite).animation.play('Sex', false, false, 0);
									cast(swagBacks['littleLight'], FlxSprite).animation.play('Sex2', false, false, 0);
								}
								else
								{
									cast(swagBacks['conalep_pc'], FlxSprite).alpha = 1;
									PlayState.instance.mainCam.fade(FlxColor.WHITE, 0.75 / PlayState.instance.songMultiplier, true);
								}
							case 1352:
								if (FlxG.save.data.distractions)
								{
									PlayState.instance.dad.alpha = 0;
									cast(swagBacks['lightsWentBRRR'], FlxSprite).alpha = 0;
									cast(swagBacks['littleLight'], FlxSprite).alpha = 0;
									cast(swagBacks['lightsWentBRRRnt'], FlxSprite).animation.play('Sex3', false, false, 0);
								}
							case 1364:
								if (!FlxG.save.data.distractions)
								{
									cast(swagBacks['conalep_pc'], FlxSprite).alpha = 0;

									PlayState.instance.mainCam.fade(FlxColor.WHITE, 0.75 / PlayState.instance.songMultiplier, true);
								}
						}
				}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (!FlxG.save.data.background)
			return;

		if (FlxG.save.data.distractions && FlxG.save.data.background && animatedBacks.length > 0)
		{
			for (bg in animatedBacks)
				bg.animation.play('idle', true);
		}

		if (FlxG.save.data.distractions && FlxG.save.data.background)
		{
		}

		if (FlxG.save.data.background)
		{
			switch (curStage)
			{
				case "voltexStage":
					if (PlayState.SONG.songId == '666') // Hardcode moment because I'm too lazy to add it as event.
					{
						switch (curBeat)
						{
							case 456:
								PlayState.instance.camHUD.flash(FlxColor.WHITE, 0.5);
								var normalFront:FlxSprite = swagBacks['stageFront'];
								normalFront.alpha = 0;
								var frontOpponent:FlxSprite = swagBacks['lateStageFront'];
								frontOpponent.alpha = 1;
							case 465:
								PlayState.instance.tweenManager.tween(PlayState.instance.dad, {y: 0}, 1.75, {ease: FlxEase.sineInOut});

							case 475:
								var coolSword:FlxSprite = swagBacks['sword'];
								coolSword.alpha = 1;
								coolSword.animation.followGlobalSpeed = false;
								coolSword.animation.play('slice');
								coolSword.animation.finishCallback = function(name:String)
								{
									coolSword.alpha = 0.0001;
								}
							case 482:
								FlxAnimationController.globalSpeed *= 0.25;
							case 494:
								FlxAnimationController.globalSpeed /= 0.25;
						}
					}
			}
		}
	}

	public var spinCat:FlxTween;

	function epicCatSpin()
	{
		spinCat = PlayState.instance.createTween(swagBacks['coolCatBG'], {angle: 180}, 8 / PlayState.instance.songMultiplier, {
			ease: FlxEase.linear,
			onComplete: function(tween:FlxTween)
			{
				spinCat = null;
				PlayState.instance.createTween(swagBacks['coolCatBG'], {angle: 360}, 8, {
					ease: FlxEase.linear,
					onComplete: function(tween:FlxTween)
					{
						spinCat = null;
						swagBacks['coolCatBG'].angle = 0;
						epicCatSpin();
					}
				});
			}
		});
	}

	public var rasisTween:FlxTween;

	function verticalSway()
	{
		rasisTween = PlayState.instance.createTween(swagBacks['hotGirlBG'], {y: pos + 30}, 2 / PlayState.instance.songMultiplier, {
			ease: FlxEase.sineInOut,
			onComplete: function(tween:FlxTween)
			{
				rasisTween = null;
				rasisTween = PlayState.instance.createTween(swagBacks['hotGirlBG'], {y: pos - 30}, 2, {
					ease: FlxEase.sineInOut,
					onComplete: function(tween:FlxTween)
					{
						rasisTween = null;
						verticalSway();
					}
				});
			}
		});
		PlayState.instance.createTween(swagBacks['hotGirlBG'], {y: pos + 30}, 2 / PlayState.rate, {
			ease: FlxEase.sineInOut,
			onComplete: function(tween:FlxTween)
			{
				PlayState.instance.createTween(swagBacks['hotGirlBG'], {y: pos - 30}, 2, {
					ease: FlxEase.sineInOut
				});
			}
		});
	}

	override function destroy()
	{
		super.destroy();
		for (sprite in swagBacks.keys())
		{
			if (swagBacks[sprite] != null)
				swagBacks[sprite].destroy();
		}

		swagBacks.clear();

		while (toAdd.length > 0)
		{
			toAdd.remove(toAdd[0]);
			if (toAdd[0] != null)
				toAdd[0].destroy();
		}

		while (animatedBacks.length > 0)
		{
			animatedBacks.remove(animatedBacks[0]);
			if (animatedBacks[0] != null)
				animatedBacks[0].destroy();
		}

		for (array in layInFront)
		{
			for (sprite in array)
			{
				if (sprite != null)
					sprite.destroy();
				array.remove(sprite);
			}
		}

		for (swag in swagGroup.keys())
		{
			if (swagGroup[swag].members != null)
				for (member in swagGroup[swag].members)
				{
					swagGroup[swag].members.remove(member);
					member.destroy();
				}
		}

		swagGroup.clear();
	}
}
