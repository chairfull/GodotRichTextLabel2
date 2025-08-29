@tool
class_name RTxtLinkList extends RTxtModifier
## Treats each line as a link, and calls

@export var use_signals := true ## Will fire link_hovered, link_unhovered.
@export var use_tooltip_text := true ## Will set labels tooltip_text, causing a popup to show.
@export var can_right_click := false
var tooltips: Dictionary[String, String]

func _preparse(bbcode: String) -> String:
	tooltips.clear()
	var lines := bbcode.strip_edges().split("\n")
	for i in lines.size():
		var parts := lines[i].split("|", true, 1)
		var id := parts[0].to_kebab_case()
		var tooltip := ""
		if parts.size() == 2:
			tooltip = parts[1]
		tooltips[id] = tooltip
		lines[i] = "[=call:%s:_clicked:%s]%s]" % [get_instance_id(), id, tr(parts[0], &"main_menu")]
	return "\n".join(lines)

func _clicked(id: String):
	label.link_clicked.emit(id)
	return true

func _clicked_right_clicked(id: String):
	if can_right_click:
		label.link_right_clicked.emit(id)
		return true
	return false

func _clicked_hovered(id: String):
	if use_signals:
		label.link_hovered.emit(id)
		return true
	if use_tooltip_text:
		return tooltips.get(id, "")
	return ""

func _clicked_unhovered(id: String):
	if use_signals:
		label.link_unhovered.emit(id)
		return true
	if use_tooltip_text:
		return ""
	return ""
