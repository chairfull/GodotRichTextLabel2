@tool
extends RichTextEffectBase

## Syntax: [woo scale=1.0 freq=8.0][]
var bbcode = "woo"

func _process_custom_fx(c: CharFXTransform):
	var scale: float = c.env.get("scale", 1.0)
	var freq: float = c.env.get("freq", 8.0)
	if rand_anim(c) > 0.5:
		var ch := get_char(c)
		if ch == ch.to_lower():
			set_char(c, ch.to_upper())
		elif ch == ch.to_upper():
			set_char(c, ch.to_lower())
	return true
