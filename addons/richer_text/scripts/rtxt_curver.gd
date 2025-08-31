@tool
class_name RTxtCurver extends RTxtModifier

@export_node_path("Path2D") var curve: NodePath
@export_range(0.0, 1.0, 0.01) var offset := 0.0 ## Offset along the curve. Curve must be larger than text.
@export var rotate := true ## Rotate with the curve normal.
@export var skew := true ## Skew with the curve normal.
@export_range(0, 8) var increase_spaces := 0 ## Add more spaces between text.
var _sizes: PackedVector2Array

func _preparse(bbcode: String) -> String:
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_contents = false
	
	if increase_spaces > 0:
		bbcode = bbcode.replace(" ", " ".repeat(1+increase_spaces))
	
	return "[curve id=%s]%s]" % [get_instance_id(), super(bbcode)]

func _finished():
	super()
	
	var txt := label.get_parsed_text()
	_sizes.resize(txt.length())
	var fnt := label.get_theme_default_font()
	var fnt_size := label.font_size
	var off := 0.0
	for i in txt.length():
		var chr_size := fnt.get_string_size(txt[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fnt_size)
		_sizes[i] = Vector2(off, chr_size.x)
		off += chr_size.x
	
#func _get_property_list() -> Array[Dictionary]:
	#return EditorProperties.new(super())\
		#.boolean(&"position_enabled")\
		#.prop(&"position_curve", TYPE_OBJECT)\
		#.end()
