@tool
class_name RTxtParser extends Resource

"""
TODO:
	- fill stack w tags, but never push them until you get to text
		- before printing, allow for tag sorting, so certain effects can run before others
		- when closing a stack, remember the order of the printing
		- when doing an old fashioned close [/tag], reprint opening tags, so you can do mixed order [b]bold[i]bold italic[/b]italic[/i]
			mixed order currently isn't allowed in godot, but shouldn't be impossible to implement
"""

static var link_hovered: Signal = _add_signal(&"url_hovered", { label=TYPE_OBJECT, link_index=TYPE_INT })
static var link_unhovered: Signal = _add_signal(&"url_unhovered", { label=TYPE_OBJECT, link_index=TYPE_INT })
static var link_clicked: Signal = _add_signal(&"url_clicked", { label=TYPE_OBJECT, link_index=TYPE_INT })
static var link_right_clicked: Signal = _add_signal(&"url_right_clicked", { label=TYPE_OBJECT, link_index=TYPE_INT })
static var _get_all_rtp: Signal = _add_signal(&"get_all_rtp")
signal started()
signal install_effect(effect)
signal changed_font()
signal changed_font_size()
signal changed_outline()

const EXT_IMAGE: PackedStringArray = ["png", "jpg", "jpeg", "webp", "svg"]
const EXT_AUDIO: PackedStringArray = ["mp3", "ogg", "wav"]
const FONT_BOLD_WEIGHT := 1.2
const FONT_ITALICS_SLANT := 0.25
const FONT_ITALICS_WEIGHT := -.25
const FONT_SIZE_MIN := 8
const FONT_SIZE_MAX := 128
const BBCODE_BUILTIN: PackedStringArray = ["b", "i", "u", "s", "left", "right", "center", "fill", "url"]
const DIR := "res://addons/richer_text/"
const DIR_TEXT_EFFECTS := DIR + "text_effects/effects"
const DIR_TEXT_ANIMATIONS := DIR + "text_effects/anims"
const DIR_TEXT_MODIFIERS := DIR + "text_effects/mods"
const PATH_EMOJIS := DIR + "emoji.json"
const PATH_DEFAULT_PARSER := "res://assets/richer_text_parser.tres"
static var REGEX_REPLACE_CONTEXT := RegEx.create_from_string(r"(?<!\\)@(?:[a-zA-Z][a-zA-Z0-9_]*|-?\d+)(?:\.[a-zA-Z0-9_]+)*(?:\([^\)]*\))?(?![^\[\]]*\])")
static var REGEX_REPLACE_CONTEXT_2 := RegEx.create_from_string(r"\{.*?\}")
static var REGEX_EMOJI := RegEx.create_from_string(r"~[a-zA-Z0-9/_-]+(?=\b|[^a-zA-Z0-9/_-])")
static var REGEX_NODE_OR_OBJECT := RegEx.create_from_string(r"(?:([A-Za-z0-9_]+):)?<([A-Za-z0-9_]+)#(-?\d+)>")
static var REGEX_TAG_HEAD := RegEx.create_from_string("^[/=!]?(\\w+)") # [tag] [tag=true] [tag prop=true] all return "tag"
static var REGEX_URL := RegEx.create_from_string(r"\[url(?:=([^\]]+)| ([^\]]+))?\](.*?)(?:\[/url\]|\[\]|(?<=\S)\])")

enum OutlineMode {
	OFF, ## Disables outline.
	DARKEN, ## Outlines will be darker than text color.
	LIGHTEN, ## Outlines will be lighter than text color.
	CUSTOM, ## Uses outline_color for all text.
	CUSTOM_DARKEN, ## Uses outline_color by default, but darkens colored text outlines.
	CUSTOM_LIGHTEN, ## Uses outline_color by default, but lightens colored text outlines.
}

var _state: Dictionary
var _stack: Array[Dictionary]
var _effects: Dictionary
var _output: PackedStringArray
var _output_stripped: PackedStringArray
var _context_node: Node
var _expression_error := OK
var _links: Dictionary[int, String]
var _offset: int
var _waypoints: Dictionary[int, String]

@export_group("Test", "test_")
@export_multiline var test_string := ""
@export_multiline var test_string_output := ""
@export_multiline var test_string_output_stripped := ""
@export_tool_button("Test") var test_button := func(): parse(test_string)

@export var colors_custom: Dictionary[StringName, Color]
@export var colors_allow_builtin := true ## Use built in colors?

@export var bbcode_shortcuts: Dictionary[StringName, String] ## Merge many tags into an easy to remember tag: [mytag] -> [b;custom_font;red]

## Pre-parsers run before anything else happens.
@export var regexes: Array[RTxtParserRegex]
@export_dir var custom_effects_dir := "res://assets/richer_text_effects"

#region Font
var font_db: FontDB = FontDB.get_default()

## Primary font to use.
var font_default: StringName:
	set(f):
		font_default = f
		changed_font.emit()

## Default color used.
var font_color := Color.WHITE:
	set(c):
		font_color = c
		changed_font.emit()

## Default size.
## Use float tags [2.0] to resize relative.
## Use int tags [32] to resize absolute.
var font_size := 32:
	set(x):
		font_size = clampi(x, FONT_SIZE_MIN, FONT_SIZE_MAX)
		changed_font_size.emit()

## Custom font thickness when using bold tag.
var font_bold_weight := 1.5:
	set(f):
		font_bold_weight = f
		changed_font.emit()
		
## Custom font slant when using italics tag. (Can be negative.)
var font_italics_slant := 0.25:
	set(f):
		font_italics_slant = f
		changed_font.emit()

## Custom font thickness when using italics tag.
var font_italics_weight := -.25:
	set(f):
		font_italics_weight = f
		changed_font.emit()
#endregion

#region Emoji
## Path to emoji font.
var emoji_font: String

## Relative to font_size.
## Used with bbcode :banana:.
var emoji_scale := 1.0:
	set(x):
		emoji_scale = x
		changed.emit()

## Allow using the :emoji: pattern for including images.
var emoji_images := true

## Directory to look for images inside of. 
var emoji_images_dir := "res://"

#endregion

#region Outline
var outline_size := 0:
	set(o):
		outline_size = o
		changed.emit()
		changed_outline.emit()

## Automatically colorize outlines based on font color.
var outline_mode: OutlineMode = OutlineMode.DARKEN:
	set(o):
		outline_mode = o
		changed.emit()
		changed_outline.emit()
		notify_property_list_changed()

## Used with OutlineMode.CUSTOM, OutlineMode.CUSTOM_DARKEN, OutlineMode.CUSTOM_LIGHTEN.
var outline_color := Color.BLACK:
	set(x):
		outline_color = x
		changed.emit()
		changed_outline.emit()
		#_update_theme_outline()

## How much to shift outline color.
var outline_adjust := 0.8:
	set(x):
		outline_adjust = x
		changed.emit()
		changed_outline.emit()
		#_update_theme_outline()

## Nudges the tint of the outline so it isn't identical to the font.
## Produces more contrast.
var outline_hue_adjust := 0.0125:
	set(x):
		outline_hue_adjust = x
		changed.emit()
		changed_outline.emit()
		#_update_theme_outline()
#endregion

#region Markdown
var markdown_enabled := true
var markdown_custom: Dictionary[String, String] = {
	"*": "[i]%s]",
	"**": "[b]%s]",
	"***": "[b;i]%s]",
	"~": "[s]%s]",
	'"': "“%s”"
}
#endregion

#region Context
## Uses @pattern and {pattern} to replace text with state data.
## Can be call a method: "I have @player.item_count("coins") coins."
## Even array elements: "Slot 3 has @slots[3] in it.
## When only a method name is passed it will be automatically called.
var context_enabled := false
## The main node to get properties from.
var context_path: NodePath = ^"/root/State"
## Access autoloads like in regular gdscript: @Global.get_tree().get_nodes_in_group("chars")
var context_allow_autoloads := true
## Access classes like in regular gdscript.
var context_allow_global_classes := true
## Access `Engine` and other built in singletons.
var context_allow_engine_singletons := true
## Allowed globals. If none set all will be allowed.
var context_classes_allowed: PackedStringArray
## Blocked globals. If none set all will be allowed.
var context_classes_blocked: PackedStringArray
## Extra properties you can access inside the expressions.
var context_state: Dictionary[StringName, Variant]
## Will attempt to call `to_richtext()` on objects.
## If that doesn't work it looks for a `name` property.
## Otherwise `to_string()` is used.
var context_rich_objects := true
## Will automatically add commas to integers: 1234 -> 1,234
var context_rich_ints := true
## Will display an array as comma seperated items.
## Uses rich_objects and rich_ints if they are enabled.
var context_rich_array := true
#endregion

#region Link
var link_effect: RTxtLinkEffect ## Effect to animated links on hover & clicked.
var link_cursor := Input.CURSOR_POINTING_HAND
var link_tooltip_cursor := Input.CURSOR_HELP
var link_tooltip_scene: String ## TODO: Not implemented. Custom scene to load instead of the default tooltip.
var link_audio_enabled := true ## Enable audio for link on hover & clicked.
var link_audio_path_hovered := "" ## Sound played on hovered.
var link_audio_path_unhovered := "" ## Sound played on unhovered.
var link_audio_path_clicked := "" ## Sound played on clicked.
var link_audio_path_right_clicked := "" ## Sound played on right clicked.
var link_audio_path_tooltip_hovered := "" ## Sound played on tooltip hovered.
var link_audio_path_tooltip_unhovered := "" ## Sound played on tooltip unhovered.
#endregion

## Try to find a default parser resource in the "res://assets/" folder.
static func get_default() -> RTxtParser:
	if Engine.is_editor_hint():
		if not FileAccess.file_exists(PATH_DEFAULT_PARSER):
			if not DirAccess.dir_exists_absolute(PATH_DEFAULT_PARSER.get_base_dir()):
				DirAccess.make_dir_recursive_absolute(PATH_DEFAULT_PARSER.get_base_dir())
			var parser := RTxtParser.new()
			var err := ResourceSaver.save(parser, PATH_DEFAULT_PARSER)
			if err != OK:
				push_error("Parser: ", error_string(err))
	return load(PATH_DEFAULT_PARSER)

func parse(input: String, context_node: Node = null, links: Dictionary[int, String] = {}) -> String:
	_context_node = context_node
	_links = links
	_links.clear()
	_offset = 0
	_waypoints.clear()
	
	started.emit()
	
	var output := input
	
	# Replace any links that may already exist.
	output = _replace(output, REGEX_URL, func(rm: RegExMatch):
		var link_index := _add_link(rm.strings[1])
		return "[link id=%s]%s[/link]" % [link_index, rm.strings[3]])
	
	# Replace Godot node and object strings
	# Label:<MyLabel#32152512341241>
	# <MyObject#5324326132309>
	output = _replace(output, REGEX_NODE_OR_OBJECT, func(rm: RegExMatch): return "@%s" % rm.strings[3])
	
	# User defined parsers.
	for rep in regexes:
		output = rep._run(output, self)
	
	# Context replace.
	if context_enabled and _context_node:
		# @pattern
		output = _replace(output, REGEX_REPLACE_CONTEXT, func(rm: RegExMatch): return _expression_rich(rm.strings[0], rm.strings[0].trim_prefix("@")))
		
		# {} pattern
		output = _replace(output, REGEX_REPLACE_CONTEXT_2, func(rm: RegExMatch): return _expression_rich(rm.strings[0], str_unwrap(rm.strings[0], "{}")))
	
	# Emojis
	output = _replace(output, REGEX_EMOJI, func(rm: RegExMatch):
		var emoji_id := rm.strings[0].trim_prefix("~")
		for ext in EXT_IMAGE:
			var img_path := "%s%s.%s" % [emoji_images_dir, emoji_id, ext]
			if FileAccess.file_exists(img_path):
				var height := font_size * emoji_scale
				return "[img height=%s]%s[/img]" % [height, img_path]
		var json := FileAccess.get_file_as_string(PATH_EMOJIS)
		var data := JSON.parse_string(json)
		if data and emoji_id in data.named:
			return data.named[emoji_id]
		return rm.strings[0])
	
	if markdown_enabled:
		var keys := markdown_custom.keys()
		keys.sort_custom(func(a, b): return a.length() > b.length())
		for key in keys:
			output = _replace_wrapped(output, key, markdown_custom[key])
	
	_clear()
	var i := 0
	var n := output.length()
	while i < n:
		var ch := output[i]
		if ch == "[":
			var j := i+1
			var closed := false
			while j < n:
				var chj := output[j]
				if chj == "]":
					closed = true
					break
				j += 1
			var inner := output.substr(i+1, j-i-1)
			if closed:
				_tags(inner)
			else:
				_add_text(inner)
			i = j
		elif ch == "]":
			if _stack:
				_pop_last()
		elif ch == "<":
			var j := i+1
			var closed := false
			while j < n:
				var chj := output[j]
				if chj == ">":
					closed = true
					break
				j += 1
			var inner := output.substr(i+1, j-i-1)
			if closed:
				_waypoints[_offset] = inner
			else:
				_add_text(inner)
			i = j
		else:
			_add_text(ch)
		i += 1
	output = "".join(_output)
	
	test_string_output = output
	test_string_output_stripped = "".join(_output_stripped)
	_clear()
	_context_node = null
	_links = {}
	
	return output

func prnt(...args):
	print_rich(parse("".join(args)))

func prnts(...args):
	print_rich(parse(" ".join(args)))

func _clear():
	_state = {}
	_stack = []
	_output = []
	_output_stripped = []
	_effects.clear()

func _pop_last():
	if _stack:
		var keys := _stack[-1].keys()
		for i in range(keys.size()-1, -1, -1):
			_remove_tag(keys[i])
		_stack.pop_back()

func _add_tag(tag: String, is_first_tag := false, tag_state: Variant = null) -> bool:
	if not tag in _state:
		if is_first_tag:
			_stack.append({})
			is_first_tag = false
		_state[tag] = tag_state
		_stack[-1][tag] = tag_state
		if tag_state is String:
			_output.append("[%s]" % tag_state)
		elif tag_state is Dictionary:
			_output.append("[%s]" % (_state_to_tag_str(tag_state)))
		else:
			_output.append("[%s]" % tag)
	return is_first_tag

func _remove_tag(tag: String):
	if tag in _state:
		_state.erase(tag)
	for i in range(_stack.size()-1, -1, -1):
		if tag in _stack[i]:
			_stack[i].erase(tag)
			_output.append("[/%s]" % tag)
			break

func _add_text(txt: String):
	_output.append(txt)
	_output_stripped.append(txt)
	_offset += txt.length()

func _tags(tag_str: String):
	var tags: PackedStringArray
	for tag in tag_str.split(";"):
		if tag in bbcode_shortcuts:
			tags.append_array(bbcode_shortcuts[tag].split(";"))
		else:
			tags.append(tag)
	
	var is_first_tag := true
	for full_tag in tags:
		var rm := RegEx.create_from_string(r"^[/=!]?[^\]\s]+").search(full_tag)
		var tag := rm.strings[0] if rm else ""
		if not rm:
			_add_text(full_tag)
		elif tag == "":
			_pop_last()
		elif tag.begins_with("="):
			var index := _add_link(full_tag.substr(1))
			is_first_tag = _add_tag("link", is_first_tag, "link id=%s" % index)
		elif tag.begins_with("/"):
			var open_tag := tag.substr(1)
			if open_tag in BBCODE_BUILTIN:
				_remove_tag(open_tag)
			else:
				var state := _get_tag_state(open_tag, full_tag.substr(1))
				if state:
					for item in (state if state is Array else [state]):
						_remove_tag(item.tag)
				else:
					_add_text("[%s]" % full_tag)
		else:
			if tag in BBCODE_BUILTIN:
				is_first_tag = _add_tag(tag, is_first_tag, full_tag)
			else:
				var state := _get_tag_state(tag, full_tag)
				if state:
					for item in (state if state is Array else [state]):
						is_first_tag = _add_tag(item.tag, is_first_tag, item)
				else:
					_add_text("[%s]" % full_tag)

func _add_link(data: Variant) -> int:
	var link_index := _links.size()
	if data is Object:
		_links[link_index] = "id:%s" % (data as Object).get_instance_id()
	elif not data is String:
		_links[link_index] = JSON.stringify(data, "", false)
	else:
		_links[link_index] = data
	return link_index

## Returns a Dictionary or Array of Dictionaries.
func _get_tag_state(tag: String, full_tag: String) -> Variant:
	# Links to functions.
	if tag.begins_with("!"):
		var parts := tag.trim_prefix("!").split(" ")
		var method: Callable = _expression(parts[0])
		var obj_id := method.get_object_id()
		var meth_name := method.get_method()
		var meth_args := "&".join(parts.slice(1))
		var link_index := _add_link("call:%s:%s:%s" % [obj_id, meth_name, meth_args])
		return [{ tag="link", id=link_index }]
	
	# Effects.
	var effect := _to_effect(tag)
	if effect != null:
		if tag != "link" and not tag in _effects:
			_effects[tag] = true
			install_effect.emit(effect)
		return { tag=tag, _rest=full_tag }
	
	var flt := _to_float(tag)
	if flt != null:
		return { tag="font_size", font_size=int(font_size * flt) }
	
	if tag.is_valid_int():
		return { tag="font_size", font_size=font_size+int(tag) }
	
	var fnt := null if not font_db else font_db.paths.get(tag, null)
	if fnt != null:
		return { tag="font", font=fnt }
	
	var clr := _to_color(tag)
	if clr != Color.TRANSPARENT:
		if " " in full_tag:
			var clr2_str := tag.split(" ", true, 1)[-1]
			var clr2 := _to_color(clr2_str)
			if clr2 == Color.TRANSPARENT:
				# ERROR: Color was malformed.
				clr2 = clr.darkened(0.5)
			if outline_size == 0:
				return [
					{ tag="outline_size", outline_size=4 },
					{ tag="color", color=clr },
					{ tag="outline_color", outline_color=clr2 } ]
			else:
				return [
					{ tag="color", color=clr },
					{ tag="outline_color", outline_color=clr2 } ]
		else:
			if outline_size != 0:
				return [
					{ tag="color", color=clr },
					{ tag="outline_color", outline_color=clr.darkened(0.5) }
				]
			else:
				return { tag="color", color=clr }
	
	return {}

func _state_to_tag_str(state: Dictionary) -> String:
	if "_rest" in state:
		return state._rest
	
	var out: PackedStringArray = []
	if not state.tag in state:
		out.append(state.tag)
	for key in state:
		if key != &"tag":
			match typeof(state[key]):
				TYPE_COLOR: out.append("%s=#%s" % [key, (state[key] as Color).to_html(false)])
				_: out.append("%s=%s" % [key, state[key]])
	return " ".join(out)

func _to_effect(tag: String) -> RichTextEffect:
	for dir in [DIR_TEXT_EFFECTS, DIR_TEXT_ANIMATIONS, DIR_TEXT_MODIFIERS, custom_effects_dir]:
		if not dir:
			continue
		for ext in ["gd", "gdc"]:
			var path = dir.path_join("rte_%s.%s" % [tag, ext])
			if FileAccess.file_exists(path):
				var effect: RichTextEffect = load(path).new()
				effect.resource_name = tag
				effect.setup_local_to_scene()
				return effect
	return null
	
func _to_float(tag: String) -> Variant:
	if "." in tag:
		for c in tag:
			if not c in "0123456789.":
				return null
		return float(tag)
	return null

func _to_color(tag: String, default := Color.TRANSPARENT) -> Color:
	# Check if raw color was passed.
	if tag.begins_with("(") and tag.ends_with(")"):
		var floats := str_unwrap(tag, "()").split_floats(",")
		return Color(floats[0], floats[1], floats[2], floats[3])
	# 1st check custom colors.
	if tag in colors_custom:
		return colors_custom[tag]
	# 2nd check builtin colors.
	if colors_allow_builtin:
		return Color().from_string(tag, default)
	return default

func _regex_escape(s: String) -> String:
	var specials := ".*+?^${}()|[]\\"
	var out := ""
	for c in s:
		if specials.find(c) != -1:
			out += "\\" + c
		else:
			out += c
	return out

func _rich_variant(thing: Variant) -> String:
	if thing is Callable:
		return _rich_variant(thing.call())
	if context_rich_ints and typeof(thing) == TYPE_INT:
		return str_commas(thing)
	if context_rich_objects and typeof(thing) == TYPE_OBJECT:
		var output := ""
		if thing.has_method(&"to_richtext"):
			output = thing.to_richtext()
		elif &"name" in thing:
			output = thing.name
		else:
			output = str(thing)
		
		var is_link := false
		if thing.has_method(&"_richtext_clicked"):
			var link_index := _add_link(thing)
			output = "[link id=%s]%s[/link]" % [link_index, output]
			is_link = true
		
		if not is_link and &"tooltip_text" in thing:
			output = "[hint=%s]%s[/hint]" % [thing.tooltip_text, output]
		
		return output
	if context_rich_array and typeof(thing) == TYPE_ARRAY:
		return ", ".join(Array(thing).map(_rich_variant))
	return str(thing)

func _expression_rich(exp: String, exp_clean: String, state2 := {}) -> String:
	var value: Variant
	# Passed an instance id number?
	if exp_clean.is_valid_int():
		value = instance_from_id(int(exp_clean))
	# Property or method of instance id number?
	elif "." in exp_clean and exp_clean.split(".", true, 1)[0].is_valid_int():
		var parts := exp_clean.split(".", true, 1)
		var instance := instance_from_id(int(parts[0]))
		var new_exp_clean := "_MYINST_.%s" % parts[1]
		value = _expression(new_exp_clean, { _MYINST_=instance })
	else:
		value = _expression(exp_clean, state2)
	return _rich_variant(value) if _expression_error == OK else ("[red]%s]" % exp)

func _replace(text: String, re: RegEx, call: Callable) -> String:
	var offset := 0
	var output: PackedStringArray
	while offset < text.length() and re:
		var rm := re.search(text, offset)
		if rm:
			output.append(text.substr(offset, rm.get_start() - offset))
			output.append(call.call(rm))
			offset = rm.get_end()
		else:
			output.append(text.substr(offset))
			offset = text.length()
	return "".join(output)

func _replace_wrapped(text: String, tag: String, format: String) -> String:
	return _replace_between(text, tag, tag, func(rm: RegExMatch): return format % rm.get_string(1))

func _replace_between(text: String, head: String, tail: String, call: Callable) -> String:
	var esc_head := _regex_escape(head)
	var esc_tail := _regex_escape(tail)
	var re := RegEx.create_from_string(esc_head + r"(.*?)" + esc_tail)
	return _replace(text, re, func(rm: RegExMatch): return call.call(rm))

func _expression(ex: String, state2 := {}) -> Variant:
	var context: Object = null
	if _context_node and _context_node.is_inside_tree():
		context = _context_node.get_tree().root.get_node(context_path)
	else:
		var local := get_local_scene()
		if local:
			context = local.get_node(context_path)
	
	if not context:
		return "???"
	
	# If a pipe is present.
	if "|" in ex:
		# Get all pipes.
		var pipes := ex.split("|")
		var ex_prepipe := pipes[0]
		# Get initial value of expression.
		var got: Variant = _expression(ex_prepipe)
		for i in range(1, len(pipes)):
			var pipe_parts := pipes[i].split(" ")
			# First arg is pipe method name.
			var pipe_meth := pipe_parts[0]
			# Rest are arguments. Convert to an array.
			# Does method exist in context node?
			if context and context.has_method(pipe_meth):
				var arg_str := "[%s]" % [", ".join(pipe_parts.slice(1))]
				var pipe_args: Array = [got] + _expression(arg_str)
				got = context.callv(pipe_meth, pipe_args)
			else:
				var s2 := { "_GOT_": got }
				var arg_str := []
				for j in len(pipe_parts)-1:
					var key := "_ARG%s_" % j
					s2[key] = _expression(pipe_parts[j+1])
					arg_str.append(key)
				var p_exp := "_GOT_.%s(%s)" % [pipe_meth, ", ".join(arg_str)]
				got = _expression(p_exp, s2)
		return got
	
	_expression_error = OK
	var e := Expression.new()
	var returned: Variant = null
	var con_args := context_state.keys() if context_state else []
	var con_vals := context_state.values() if context_state else []
	
	if state2:
		con_args = con_args + state2.keys()
		con_vals = con_vals + state2.values()
	
	#TODO: Cache all these references.
	
	if context_allow_engine_singletons:
		for name in Engine.get_singleton_list():
			if context_classes_blocked and name in context_classes_blocked:
				continue
			if not context_classes_allowed or name in context_classes_allowed:
				con_args.append(name)
				con_vals.append(Engine.get_singleton(name))
	
	if context_allow_autoloads:
		for child in context.get_node("/root/").get_children():
			if "@" in child.name:
				continue
			if context_classes_blocked and child.name in context_classes_blocked:
				continue
			if not context_classes_allowed or child.name in context_classes_allowed:
				con_args.append(child.name)
				con_vals.append(child)
	
	if context_allow_global_classes:
		for data in ProjectSettings.get_global_class_list():
			if context_classes_blocked and data.class in context_classes_blocked:
				continue
			if not context_classes_allowed or data.class in context_classes_allowed:
				con_args.append(data.class)
				con_vals.append(load(data.path))
	
	_expression_error = e.parse(ex, con_args)
	if _expression_error == OK:
		returned = e.execute(con_vals, context, false)
	
	if e.has_execute_failed():
		_expression_error = FAILED
		push_error(e.get_error_text())
		return null
	
	return returned



#region String
static func str_unwrap(t: String, w: String) -> String:
	return t.trim_prefix(w[0]).trim_suffix(w[-1])

# 1234567 => 1,234,567
static func str_commas(number: Variant) -> String:
	var string := str(number)
	var is_neg := string.begins_with("-")
	if is_neg:
		string = string.substr(1)
	var mod = len(string) % 3
	var out = ""
	for i in len(string):
		if i != 0 and i % 3 == mod:
			out += ","
		out += string[i]
	return "-" + out if is_neg else out
#endregion

#region Editor
func _property_can_revert(property: StringName) -> bool:
	return RTxtParser.new().get(property) != null

func _property_get_revert(property: StringName) -> Variant:
	return RTxtParser.new().get(property)

func _get_property_list():
	var props := EditorProperties.new()\
		.group("Font", "font_")\
		.res(&"font_db", "FontDB")\
		.string_enum(&"font_default", [] if not font_db else font_db.paths.keys())\
		.integer(&"font_size")\
		.color(&"font_color")\
		.number(&"font_bold_weight")\
		.number(&"font_italics_slant")\
		.number(&"font_italics_weight")
	
	props.group("Emoji", "emoji_")\
		#.file(&"emoji_font", EXT_FONT)\
		.number_range(&"emoji_scale", 0.1, 2.0)\
		.boolean(&"emoji_images_enabled")\
		.dir(&"emoji_images_dir")
		
	props.group("Outline", "outline_")\
		.integer(&"outline_size")\
		.integer_enum(&"outline_mode", OutlineMode)
	if outline_mode in [OutlineMode.CUSTOM, OutlineMode.CUSTOM_DARKEN, OutlineMode.CUSTOM_LIGHTEN]:
		props.color(&"outline_color")
	if outline_mode in [OutlineMode.DARKEN, OutlineMode.LIGHTEN, OutlineMode.CUSTOM_DARKEN, OutlineMode.CUSTOM_LIGHTEN]:
		props.number_range(&"outline_adjust")
		props.number_range(&"outline_hue_adjust")
	
	props.group("Context", "context_")\
		.boolean(&"context_enabled")\
		.node_path(&"context_path")\
		.dict(&"context_state", "StringName;Variant")\
		.boolean(&"context_allow_autoloads")\
		.boolean(&"context_allow_global_classes")\
		.boolean(&"context_allow_engine_singletons")\
		.prop(&"context_classes_allowed", TYPE_PACKED_STRING_ARRAY)\
		.prop(&"context_classes_blocked", TYPE_PACKED_STRING_ARRAY)\
		.boolean(&"context_rich_objects")\
		.boolean(&"context_rich_ints")\
		.boolean(&"context_rich_array")
	
	props.group("Link", "link_")\
		.res(&"link_effect", "RTxtLinkEffect")\
		.enum_cursor(&"link_cursor")\
		.enum_cursor(&"link_tooltip_cursor")\
		.file(&"link_tooltip_scene", ["scn", "tscn"])\
		.boolean(&"link_audio_enabled")\
		.subgroup("Audio Paths", "link_audio_path_")\
		.file(&"link_audio_path_hovered", EXT_AUDIO)\
		.file(&"link_audio_path_unhovered", EXT_AUDIO)\
		.file(&"link_audio_path_clicked", EXT_AUDIO)\
		.file(&"link_audio_path_right_clicked", EXT_AUDIO)\
		.file(&"link_audio_path_tooltip_hovered", EXT_AUDIO)\
		.file(&"link_audio_path_tooltip_unhovered", EXT_AUDIO)
	
	return props.end()
	
#endregion

static func _add_signal(name: StringName, var_types := {}):
	var targ: Object = RTxtParser
	if not targ.has_signal(name):
		var args := []
		for var_name in var_types:
			args.append({ "name": var_name, "type": var_types[var_name] })
		targ.add_user_signal(name, args)
	return Signal(RTxtParser, name)
