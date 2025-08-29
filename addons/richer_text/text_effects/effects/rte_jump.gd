@tool
class_name RTE_Jump extends RicherTextEffect
## Jumps up and down.

## Syntax: [jump angle=45]]
var bbcode := "jump"

const SPLITTERS := " .,"

@export_range(-180.0, 180.0, 1.0, "radians_as_degrees") var jump_angle := 0.0
@export_range(0.0, 1.0, 0.01) var jump_scale := 1.0

var _w_char = 0
var _last = 999

func _update() -> bool:
	if absolute_index < _last or chr in SPLITTERS:
		_w_char = absolute_index
	
	_last = absolute_index
	var a := jump_angle + deg_to_rad(get_float(&"angle", 0.0))
	var s := -absf(sin(-time * 6.0 + _w_char * PI * .025))
	s *= jump_scale * get_float(&"scale", 1.0) * font_size * .125 * weight
	position += Vector2(sin(a), cos(a)) * s
	return true
