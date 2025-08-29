@tool
class_name RTxtScatterer extends RTxtModifier

## Automatically repeats the bbcode multiple times, so you can draw the same text in multiple places.
@export_range(0, 3) var repeat_input := 0
@export var nodes: Array[NodePath]
@export var horizontal_alignment := HORIZONTAL_ALIGNMENT_CENTER
@export var vertical_alignment := VERTICAL_ALIGNMENT_CENTER
## Attempt to clamp text to the viewport. Doesn't quite work with rotations.
@export var viewport_clamp := true
@export var viewport_margin := Vector2i(16, 16)
## Copy the rotation of the nodes.
@export var copy_rotation := true
@export var copy_scale := true

var _rects: Array[Rect2]
var _char_bounds: Array[PackedVector2Array]
var _line_height: float

func _preparse(bbcode: String) -> String:
	label.clip_contents = false ## Needed for if characters are out of rect.
	label.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED ## Needed for when tooltip is out of rect.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	var lines := bbcode.split("\n")
	if lines.size() == 1 and repeat_input != 0:
		for i in repeat_input:
			lines.append(lines[0])
	
	var id := get_instance_id()
	for i in lines.size():
		var target: Node
		if i < nodes.size() and nodes[i]:
			target = label.get_node(nodes[i])
		if not target and i < label.get_child_count():
			target = label.get_child(i)
		if target:
			lines[i] = "[scatr id=%s pid=%s ln=%s]%s]" % [id, target.get_instance_id(), i, lines[i]]
	
	return "\n".join(lines)

func _finished():
	var fnt := label.get_theme_font(&"normal_font")
	var fnt_size := label.get_theme_font_size(&"normal_font_size")
	var lines := label.get_parsed_text().split("\n")
	_rects.resize(lines.size())
	_char_bounds.resize(label.get_parsed_text().length())
	_line_height = fnt.get_ascent(fnt_size) + fnt.get_descent(fnt_size)
	for i in lines.size():
		var size := fnt.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fnt_size)
		_rects[i] = Rect2(0.0, 0.0, size.x, size.y)
