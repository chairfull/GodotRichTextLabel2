@tool
extends RicherTextEffect
## Sine wave effect.

## [sin]]
var bbcode := "sin"

func _update() -> bool:
	var sn := get_float("sin", 1.0)
	var fr := get_float("freq", 1.0)
	var sp := get_float("speed", 1.0)
	offset.y += weight * sin(time * 12.0 * sp + range.x * fr) * font_size * .1 * sn
	return true
