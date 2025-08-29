@tool
extends RichTextEffectBase
## Wacky random animations.
## Randomly scales and rotates characters.

var bbcode := "wack"

func _process_custom_fx(c: CharFXTransform):
	var cs := get_char_size(c) * Vector2(0.5, -0.3)
	c.transform *= Transform2D.IDENTITY.translated(cs)
	c.transform *= Transform2D.IDENTITY.rotated((cos(c.relative_index + c.elapsed_time) + sin(get_rand(c) + c.elapsed_time * 3.0)) * .125)
	c.transform *= Transform2D.IDENTITY.scaled(Vector2.ONE * (1.0 + cos(get_rand(c) * .5 + c.relative_index * 3.0 + c.elapsed_time * 1.3) * .125))
	c.transform *= Transform2D.IDENTITY.translated(-cs)
	return true
