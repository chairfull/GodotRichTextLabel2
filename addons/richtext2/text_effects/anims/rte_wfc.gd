@tool
extends RichTextEffectBase
## Simulates a "Wave Function Collapse" for each character.

## Syntax: [wfc][]
var bbcode = "wfc"

const SPACE := " "
const SYMBOLS := "10"

func _process_custom_fx(c: CharFXTransform):
	var a := get_animation_delta(c)
	
	if is_animation_fading_out():
		var aa = a + rand2(c) * a
		if aa < 1.0 and get_char(c) != SPACE:
			set_char(c, SYMBOLS[rand_anim(c, 8.0, len(SYMBOLS))])
			c.color.v -= .5
		
	else:
		var aa = a + rand2(c) * a
		if aa < 1.0 and get_char(c) != SPACE:
			set_char(c, SYMBOLS[rand_anim(c, 8.0, len(SYMBOLS))])
			c.color.v -= .5
	
	c.color.a = a
	send_back_transform(c)
	return true
