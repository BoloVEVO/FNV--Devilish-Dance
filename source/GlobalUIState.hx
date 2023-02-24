package;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

/**
 *
 * UI State Override
 * From: https://github.com/Yoshubs/Forever-Engine-Legacy
 *
**/
class GlobalUIState extends FlxUIState
{
	override function create()
	{
		// state stuffs
		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new PsychTransition(0.75, true));

		super.create();
	}
}
