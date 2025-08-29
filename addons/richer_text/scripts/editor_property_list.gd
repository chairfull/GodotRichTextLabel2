@tool
class_name EditorProperties extends RefCounted

var _list: Array[Dictionary]

func _init(list := []) -> void:
	_list.assign(list)

func group(name: String, hint_string: String) -> EditorProperties:
	return prop(name, TYPE_NIL, PROPERTY_HINT_NONE, hint_string, PROPERTY_USAGE_GROUP)

func subgroup(name: String, hint_string: String) -> EditorProperties:
	return prop(name, TYPE_NIL, PROPERTY_HINT_NONE, hint_string, PROPERTY_USAGE_SUBGROUP)

func res(name: StringName, type: String = "Resource") -> EditorProperties:
	return prop(name, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, type)

func button(name: StringName, text: String = "Click") -> EditorProperties:
	return prop(name, TYPE_CALLABLE, PROPERTY_HINT_TOOL_BUTTON, text, PROPERTY_USAGE_EDITOR)

func boolean(name: StringName) -> EditorProperties:
	return prop(name, TYPE_BOOL)

func node_path(name: StringName) -> EditorProperties:
	return prop(name, TYPE_NODE_PATH)

func color(name: StringName) -> EditorProperties:
	return prop(name, TYPE_COLOR)

func integer(name: StringName) -> EditorProperties:
	return prop(name, TYPE_INT)

func integer_enum(name: StringName, en: Variant) -> EditorProperties:
	en = en if en is String else ",".join(en.keys().map(func(s): return s.capitalize()))
	return prop(name, TYPE_INT, PROPERTY_HINT_ENUM, en)

func string(name: StringName) -> EditorProperties:
	return prop(name, TYPE_STRING)

func string_enum(name: StringName, keys: Variant) -> EditorProperties:
	return prop(name, TYPE_STRING, PROPERTY_HINT_ENUM_SUGGESTION, ",".join(keys))

func tween_trans(name: StringName) -> EditorProperties:
	return prop(name, TYPE_INT, PROPERTY_HINT_ENUM, "Linear:0,Sine:1,Quint:2,Quart:3,Quad:4,Expo:5,Elastic:6,Cubic:7,Circ:8,Bounce:9,Back:10,Spring:11")

func tween_ease(name: StringName) -> EditorProperties:
	return prop(name, TYPE_INT, PROPERTY_HINT_ENUM, "In:0,Out:1,In Out:2,Out In:3")

func number_range(name: StringName, minn = 0.0, maxx = 1.0) -> EditorProperties:
	return prop(name, TYPE_FLOAT, PROPERTY_HINT_RANGE, "%s,%s" % [minn, maxx])

func number(name: StringName) -> EditorProperties:
	return prop(name, TYPE_FLOAT)

func node(name: StringName, hint_string: String = "") -> EditorProperties:
	return prop(name, TYPE_OBJECT, PROPERTY_HINT_NODE_TYPE, hint_string)

func dict(name: StringName, hint_string: String) -> EditorProperties:
	if true and Engine.get_version_info().hex >= 0x040400:
		#var hint_string := "%s;%s" % [type_string(typeof(a)), type_string(typeof(b))]
		# PROPERTY_HINT_DICTIONARY_TYPE = 38
		return prop(name, TYPE_DICTIONARY, 38, hint_string)
	else:
		return prop(name, TYPE_DICTIONARY)

func file(name: StringName, types: PackedStringArray = []) -> EditorProperties:
	return prop(name, TYPE_STRING, PROPERTY_HINT_FILE, "" if not types else ("*." + ",*.".join(types)))

func dir(name: StringName) -> EditorProperties:
	return prop(name, TYPE_STRING, PROPERTY_HINT_DIR)

func enum_cursor(name: StringName) -> EditorProperties:
	return integer_enum(name, CursorShape)

func prop(name: StringName, type: int, hint: PropertyHint = PROPERTY_HINT_NONE, hint_string: String = "", usage := PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE) -> EditorProperties:
	_list.append({ name=name, type=type, usage=usage, hint=hint, hint_string=hint_string })
	return self

func end() -> Array[Dictionary]:
	return _list

enum CursorShape {
	ARROW = 0,			# Arrow cursor. Standard, default pointing cursor.
	IBEAM = 1,			# I-beam cursor. Usually used to show where the text cursor will appear when the mouse is clicked.
	POINTING_HAND = 2,	# Pointing hand cursor. Usually used to indicate the pointer is over a link or other interactable item.
	CROSS = 3,			# Cross cursor. Typically appears over regions in which a drawing operation can be performed or for selections.
	WAIT = 4,			# Wait cursor. Indicates that the application is busy performing an operation, and that it cannot be used during the operation.
	BUSY = 5,			# Busy cursor. Indicates that the application is busy performing an operation, and that it is still usable during the operation.
	DRAG = 6,			# Drag cursor. Usually displayed when dragging something.
						# Note: Windows lacks a dragging cursor, so DRAG is the same as MOVE for this platform.
	CAN_DROP = 7,		# Can drop cursor. Usually displayed when dragging something to indicate that it can be dropped at the current position.
	FORBIDDEN = 8,		# Forbidden cursor. Indicates that the current action is forbidden or that the control at a position is disabled.
	VSIZE = 9,			# Vertical resize mouse cursor. Double-headed vertical arrow.
	HSIZE = 10,			# Horizontal resize mouse cursor. Double-headed horizontal arrow.
	BDIAGSIZE = 11,		# Window resize cursor (↘↖). Bottom-left to top-right diagonal double-headed arrow.
	FDIAGSIZE = 12,		# Window resize cursor (↙↗). Top-left to bottom-right diagonal double-headed arrow.
	MOVE = 13,			# Move cursor. Indicates that something can be moved.
	VSPLIT = 14,		# Vertical split cursor. On Windows, same as VSIZE.
	HSPLIT = 15,		# Horizontal split cursor. On Windows, same as HSIZE.
	HELP = 16			# Help cursor. Usually a question mark.
}
