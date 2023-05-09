package;

import CoolUtil.CoolText;
import flixel.FlxSubState;
import flixel.input.gamepad.FlxGamepad;
import Modifiers;
import FreeplayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

// Uuh... Direct copy of OptionsMenu.hx xD
class ModMenu extends MusicBeatSubstate
{
	public static var instance:ModMenu = null;

	public var background:FlxSprite;

	public var selectedModifier:Modifier;

	public var selectedModifierIndex = 0;

	public var modifiers:Array<Modifier>;

	public var shownStuff:FlxTypedGroup<CoolText>;

	public static var visibleRange = [114, 640];

	public var menu:FlxTypedGroup<FlxSprite>;

	public var descText:CoolText;
	public var descBack:FlxSprite;
	public var descTop:FlxSprite;

	public var modObjects:FlxTypedGroup<CoolText>;

	public var titleObject:FlxText;

	public var text:CoolText;

	var changedMod = false;

	override function create()
	{
		modObjects = new FlxTypedGroup();

		modifiers = [
			new OpponentMode("Toggle to play as the opponent."),
			new Mirror("Flip Notes horizontally (Up is Down, Left is Right)"),
			new Practice("Skill issue? Try this, and u'll get better :D ."),
			new NoMissesMode("Skill issuen't? Try this, a single miss you die!"),
			new Sustains("Toggle Hold Notes in song chart."),
			new Modchart("Toggle Song Modchart if it has it."),
			new HealthDrain("Toggle Opponent Health Drain when singing."),
			new HealthGain("Toggle how many health you want to gain."),
			new HealthLoss("Toggle how many health you want to loss.")
		];

		titleObject = new FlxText(176, 49, 0, 'GAMEPLAY MODIFIERS');
		titleObject.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		titleObject.borderSize = 3;

		for (i in 0...modifiers.length)
		{
			var mod = modifiers[i];
			text = new CoolText(72, titleObject.y + 72 + (46 * i), 35, 35, Paths.bitmapFont('fonts/vcr'));
			text.autoSize = true;
			text.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;

			text.borderSize = 2;
			text.borderQuality = 1;
			text.scrollFactor.set();
			text.text = mod.getValue();
			text.alpha = 0.4;
			text.antialiasing = FlxG.save.data.antialiasing;
			text.updateHitbox();
			modObjects.add(text);
		}

		instance = this;

		menu = new FlxTypedGroup<FlxSprite>();

		shownStuff = new FlxTypedGroup<CoolText>();

		selectedModifier = modifiers[0];

		background = new FlxSprite(30, 40).makeGraphic(690, 640, FlxColor.BLACK);
		background.alpha = 0.5;
		background.scrollFactor.set();
		menu.add(background);

		descTop = new FlxSprite(30, 39).makeGraphic(690, 55, FlxColor.BLACK);
		descTop.alpha = 0.3;
		descTop.scrollFactor.set();
		menu.add(descTop);

		descBack = new FlxSprite(30, 642).makeGraphic(690, 38, FlxColor.BLACK);
		descBack.alpha = 0.3;
		descBack.scrollFactor.set();
		menu.add(descBack);

		add(menu);
		add(shownStuff);

		descText = new CoolText(62, 650, 20, 20, Paths.bitmapFont('fonts/vcr'));
		descText.autoSize = true;
		descText.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
		descText.antialiasing = FlxG.save.data.antialiasing;

		descText.borderSize = 2;

		add(descBack);
		add(descText);

		add(titleObject);

		selectedModifier = modifiers[0];

		selectModifier(selectedModifier);

		for (i in modObjects)
			shownStuff.add(i);

		openCallback = refresh;

		super.create();
	}

	private function refresh()
	{
		selectedModifierIndex = 0;

		selectedModifier = modifiers[0];

		selectModifier(selectedModifier);
	}

	public function selectModifier(mod:Modifier)
	{
		var object = modObjects.members[selectedModifierIndex];

		selectedModifier = mod;

		object.text = "> " + mod.getValue();

		descText.text = mod.getDescription();
		descText.updateHitbox();

		object.updateHitbox();

		Debug.logTrace("Changed mod: " + selectedModifierIndex);

		Debug.logTrace("Bounds: " + visibleRange[0] + "," + visibleRange[1]);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var accept = false;
		var right = false;
		var left = false;
		var up = false;
		var down = false;
		var any = false;
		var escape = false;

		changedMod = false;

		accept = FlxG.keys.justPressed.ENTER || (gamepad != null ? gamepad.justPressed.A : false);
		right = FlxG.keys.justPressed.RIGHT || (gamepad != null ? gamepad.justPressed.DPAD_RIGHT : false);
		left = FlxG.keys.justPressed.LEFT || (gamepad != null ? gamepad.justPressed.DPAD_LEFT : false);
		up = FlxG.keys.justPressed.UP || (gamepad != null ? gamepad.justPressed.DPAD_UP : false);
		down = FlxG.keys.justPressed.DOWN || (gamepad != null ? gamepad.justPressed.DPAD_DOWN : false);

		any = FlxG.keys.justPressed.ANY || (gamepad != null ? gamepad.justPressed.ANY : false);
		escape = FlxG.keys.justPressed.ESCAPE || (gamepad != null ? gamepad.justPressed.B : false);

		#if !mobile
		if (FlxG.mouse.wheel != 0)
		{
			if (FlxG.mouse.wheel < 0)
				down = true;
			else if (FlxG.mouse.wheel > 0)
				up = true;
		}
		#end

		for (i in modObjects.members)
		{
			if (i != null)
			{
				if (modObjects.members[selectedModifierIndex].text != i.text)
					i.alpha = 0.4;
				else
					i.alpha = 1;
			}
		}

		if (selectedModifier != null)
			if (selectedModifier.acceptType)
			{
				if (escape && selectedModifier.waitingType)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedModifier.waitingType = false;
					var object = modObjects.members[selectedModifierIndex];
					object.text = "> " + selectedModifier.getValue();
					Debug.logTrace("New text: " + object.text);
					object.updateHitbox();
					return;
				}
				else if (any)
				{
					var object = modObjects.members[selectedModifierIndex];
					selectedModifier.onType(gamepad == null ? FlxG.keys.getIsDown()[0].ID.toString() : gamepad.firstJustPressedID());
					object.text = "> " + selectedModifier.getValue();
					object.updateHitbox();
					Debug.logTrace("New text: " + object.text);
				}
			}

		if (accept)
		{
			var prev = selectedModifierIndex;
			var object = modObjects.members[selectedModifierIndex];
			selectedModifier.press();

			if (selectedModifierIndex == prev)
			{
				object.text = "> " + selectedModifier.getValue();
			}
		}

		if (down)
		{
			if (selectedModifier.acceptType)
				selectedModifier.waitingType = false;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			modObjects.members[selectedModifierIndex].text = selectedModifier.getValue();
			selectedModifierIndex++;

			// just kinda ignore this math lol

			if (selectedModifierIndex > modifiers.length - 1)
				selectedModifierIndex = 0;
			selectModifier(modifiers[selectedModifierIndex]);
		}
		else if (up)
		{
			if (selectedModifier.acceptType)
				selectedModifier.waitingType = false;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			modObjects.members[selectedModifierIndex].text = selectedModifier.getValue();
			selectedModifierIndex--;

			// just kinda ignore this math lol

			if (selectedModifierIndex < 0)
				selectedModifierIndex = modifiers.length - 1;

			selectModifier(modifiers[selectedModifierIndex]);
		}

		if (right)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			var object = modObjects.members[selectedModifierIndex];
			selectedModifier.right();

			changedMod = true;
			object.text = "> " + selectedModifier.getValue();
			object.updateHitbox();
			Debug.logTrace("New text: " + object.text);
		}
		else if (left)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			var object = modObjects.members[selectedModifierIndex];
			selectedModifier.left();
			changedMod = true;

			object.text = "> " + selectedModifier.getValue();
			object.updateHitbox();
			Debug.logTrace("New text: " + object.text);
		}
		if (escape)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));

			PlayerSettings.player1.controls.loadKeyBinds();

			FlxG.state.closeSubState();

			FreeplayState.openMod = false;

			FreeplayState.instance.changeSelection();

			modObjects.members[selectedModifierIndex].text = selectedModifier.getValue();
		}
		#if !html5
		if (changedMod)
			if (selectedModifierIndex == 0)
				FreeplayState.instance.updateDiffCalc();
		#end
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
