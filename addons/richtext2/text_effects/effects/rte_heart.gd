@tool
extends RichTextEffectBase
## Hear beat jumping, and turning into a heart shape.

## Syntax: [heart scale=1.0 freq=8.0][]
var bbcode = "heart"

const TO_CHANGE := "oOaA"

func _process_custom_fx(c: CharFXTransform):
	var scale: float = c.env.get("scale", 16.0)
	var freq: float = c.env.get("freq", 2.0)

	var x =  c.relative_index / scale - c.elapsed_time * freq
	var t = abs(cos(x)) * max(0.0, smoothstep(0.712, 0.99, sin(x))) * 2.5;
	c.color = c.color.lerp(Color.BLUE.lerp(Color.RED, t), t)
	c.offset.y -= t * 4.0
	
	if c.offset.y < -1.0:
		if get_char(c) in TO_CHANGE and FontHelper.has_emoji_font():
			var font := FontHelper.get_emoji_font()
			if font:
				c.font = font.get_rids()[0]
				c.transform *= Transform2D.IDENTITY.scaled(Vector2.ONE * 0.6)
				c.offset.y -= 6.0
				set_char(c, "❤️")
			else:
				set_char(c, "•")
	
	return true
