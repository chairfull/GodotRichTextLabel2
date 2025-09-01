@tool
class_name RTE_Sin extends RTxtEffect
## Sine wave effect.

## [sin sin=float speed=float freq=float skew=float][/sin]
var bbcode := "sin"

@export var sin_scale := 1.0
@export var freq := 0.5
@export var speed := 1.0
@export var skew_scale := 0.2

func _update() -> bool:
	var t := time * get_float(&"speed", speed)
	t += range.x * get_float(&"freq", freq) * font_size
	position.y += sin(t) * font_size * .25 * get_float(&"sin", sin_scale) * weight
	skew_y = cos(t) * get_float(&"skew", skew_scale) * weight
	return true
