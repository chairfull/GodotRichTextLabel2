@tool
extends RichTextEffectBase
## Bounces text in.

## Syntax: [back scale=8.0][]
var bbcode = "back"

const c1 := 1.70158
const c3 := c1 + .5

func ease_back(x):
	return c3 * x * x * x - c1 * x * x

func _process_custom_fx(c: CharFXTransform):
	var a := 1.0 - get_animation_delta(c)
	var scale = c.env.get("scale", 1.0)
	c.offset.y += ease_back(a) * get_label2().font_size * scale
	c.color.a *= (1.0 - a)
	send_back_transform(c)
	return true
