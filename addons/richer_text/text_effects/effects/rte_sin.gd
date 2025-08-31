@tool
extends RTxtEffect
## Sine wave effect.

## [sin]]
var bbcode := "sin"

func _update() -> bool:
	var sn := get_float("sin", 1.0)
	var fr := get_float("freq", 0.5)
	var sp := get_float("speed", 1.0)
	var t := time * 12.0 * sp + range.x * fr
	offset.y += weight * sin(t) * font_size * .1 * sn
	skew = cos(t) * .1
	return true
