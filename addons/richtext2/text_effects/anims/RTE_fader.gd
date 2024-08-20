## Fades words in one at a time.
@tool
extends RichTextEffectBase

## Syntax: [fader][]
var bbcode = "fader"

func _process_custom_fx(c: CharFXTransform):
	c.color.a *= get_animation_delta(c)
	send_back_transform(c)
	return true
