@tool
extends RichTextEffectBase
## Invisible unless cursor is near it.

## Syntax: [secret][]
const bbcode = "secret"

func _process_custom_fx(c: CharFXTransform):
	var dif := c.transform.origin - get_mouse_pos(c)
	var dis := dif.length()
	c.color.a = clampf(8.0 - (dis / 8.0), 0.0, 1.0)
	return true
