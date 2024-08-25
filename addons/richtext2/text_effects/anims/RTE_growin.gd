@tool
extends RichTextEffectBase
## Grows characters in one at a time.

## Syntax: [growin][]
var bbcode = "growin"

func _process_custom_fx(c: CharFXTransform):
	var delta: float = ease_back_out(get_animation_delta(c), 2.0)
	c.color.a *= delta
	var cs := get_char_size(c) * Vector2(0.5, -0.25)
	c.transform *= Transform2D.IDENTITY.translated(cs)
	c.transform *= Transform2D.IDENTITY.scaled(Vector2.ONE * delta)
	c.transform *= Transform2D.IDENTITY.translated(-cs)
	send_back_transform(c)
	return true
