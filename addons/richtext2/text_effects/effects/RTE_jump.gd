@tool
extends RichTextEffect

# Syntax: [jump=45][]
var bbcode = "jump"

const SPLITTERS := " .,"

var _w_char = 0
var _last = 999

func _process_custom_fx(c:CharFXTransform):
	var t: RicherTextLabel = instance_from_id(get_meta("rt"))
	
	if c.absolute_index < _last or c.character in SPLITTERS:
		_w_char = c.absolute_index
	
	_last = c.absolute_index
	var a = deg_to_rad(c.env.get("angle", 0))
	var s = -abs(sin(-c.elapsed_time * 6.0 + _w_char * PI * .025))
	s *= c.env.get("scale", 1.0) * t.size * .125
	c.offset.x += sin(a) * s
	c.offset.y += cos(a) * s
	return true
