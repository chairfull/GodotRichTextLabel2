@tool
extends RTxtEffect
## Bounces text in.

## Syntax: [back scale=8.0][]
var bbcode = "back"

func _process_custom_fx(c: CharFXTransform):
	var a := 1.0 - get_char_delta(c)
	var scale = c.env.get("scale", 1.0)
	c.offset.y += ease_back(a) * label.font_size * scale
	c.color.a *= (1.0 - a)
	send_back_transform(c)
	return true
