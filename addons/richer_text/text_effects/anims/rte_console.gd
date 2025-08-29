@tool
extends RTxtEffect

## Syntax: [console][]
var bbcode = "console"

const SPACE := " "
const CURSOR := "█"
const CURSOR_COLOR := Color.GREEN_YELLOW

func _process_custom_fx(c: CharFXTransform):
	var lbl := label
	
	if is_animation_fading_out():
		var a := get_char_delta(c)
		c.color.a *= a
		c.offset.y -= lbl.font_size * .5 * (1.0 - a)
		
	else:
		if lbl.progress == 1.0:
			if lbl.visible_character-1 == c.range.x and sin(c.elapsed_time * 16.0) > 0.0:
				set_char(c, CURSOR)
				c.color = CURSOR_COLOR
				c.offset = Vector2.ZERO
		
		else:
			
			if lbl.visible_character == c.range.x:
				if get_char(c) == SPACE:
					c.color.a = 0.0
				else:
					set_char(c, CURSOR)
					c.color = CURSOR_COLOR
					c.offset = Vector2.ZERO
			
			else:
				c.color.a *= get_char_delta(c)
	
	send_back_transform(c)
	return true
