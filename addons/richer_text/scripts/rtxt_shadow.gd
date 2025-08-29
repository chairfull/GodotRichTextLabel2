@tool
class_name RTxtShadow extends Resource
## Handles shadow settings for easy reuse.

@export var enabled: bool = true:
	set(e):
		enabled = e
		changed.emit()

## In pixels.
@export_range(0.0, 16.0, 0.1, "suffix:pixels") var distance := 4.0:
	set(o):
		distance = o
		changed.emit()

@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var angle := PI*.25:
	set(d):
		angle = d
		changed.emit()

@export_color_no_alpha var color := Color.BLACK:
	set(c):
		color = c
		changed.emit()

@export_range(0.0, 1.0) var alpha := 0.25:
	set(a):
		alpha = a
		changed.emit()

## Relative to font_size.
@export var outline_size := 0.1:
	set(o):
		outline_size = o
		changed.emit()
