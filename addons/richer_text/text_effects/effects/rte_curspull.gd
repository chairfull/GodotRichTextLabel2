@tool
extends RichTextEffectBase
## Pulls or pushes characters away from the cursor.
## Use a negative number for reverse effect.

## Syntax: [curspull 1.0][]
const bbcode = "curspull"

func _process_custom_fx(c: CharFXTransform):
	var pull: float = c.env.get("pull", 1.0)
	var dif := c.transform.origin - get_mouse_pos(c)
	var dis := dif.length()
	var nrm := dif.normalized() * -pull
	c.transform.origin += nrm * clampf(pow(dis * .1, 4.0), 0.1, 4.0)
	return true
