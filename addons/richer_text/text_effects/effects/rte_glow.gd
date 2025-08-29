@tool
class_name RTE_Glow extends RicherTextEffect
## TODO: Unfinished test class

@export var glow_color := Color.TOMATO
@export var glow_outline_color := Color.GREEN_YELLOW
@export var glow_speed := 1.0

func _update() -> bool:
	color = lerp(glow_color, glow_outline_color, sin(time * glow_speed))
	return true
