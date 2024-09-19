@tool
extends RichTextEffectBase
## Sine wave effect.

## Syntax: [sin][]
var bbcode = "sin"

func _process_custom_fx(c: CharFXTransform):
	var t: RicherTextLabel = get_label2()
	var sn: float = c.env.get("sin", 1.0)
	var fr: float = c.env.get("freq", 1.0)
	var sp: float = c.env.get("speed", 1.0)
	c.offset.y += sin(c.elapsed_time * 12.0 * sp + c.range.x * fr) * t.font_size * .05 * sn
	return true
