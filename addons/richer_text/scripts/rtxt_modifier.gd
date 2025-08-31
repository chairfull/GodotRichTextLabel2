@tool
@abstract class_name RTxtModifier extends Resource

## Modifier will preparse bbcode.
var enabled := true:
	set(e):
		enabled = e
		changed.emit()

@export_storage var label: RicherTextLabel

## Called before set_text()
func _preparse(bbcode: String) -> String:
	label.bbcode_enabled = true
	return bbcode

## Called when text is done processing.
func _finished():
	pass

func _debug_draw(rtl: RicherTextLabel):
	pass

func _get_property_list() -> Array[Dictionary]:
	# , hint=PROPERTY_HINT_GROUP_ENABLE
	return [{ name=&"enabled", type=TYPE_BOOL }]
