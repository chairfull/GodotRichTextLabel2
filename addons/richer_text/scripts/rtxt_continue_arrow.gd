@tool
class_name RTxtContinueArrow extends CanvasItem
## Simple base class for an indicator to be displayed at the end of the RicherTextLabel.

signal enabled()
signal disabled()

func _ready() -> void:
	var anim := get_animation()
	if anim:
		anim.indicator_enabled.connect(enabled.emit)
		anim.indicator_disabled.connect(disabled.emit)

func get_animation() -> RTxtAnimator:
	var parent := get_parent()
	if parent is RicherTextLabel:
		return (parent as RicherTextLabel).get_animation()
	return null
