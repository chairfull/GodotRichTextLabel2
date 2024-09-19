@tool
extends RichTextEffectBase
## Fades words in one at a time.

## Syntax: [cfac][]
var bbcode = "fromcursor"

func _process_custom_fx(c: CharFXTransform):
	var delta := get_animation_delta(c)
	# Send position back early so ctc isn't weird.
	send_back_transform(c)
	c.color.a *= delta
	c.transform.origin = get_mouse_pos(c).lerp(c.transform.origin, pow(delta, 0.25))
	return true
