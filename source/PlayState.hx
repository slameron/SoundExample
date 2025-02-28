package;

import SelectionList;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	var soundVolume = 0.5;
	var musicVolume = 0.5;
	var masterVolume = 1.0;

	var soundVolText:FlxText;
	var musicVolText:FlxText;

	override public function create()
	{
		super.create();

		var defY = 100;
		var spacing = 70;
		var textBorderStyle:FlxTextBorderStyle = OUTLINE;

		optionsMenu = new SelectionList(defY, spacing, textBorderStyle);
		optionsMenu.targetX = 30;
		optionsMenu.topBound = 0;
		optionsMenu.bottomBound = FlxG.height;
		optionsMenu.addCallback('Master Volume', by ->
		{
			masterVolume += .1 * by;
			masterVolume = FlxMath.bound(FlxMath.roundDecimal(masterVolume, 1), 0, 1);

			FlxG.game.soundTray.silent = false;
			FlxG.game.soundTray.show(by > 0, 'MASTER VOLUME', masterVolume);
		}, true, true).addCallback('Sound Volume', by ->
			{
				soundVolume += .1 * by;
				soundVolume = FlxMath.bound(FlxMath.roundDecimal(soundVolume, 1), 0, 1);

				FlxG.game.soundTray.silent = false;
				FlxG.game.soundTray.show(by > 0, 'SOUND VOLUME', soundVolume);
			}, true, true).addCallback('Music Volume', by ->
			{
				musicVolume += .1 * by;
				musicVolume = FlxMath.bound(FlxMath.roundDecimal(musicVolume, 1), 0, 1);

				FlxG.game.soundTray.silent = true;
				FlxG.game.soundTray.show(by > 0, 'MUSIC VOLUME', musicVolume);
			}, true, true);

		add(optionsMenu);

		soundVolText = new FlxText(0, FlxG.height, 0, 'sounds will be played at ${soundVolume * masterVolume} volume', 32);
		soundVolText.y -= (soundVolText.height + 10) * 2;
		add(soundVolText);

		musicVolText = new FlxText(0, FlxG.height, 0, 'music will be played at ${musicVolume * masterVolume} volume', 32);
		musicVolText.y -= musicVolText.height + 10;
		add(musicVolText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		soundVolText.text = 'sounds will be played at ${soundVolume * masterVolume} volume';
		musicVolText.text = 'music will be played at ${musicVolume * masterVolume} volume';

		if (FlxG.keys.anyJustPressed([W, UP]))
			change(-1);
		if (FlxG.keys.anyJustPressed([S, DOWN]))
			change(1);

		optionsMenu.focusedMenu.forEach(spr ->
		{
			if (spr.ID == optionsMenu.focusedMenu.curSelected)
				spr.color = 0xFFffcc26;
			else
				spr.color = FlxColor.WHITE;
		});

		if (FlxG.keys.anyJustPressed([SPACE, ENTER]))
			optionsMenu.focusedMenu.select();
		if (FlxG.keys.anyJustPressed([A, LEFT]))
			optionsMenu.focusedMenu.select(-1);
		if (FlxG.keys.anyJustPressed([D, RIGHT]))
			optionsMenu.focusedMenu.select(1);
	}

	function change(by:Int = 0)
	{
		optionsMenu.focusedMenu.curSelected = retSel(optionsMenu.focusedMenu.curSelected + by);
		optionsMenu.focusedMenu.scroll(by);
		// Sound.play('menuChange');
	}

	function retSel(sel:Int, online = false):Int
	{
		return Std.int(FlxMath.bound(sel, 0, optionsMenu.focusedMenu.length - 1));
		/*return if (sel >= mainMenu.focusedMenu.length) retSel(sel - mainMenu.focusedMenu.length) else if (sel < 0) retSel(mainMenu.focusedMenu.length +
			sel) else sel; */
	}

	var optionsMenu:SelectionList;
}
