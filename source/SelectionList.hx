package;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxSort;

typedef Choice =
{
	var choices:Array<{name:String, callback:String->Void}>;
	var curSelected:Int;
}

class SelectionList extends FlxTypedGroup<Text>
{
	public var options:Array<String> = [];
	public var curSelected:Int = 0;
	public var choiceSelected(get, never):Int;
	public var topBound:Float = 173;
	public var bottomBound:Float = 520;
	public var parentMenu:SelectionList;
	public var focusedMenu:SelectionList;
	public var targetX:Float = 30;

	var callbacks:Map<String, Null<Float>->Void> = [];
	var choiceCallbacks:Map<String, Choice> = [];
	var submenus:Map<String, SelectionList> = [];
	var nextQ:Map<String, Array<String>> = [];
	var lists:Map<String, Bool> = [];
	var _defY:Float;
	var _spacing:Float;
	var _borderStyle:FlxTextBorderStyle;
	var topMenu(get, never):SelectionList;
	var scrollSelected:Int = 0;
	var scrollAmount:Int = 0;

	function get_topMenu():SelectionList
	{
		var menu = this;
		while (menu.parentMenu != null)
			menu = menu.parentMenu;
		return menu;
	}

	function get_choiceSelected():Int
	{
		if (choiceCallbacks.exists(options[curSelected]))
			return choiceCallbacks.get(options[curSelected]).curSelected;
		else
			return -1;
	}

	public function addChoices(option:String, choices:Array<{name:String, callback:String->Void}>, defaultIndex:Int = 0, mustSelect:Bool = false,
			hasLabel:Bool = false)
	{
		if (options.contains(option))
		{
			var myCallback:Null<Float>->Void = myFloat ->
			{
				choiceCallbacks.get(option)
					.curSelected = Std.int(FlxMath.bound(choiceCallbacks.get(option)
						.curSelected + myFloat, 0, choiceCallbacks.get(option).choices.length - 1));
				members[options.indexOf(option)].text = choiceCallbacks.get(option).choices[choiceCallbacks.get(option).curSelected].name;

				members[options.indexOf(option)].text = '${choiceCallbacks.get(option).curSelected > 0 ? '< ' : ''}${members[options.indexOf(option)].text}${choiceCallbacks.get(option).curSelected < choiceCallbacks.get(option).choices.length - 1 ? ' >' : ''}';

				if (!mustSelect || myFloat == 0 || myFloat == null)
					choiceCallbacks.get(option)
						.choices[choiceCallbacks.get(option)
							.curSelected].callback(choiceCallbacks.get(option).choices[choiceCallbacks.get(option).curSelected].name);
			};
			callbacks.set(option, myCallback);
			return this;
		}
		else
		{
			if (options.contains('Back'))
				options.insert(options.lastIndexOf('Back'), option);
			else
				options.push(option);

			choiceCallbacks.set(option, {curSelected: defaultIndex, choices: choices});
			updateText(hasLabel);
			members[options.indexOf(option)].text = '${choiceCallbacks.get(option).curSelected > 0 ? '< ' : ''}${choiceCallbacks.get(option).choices[choiceCallbacks.get(option).curSelected].name}${choiceCallbacks.get(option).curSelected < choiceCallbacks.get(option).choices.length - 1 ? ' >' : ''}';
			return addChoices(option, choices, defaultIndex, mustSelect, hasLabel);
		}
	}

	public function addCallback(option:String, callback:Null<Float>->Void, silent:Bool = false, usesFloat:Bool = false):SelectionList
	{
		if (options.contains(option) && callback != null)
		{
			if (usesFloat)
				lists.set(option, true);
			if (nextQ.exists(option))
			{
				var myCallback:Null<Float>->Void = myFloat ->
				{
					if (!usesFloat && myFloat != 0 && myFloat != null)
						return;

					nextQ.get(option).push(members[options.indexOf(option)].text);
					members[options.indexOf(option)].text = nextQ.get(option).shift();
					if (nextQ.get(option)[0] == option)
						callbacks.set(option, callback);
					else
						addCallback(option, callback);
				};
				callbacks.set(option, myCallback);
				return this;
			}
			if (!silent)
			{
				var myCallback:Null<Float>->Void = myFloat ->
				{
					if (!usesFloat && myFloat != 0 && myFloat != null)
						return;

					callback(myFloat);
				};
				callbacks.set(option, myCallback);
			}
			else
			{
				var myCallback:Null<Float>->Void = myFloat ->
				{
					if (!usesFloat && myFloat != 0 && myFloat != null)
						return;

					callback(myFloat);
				};
				callbacks.set(option, myCallback);
			}
			return this;
		}
		else
		{
			var split = option.split('>');
			option = split.shift();
			if (split.length >= 1)
				nextQ.set(option, split);
			if (options.contains('Back'))
				options.insert(options.lastIndexOf('Back'), option);
			else
				options.push(option);
			updateText();
			return addCallback(option, callback, silent, usesFloat);
		}
	}

	public function addSubmenu(option:String, submenu:SelectionList):SelectionList
	{
		if (options.contains(option) && submenu != null)
		{
			submenu.parentMenu = this;
			submenu.addCallback('Back', myFloat ->
			{
				submenu.curSelected = 0;
				submenu.scrollSelected = 0;
				submenu.scrollAmount = 0;
				topMenu.focusedMenu = submenu.parentMenu;
			});
			submenus.set(option, submenu);
			addCallback(option, myFloat ->
			{
				topMenu.focusedMenu = submenu;
			});
		}
		else
		{
			var split = option.split('>');
			option = split.shift();
			if (split.length >= 1)
				nextQ.set(option, split);
			if (options.contains('Back'))
				options.insert(options.lastIndexOf('Back'), option);
			else
				options.push(option);
			updateText();
			return addSubmenu(option, submenu);
		}
		return this;
	}

	public function select(amount:Float = 0, option:String = '')
	{
		if (option == 'Back')
		{
			if (callbacks.exists('Back'))
				callbacks.get('Back')(null);

			return;
		}
		if (callbacks.get(options[curSelected]) == null)
			return;
		callbacks.get(options[curSelected])(amount != 0 ? amount : null);
	}

	public function updateText(newTextsHaveLabels:Bool = false)
	{
		for (i in 0...options.length)
		{
			var textExists:Bool = false;
			forEach(text -> if (text.originalText == options[i])
			{
				textExists = true;
				text.ID = i; // reset the ID in case the index was changed.
			});
			if (textExists)
				continue;
			var newText:Text = new Text(0, 0, 0, options[i], 64, true, true, _borderStyle);
			newText.y = _defY + (_spacing * i);
			if (newTextsHaveLabels)
				newText.addLabel(options[i], 32);
			newText.ID = i;
			add(newText);
		}

		members.sort((t1, t2) -> FlxSort.byValues(FlxSort.ASCENDING, t1.ID, t2.ID));
	}

	override public function new(defaultTextY:Float = 0, defaultSpacing:Float = 50, borderStyle:FlxTextBorderStyle = SHADOW)
	{
		super();
		_defY = defaultTextY;
		_spacing = defaultSpacing;
		_borderStyle = borderStyle;
		updateText();
		focusedMenu = this;
	}

	override public function update(elapsed:Float)
	{
		var focused = topMenu.focusedMenu == this;
		forEach(text ->
		{
			var targetY = _defY + (_spacing * text.ID) - (_spacing * scrollAmount);
			text.y = FlxMath.lerp(text.y, targetY, 0.2);
			text.x = FlxMath.lerp(text.x, targetX, .3);
			text.alpha = FlxMath.lerp(text.alpha, focused ? 1 : .25, .2);
			var index = members.indexOf(text);
			if (lists.exists(options[index]))
				text.text = '< ${options[index]} >';
			if (nextQ.exists(options[text.ID]) && text.ID != curSelected)
				if (nextQ.get(options[text.ID]).contains(options[text.ID]))
				{
					nextQ.get(options[text.ID]).push(text.text);
					while (nextQ.get(options[text.ID])[0] != options[text.ID])
						nextQ.get(options[text.ID]).push(text.text = nextQ.get(options[text.ID]).shift());
					text.text = nextQ.get(options[text.ID]).shift();
					addCallback(options[text.ID], callbacks.get(options[text.ID]));
				}
			if (text.clipRect != null)
			{
				text.clipRect.put();
				text.clipRect = null;
			}
			if (text.y < topBound)
			{
				var yDiff = topBound - text.y;
				text.clipRect = FlxRect.get(0, yDiff, text.width, text.height - yDiff);
			}
			else if (text.y + text.height > bottomBound)
			{
				var yDiff = text.y + text.height - bottomBound;
				text.clipRect = FlxRect.get(0, 0, text.width, text.height - yDiff);
			}
		});
		for (menu in submenus)
			menu.update(elapsed);
		super.update(elapsed);
	}

	override public function draw()
	{
		super.draw();
		for (menu in submenus)
			menu.draw();
	}

	public function setAllRight()
	{
		for (menu in submenus)
			menu.setAllRight();
		targetX = FlxG.width;
	}

	public function scroll(amount:Int, boundOffs:Int = 0)
	{
		var bound = FlxPoint.get(0,
			options.length > (_spacing > 70 ? 3 + boundOffs : 4 + boundOffs) ? (_spacing > 70 ? 3 + boundOffs : 4 + boundOffs) : options.length - 1);
		scrollSelected += amount;
		if (scrollSelected < bound.x || scrollSelected > bound.y)
			scrollAmount = Std.int(FlxMath.bound(scrollAmount + amount, 0, options.length - scrollSelected));
		scrollSelected = Std.int(FlxMath.bound(scrollSelected, bound.x, bound.y));
		bound.put();
	}
}
