@tool
class_name RTxtTicker extends RTxtModifier

@export var speed := 1.0
@export var reverse := false
@export var divider := "   ●   "

func _preparse(bbcode: String) -> String:
	return "[ticker id=%s]%s]" % [get_instance_id(), divider.join(bbcode.split("\n")) + divider]
