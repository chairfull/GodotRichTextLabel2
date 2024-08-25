@tool
extends RichTextEffectBase
## Sways the character back and forth.

var bbcode := "sway"

func _process_custom_fx(c: CharFXTransform):
	var sway := sin(c.elapsed_time * 2.0) * 0.25
	var s := get_char_size(c) * Vector2(0.5, -0.25)
	c.transform *= Transform2D.IDENTITY.translated(s)
	c.transform *= Transform2D(0.0, Vector2.ONE, sway, Vector2.ZERO)
	c.transform *= Transform2D.IDENTITY.translated(-s)
	return true
