package;

import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class Text extends FlxText
{
	public var originalText:String;

	var labelText:Text;
	var labelTop:Bool;

	override public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true, customFont:Bool = true,
			borderStyle:FlxTextBorderStyle = SHADOW)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
		originalText = Text;

		setBorderStyle(borderStyle, FlxColor.BLACK, (Size < 8 ? Size / 4 : Size / 8) / (borderStyle == OUTLINE ? 2 : 1), 1);

		#if web
		var htmlDiff:Int = Math.floor(height - size) - 4;
		height -= htmlDiff;
		offset.y = htmlDiff;
		#end

		setPosition(Std.int(x), Std.int(y)); // Round the position to prevent weird tearing
	}

	public function addLabel(text:String, size:Int = 8, top:Bool = true)
	{
		labelText = new Text(0, 0, FlxG.width, text, size, true, true, borderStyle);
		labelText.alignment = CENTER;
		labelText.color = FlxColor.fromRGB(200, 200, 200);
		labelTop = top;
	}

	public function removeLabel()
	{
		labelText.destroy();
		labelText = null;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (labelText != null)
		{
			var yOff = labelText.size - 8;
			labelText.setPosition(x, labelTop ? y - labelText.height + yOff : y + height - yOff);
			labelText.alpha = alpha;
			var topBound:Float = 343;
			var bottomBound:Float = 630;
			if (labelText.clipRect != null)
			{
				labelText.clipRect.put();
				labelText.clipRect = null;
			}
			if (labelText.y < topBound)
			{
				var yDiff = topBound - labelText.y;
				labelText.clipRect = FlxRect.get(0, yDiff, labelText.width, labelText.height - yDiff);
			}
			else if (labelText.y + labelText.height > bottomBound)
			{
				var yDiff = labelText.y + labelText.height - bottomBound;
				labelText.clipRect = FlxRect.get(0, 0, labelText.width, labelText.height - yDiff);
			}
		}
	}

	override public function draw()
	{
		if (labelText != null)
			labelText.draw();
		super.draw();
	}
}
