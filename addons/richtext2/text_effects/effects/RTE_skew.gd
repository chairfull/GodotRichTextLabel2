@tool
extends RichTextEffectBase

var bbcode := "skew"

func _process_custom_fx(char_fx: CharFXTransform):
	char_fx.transform *= Transform2D(0.0, Vector2.ONE, sin(char_fx.elapsed_time) * 0.5, Vector2.ZERO)
	return true
