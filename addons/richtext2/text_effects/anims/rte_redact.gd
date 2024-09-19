@tool
extends RichTextEffectBase

# Syntax: [redact freq wave][]
var bbcode = "redact"

const SPACE := " "
const BLOCK := "█"
const MID_BLOCK := "▓"

func _process_custom_fx(c: CharFXTransform):
	var a := get_animation_delta(c)
	
	if is_animation_fading_out():
		c.color.a = a
	
	else:
		if a == 0 and (get_char(c) != SPACE or c.relative_index % 2 == 0):
			var freq: float = c.env.get("freq", 1.0)
			var scale: float = c.env.get("scale", 1.0)
			set_char(c, "X")#MID_BLOCK if a < 1.0 else BLOCK)
			c.color = Color.BLACK
			#c.offset = Vector2.ZERO
#			c.offset.y = sin(c.absolute_index * freq) * scale
	
	send_back_transform(c)
	return true
