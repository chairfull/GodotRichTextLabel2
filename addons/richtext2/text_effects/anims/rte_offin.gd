@tool
extends RichTextEffectBase
## Characters are offset into place.

## Syntax: [offin][]
var bbcode = "offin"

func _process_custom_fx(c: CharFXTransform):
	var delta: float = get_animation_delta(c)
	c.color.a *= delta
	c.offset.x = -get_char_size(c).x * (1.0 - delta)
	send_back_transform(c)
	return true
