@tool
extends RicherTextEffect

## Syntax: [jump2 angle=45][]
var bbcode := "jump2"

func _update() -> bool:
	var a := deg_to_rad(get_float(&"angle", 0.0))
	var s := sin(-time * 4.0 + index * PI * .125)
	s = -abs(pow(s, 4.0)) * 2.0
	s *= get_float(&"size", 1.0) * font_size * .125
	position += Vector2(sin(a), cos(a)) * s
	return true
