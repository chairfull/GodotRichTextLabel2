@tool
extends RichTextEffectBase

## Syntax: [rain][]
var bbcode = "rain"

func _process_custom_fx(c: CharFXTransform):
	var r = rand_anim(c)
	c.offset.y += r * 8.0
	c.color.a = lerp(c.color.a, 0.0, r)
	return true
