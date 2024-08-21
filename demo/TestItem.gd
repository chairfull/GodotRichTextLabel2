@tool
class_name TestItem
extends Resource

@export var name: String
@export var color: Color

func to_string_nice() -> String:
	return "[%s;b]%s[]" % [color, name]
