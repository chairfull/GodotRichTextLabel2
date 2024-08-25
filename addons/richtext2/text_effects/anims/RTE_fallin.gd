@tool
extends RichTextEffectBase
## Characters fall in one at a time.

## Syntax: [fallin][]
var bbcode = "fallin"

func _process_custom_fx(c: CharFXTransform):
	var delta: float = ease_back_out(get_animation_delta(c))
	c.color.a *= delta
	var cs := get_char_size(c) * Vector2(0.5, -0.25)
	c.transform *= Transform2D.IDENTITY.translated(cs)
	c.transform *= Transform2D.IDENTITY.scaled(Vector2.ONE * (1.0 + (1.0 - delta) * 2.0))
	c.transform *= Transform2D.IDENTITY.translated(-cs)
	send_back_transform(c)
	return true
