@tool
extends RichTextEffectBase

## Syntax: [rain][]
var bbcode = "rain"

func _process_custom_fx(c: CharFXTransform):
	var r = fmod(cos(get_rand(c) * .125 + sin(c.relative_index * .5 + c.elapsed_time * .6) * .25) + c.elapsed_time * .5, 1.0)
	c.offset.y += (r - .25) * 8.0
	c.color.a = lerp(c.color.a, 0.0, r)
	return true
