@tool
extends RichTextEffectBase
## Fades characters in more randomly.
## You should set 'fade_speed' to a low value for this to look right. 

## Syntax: [prickle pow=2][]
var bbcode = "prickle"

func _process_custom_fx(c: CharFXTransform):
	var power: float = c.env.get("pow", 2.0)
	var a := get_animation_delta(c)
	var r = rand(c)
	a = clamp(a * 2.0 - r, 0.0, 1.0)
	a = pow(a, power)
	c.color.a = a
	send_back_transform(c)
	return true
