@tool
class_name RicherTextLabel
extends RichTextLabel

signal internal_pressed(variant: Variant)
signal internal_right_pressed(variant: Variant)
signal pressed(variant: Variant)
signal right_pressed(variant: Variant)

const DIR_TEXT_EFFECTS := "res://addons/richtext2/text_effects/effects"
const DIR_TEXT_TRANSITIONS := "res://addons/richtext2/text_effects/anims"
const TAG_OPENED := "["
const TAG_CLOSED := "]"
const MIN_FONT_SIZE := 8
const MAX_FONT_SIZE := 512

enum {
	T_NONE,
	T_COLOR, T_COLOR_OUTLINE, T_COLOR_BG, T_COLOR_FG,
	T_PARAGRAPH,
	T_CONDITION,
	T_BOLD, T_ITALICS, T_BOLD_ITALICS, T_UNDERLINE, T_STRIKE_THROUGH, T_CODE,
	T_META, T_HINT,
	T_FONT,
	T_FONT_SIZE,
	T_TABLE, T_CELL,
	T_EFFECT,
	T_PIPE,
	T_FLAG_CAP, T_FLAG_UPPER, T_FLAG_LOWER,
}

enum Align {
	NONE, ## No alignment tag added.
	LEFT, ## Autowraps string in "left" tags.
	CENTER, ## Autowraps string in "center" tags.
	RIGHT, ## Autowraps string in "right" tags.
	FILL, ## Autowraps string in "fill" tags.
}

enum OutlineStyle {
	OFF, ## No outline.
	DARKEN, ## Outline will be darker than font color.
	LIGHTEN, ## Outline will be lighter than font color.
}
enum EffectsMode {
	OFF, ## Disable text effects.
	OFF_IN_EDITOR, ## Don't animate effects in edit mode.
	ON, ## Enable text effects.
}

func _get_property_list():
	if not font_cache:
		_update_font_cache()
	var fonts := "," + ",".join(font_cache.keys())
	var props: Array[Dictionary]
	_prop(props, "bbcode", TYPE_STRING, PROPERTY_HINT_MULTILINE_TEXT)
	_prop_enum(props, "effects", EffectsMode)
	_prop_enum(props, "alignment", Align)
	_prop(props, "color", TYPE_COLOR)
	_prop(props, "emoji_scale", TYPE_FLOAT)
	
	_prop_group(props, "Font", "font_")
	_prop(props, "font", TYPE_STRING, PROPERTY_HINT_ENUM_SUGGESTION, fonts)
	_prop(props, "font_auto_setup", TYPE_BOOL)
	_prop(props, "font_size", TYPE_INT)
	_prop(props, "font_bold_weight", TYPE_FLOAT)
	_prop(props, "font_italics_slant", TYPE_FLOAT)
	_prop(props, "font_italics_weight", TYPE_FLOAT)
	_prop(props, "font_cache", TYPE_DICTIONARY)
	
	_prop_group(props, "Shadow", "shadow_")
	_prop(props, "shadow_enabled", TYPE_BOOL)
	_prop(props, "shadow_offset", TYPE_FLOAT)
	_prop_range(props, "shadow_alpha")
	_prop(props, "shadow_outline_size", TYPE_FLOAT)
	
	_prop_group(props, "Outline", "outline_")
	_prop(props, "outline_size", TYPE_INT)
	_prop_enum(props, "outline_mode", OutlineStyle)
	_prop_range(props, "outline_adjust")
	_prop_range(props, "outline_hue_adjust")
	
	_prop_group(props, "Nicer Quotes", "nicer_quotes_")
	_prop(props, "nicer_quotes_enabled", TYPE_BOOL)
	_prop(props, "nicer_quotes_format", TYPE_STRING)
	
	_prop_group(props, "Markdown", "markdown_")
	_prop(props, "markdown_enabled", TYPE_BOOL)
	_prop_subgroup(props, "Format", "markdown_format_")
	_prop(props, "markdown_format_bold", TYPE_STRING)
	_prop(props, "markdown_format_italics", TYPE_STRING)
	_prop(props, "markdown_format_bold_italics", TYPE_STRING)
	_prop(props, "markdown_format_highlight", TYPE_STRING)
	_prop(props, "markdown_format_bold2", TYPE_STRING)
	_prop(props, "markdown_format_italics2", TYPE_STRING)
	_prop(props, "markdown_format_bold_italics2", TYPE_STRING)
	
	_prop_group(props, "Context", "context_")
	_prop(props, "context_enabled", TYPE_BOOL)
	_prop(props, "context_path", TYPE_NODE_PATH)
	_prop(props, "context_state", TYPE_DICTIONARY, PROPERTY_HINT_DICTIONARY_TYPE, "StringName;Variant")
	_prop(props, "context_rich_objects", TYPE_BOOL)
	_prop(props, "context_rich_ints", TYPE_BOOL)
	_prop(props, "context_rich_array", TYPE_BOOL)
	
	_prop_group(props, "Auto Style", "autostyle_")
	_prop(props, "autostyle_numbers", TYPE_BOOL)
	_prop(props, "autostyle_numbers_tag", TYPE_STRING)
	_prop(props, "autostyle_numbers_pad_decimals", TYPE_BOOL)
	_prop(props, "autostyle_numbers_decimals", TYPE_INT)
	_prop(props, "autostyle_emojis", TYPE_BOOL)
	
	_prop_group(props, "Effect", "effect_")
	_prop_range(props, "effect_weight") 

	_prop_group(props, "Overrides", "override_")
	_prop(props, "override_bbcodeEnabled", TYPE_BOOL)
	_prop(props, "override_clipContents", TYPE_BOOL)
	_prop(props, "override_fitContent", TYPE_BOOL)
	
	
	return props

func _prop_group(list: Array[Dictionary], name: String, hint_string: String):
	list.append({ name=name, type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP, hint_string=hint_string })

func _prop_subgroup(list: Array[Dictionary], name: String, hint_string: String):
	list.append({ name=name, type=TYPE_NIL, usage=PROPERTY_USAGE_SUBGROUP, hint_string=hint_string })

func _prop_enum(list: Array[Dictionary], name: StringName, en: Variant):
	_prop(list, name, TYPE_INT, PROPERTY_HINT_ENUM, ",".join(en.keys().map(func(s): return s.capitalize())))

func _prop_range(list: Array[Dictionary], name: StringName, type: int = TYPE_FLOAT, minn = 0.0, maxx = 1.0):
	list.append({ name=name, type=type, usage=PROPERTY_USAGE_DEFAULT, hint=PROPERTY_HINT_RANGE, hint_string="%s,%s" % [minn, maxx] })

func _prop_node(list: Array[Dictionary], name: StringName, hint_string: String = ""):
	list.append({ name=name, type=TYPE_OBJECT, usage=PROPERTY_USAGE_DEFAULT, hint=PROPERTY_HINT_NODE_TYPE, hint_string=hint_string })

func _prop(list: Array[Dictionary], name: StringName, type: int, hint: PropertyHint = PROPERTY_HINT_NONE, hint_string: String = ""):
	list.append({ name=name, type=type, usage=PROPERTY_USAGE_DEFAULT, hint=hint, hint_string=hint_string })

## Text including bbcode to be converted.
var bbcode := "": set=set_bbcode

## Animating in the editor might be laggy.
var effects: EffectsMode = EffectsMode.ON:
	set(x):
		effects = x
		_redraw()

## Automatically align text.
var alignment: Align = Align.CENTER:
	set(x):
		alignment = x
		_redraw()

## Default font color.
var color := Color.WHITE:
	set(x):
		color = x
		_redraw()
		_update_color()

## Scales relative to font scale.
## Use bbcode [:+1:]. It is autoclosing.
var emoji_scale := 1.0:
	set(x):
		emoji_scale = x
		_redraw()

## Automatically search for -bold, -italic, -bolditalic, and -monospace.
var font_auto_setup := true
## Default font to use.
var font := "":
	set = set_font

## Default size.
## Use float tag [2.0] to resize relative.
## Use int tag [32] to resize absolute.
var font_size: int = 16:
	set(x):
		font_size = clampi(x, MIN_FONT_SIZE, MAX_FONT_SIZE)
		add_theme_font_size_override("bold_font_size", font_size)
		add_theme_font_size_override("bold_italics_font_size", font_size)
		add_theme_font_size_override("italics_font_size", font_size)
		add_theme_font_size_override("mono_font_size", font_size)
		add_theme_font_size_override("normal_font_size", font_size)
		_redraw()

## Custom font thickness when using bold tag.
var font_bold_weight := 1.5:
	set(f):
		font_bold_weight = f
		_update_subfonts()
		
## Custom font slant when using italics tag. (Can be negative.)
var font_italics_slant := 0.25:
	set(f):
		font_italics_slant = f
		_update_subfonts()

## Custom font thickness when using italics tag.
var font_italics_weight := -.25:
	set(f):
		font_italics_weight = f
		_update_subfonts()

## Used to prevent slow updating.
var font_cache: Dictionary

## Automatically sized based on font size.
var shadow_enabled: bool = false:
	set(v):
		shadow_enabled = v
		_update_theme_shadow()

var shadow_offset := 0.08:
	set(s):
		shadow_offset = s
		_update_theme_shadow()

var shadow_alpha := 0.25:
	set(s):
		shadow_alpha = s
		_update_theme_shadow()

var shadow_outline_size := 0.1:
	set(s):
		shadow_outline_size = s
		_update_theme_shadow()

func _update_theme_shadow():
	if shadow_enabled:
		add_theme_color_override("font_shadow_color", Color(0, 0, 0, shadow_alpha))
		add_theme_constant_override("shadow_offset_x", floor(font_size * shadow_offset))
		add_theme_constant_override("shadow_offset_y", floor(font_size * shadow_offset))
		add_theme_constant_override("shadow_outline_size", ceil(font_size * shadow_outline_size))
	else:
		remove_theme_color_override("font_shadow_color")
		remove_theme_constant_override("shadow_offset_x")
		remove_theme_constant_override("shadow_offset_y")
		remove_theme_constant_override("shadow_outline_size")

var outline_size := 0:
	set(o):
		outline_size = o
		add_theme_constant_override("outline_size", o)
		_redraw()
		_update_color()

## Automatically colorize outlines based on font color.
var outline_mode: OutlineStyle = OutlineStyle.DARKEN:
	set(o):
		outline_mode = o
		_redraw()
		_update_color()

## How much to shift outline color.
var outline_adjust := 0.8:
	set(x):
		outline_adjust = x
		_redraw()
		_update_color()

var outline_hue_adjust := 0.0125:
	set(x):
		outline_hue_adjust = x
		_redraw()
		_update_color()

## Display “Text” instead of "Text".
var nicer_quotes_enabled := true
var nicer_quotes_format := "“%s”"

## **bold** *italic* ***bold italic*** ~highlight~
var markdown_enabled := true
var markdown_format_italics := "[i]%s[]" ## _italic_
var markdown_format_bold := "[b]%s[]" ## __bold__
var markdown_format_bold_italics := "[bi]%s[]" ## ___bold italic___
var markdown_format_highlight := "[green;sin]%s[]" ## ~highlight~
var markdown_format_italics2 := "[i;gray]*%s*[]" ## *italic*
var markdown_format_bold2 := "[b]*%s*[]" ## **bold**
var markdown_format_bold_italics2 := "%s" ## ***bold italic***

var effect_weight := 0.0

## Will replace $properties in text.
## Can be a function: "I have $player.item_count("coins") coins."
## Or array elements: "Slot 3 has $slots[3] in it.
var context_enabled := true
## For use with $property to display node properties. 
var context_path: NodePath = ^"/root/State"
## Extra parameters that can be accessed in context.
var context_state: Dictionary[StringName, Variant] = {}
## Will attempt to call `to_rich_string()` on objects. Otherwise `.to_string()` is used.
var context_rich_objects := true
## Will automatically add commas to integers: 1234 -> 1,234
var context_rich_ints := true
## Will niceify arrays.
var context_rich_array := true

## Add tag to all numbers?
var autostyle_numbers := true
## Tag to wrap numbers in.
var autostyle_numbers_tag := "[salmon]%s[]"
## Automatically pad numbers to limit trailing decimals?
var autostyle_numbers_pad_decimals := true
## How many decimal places?
var autostyle_numbers_decimals := 2
## Automatically detects :smile: emojis.
var autostyle_emojis := true

## Override so bbcode_enabled = true at init.
var override_bbcodeEnabled := true:
	set(b):
		override_bbcodeEnabled = b
		bbcode_enabled = b

## Override s fit_content = true at init.
var override_fitContent := true:
	set(f):
		override_fitContent = f
		fit_content = f

## Some animations can go out of bounds. So override to disable clipping.
var override_clipContents := false:
	set(c):
		override_clipContents = c
		clip_contents = c

var _stack := []
var _state := {}
var _meta := {}
var _meta_hovered: Variant = null
var _expression_error := OK
@export_storage var _random: Array[int] ## Used in the effects as a random offset.

func _init():
	if not Engine.is_editor_hint():
		_connect_meta()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			if font_auto_setup:
				# Clear auto fonts so they aren't saved to disk.
				remove_theme_font_override("bold_font")
				remove_theme_font_override("bold_italics_font")
				remove_theme_font_override("italics_font")
				remove_theme_font_override("normal_font")
		
		NOTIFICATION_EDITOR_POST_SAVE:
			if font_auto_setup:
				_update_subfonts()

func _connect_meta():
	meta_hover_started.connect(_meta_hover_started)
	meta_hover_ended.connect(_meta_hover_ended)

func _meta_hover_started(meta: Variant):
	_meta_hovered = meta
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _meta_hover_ended(meta: Variant):
	_meta_hovered = null
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _meta_hovered != null:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				# Call a callable.
				if _meta_hovered in _meta:
					if _meta[_meta_hovered] is Callable:
						_meta[_meta_hovered].call()
					elif _meta_hovered.begins_with("_"):
						internal_pressed.emit(_meta[_meta_hovered])
					else:
						pressed.emit(_meta[_meta_hovered])
			
				# Goto URL.
				elif _meta_hovered.begins_with("https://"):
					OS.shell_open(_meta_hovered)
		
				else:
					push_error("No meta url for '%s'. %s" % [_meta_hovered, _meta.keys()])
				
				get_viewport().set_input_as_handled()

			MOUSE_BUTTON_RIGHT:
				if _meta_hovered in _meta:
					if _meta[_meta_hovered] is Callable:
						_meta[_meta_hovered].call()
					elif _meta_hovered.begins_with("_"):
						internal_right_pressed.emit(_meta[_meta_hovered])
					else:
						right_pressed.emit(_meta[_meta_hovered])
				else:
					push_error("No meta url for '%s'." % _meta_hovered)
				get_viewport().set_input_as_handled()

func _update_color():
	add_theme_color_override("font_outline_color", _get_outline_color(color))

var _last_drawn_at := 0
func _redraw():
	if is_inside_tree():
		var frame := get_tree().get_frame()
		if frame == _last_drawn_at:
			print("Skip _redraw")
			return
		_last_drawn_at = frame
	set_bbcode(bbcode)

func set_bbcode(btext: String):
	# When not in editor, don't keep updating.
	if not Engine.is_editor_hint() and bbcode == btext:
		return
	
	if not bbcode == btext:
		bbcode = btext
		#text = ""
		## HACK: Deferred so it outraces the set_text function.
		if is_inside_tree():
			_set_bbcode()
		else:
			await tree_entered
			_set_bbcode.call_deferred()

func _clear_font_cache():
	font_cache.clear()

func _update_font_cache():
	_clear_font_cache()
	FontHelper.get_font_paths(font_cache)

func _set_bbcode():
	clear()
	uninstall_effects()
	_stack.clear()
	_state = {
		color = color,
		color_bg = null,
		color_fg = null,
		align = alignment,
		font = font,
		font_size = font_size,
		opened = {},
		pipes = []
	}
	if not font_cache:
		font_cache = {}
		FontHelper.get_font_paths(font_cache)
	
	if color != Color.WHITE:
		_push_color(color)
	
	_parse(_preparse(bbcode))
	
	if color != Color.WHITE:
		_pop_color(Color.WHITE)
	
	var time := Time.get_ticks_msec()
	
	seed(hash(get_parsed_text()))
	_random = []
	for i in get_total_character_count():
		_random.append(randi())
	
	# TODO: Test.
	if override_fitContent:
		await finished
		if is_inside_tree():
			await get_tree().process_frame
		custom_minimum_size.y = get_content_height()

func _resize_to_content():
	autowrap_mode = TextServer.AUTOWRAP_OFF
	custom_minimum_size = Vector2(get_content_width(), get_content_height())
	size = custom_minimum_size
	set_anchors_preset(anchors_preset)

func set_meta_data(key: String, data: Variant):
	_meta[key] = data

func set_font(id: String):
	font = id
	_update_subfonts()

func _update_subfonts():
	return
	if font_auto_setup:
		FontHelper.set_fonts(self, font, font_bold_weight, font_italics_slant, font_italics_weight)

func get_normal_font() -> Font:
	return get_theme_font("normal_font")

func uninstall_effects():
	while len(custom_effects):
		custom_effects.pop_back()

func _preparse(btext :String) -> String:
	# Replace $ and {} properties.
	if context_enabled:
		btext = replace_context(btext)
	
	# Primary alignment.
	match alignment:
		1: btext = "[left]%s[]" % btext
		2: btext = "[center]%s[]" % btext
		3: btext = "[right]%s[]" % btext
		4: btext = "[fill]%s[]" % btext
	
	# Markdown.
	if markdown_enabled:
		# Hide bbcode with placeholders.
		var bbcode_placeholder: Array[String]
		btext = _replace(btext, r"\[[^\]]*\]|\{[^}]*\}|<[^>]*>", func(strings):
			var index := str(len(bbcode_placeholder))
			bbcode_placeholder.append(strings[0])
			return "&&" + index + "&&")
		
		# Replace markdown.
		btext = _replace(btext, r"(\*{1,3}[^*]+?\*{1,3}|_{1,3}[^_]+?_{1,3}|~[^~]+~)", func(strings):
			var tag: String = strings[0]
			# TODO: Improve this.
			if is_style(tag, "***"): return markdown_format_bold_italics2 % unwrap_stype(tag, "***")
			if is_style(tag, "___"): return markdown_format_bold_italics % unwrap_stype(tag, "___")
			if is_style(tag, "**"): return markdown_format_bold2 % unwrap_stype(tag, "**")
			if is_style(tag, "__"): return markdown_format_bold % unwrap_stype(tag, "__")
			if is_style(tag, "*"): return markdown_format_italics2 % unwrap_stype(tag, "*")
			if is_style(tag, "_"): return markdown_format_italics % unwrap_stype(tag, "_")
			if is_style(tag, "~"): return markdown_format_highlight % unwrap_stype(tag, "~")
			return tag
		)
		
		# Replace the placeholders.
		btext = _replace(btext, r"&&(\d+)&&", func(strings):
			return bbcode_placeholder[strings[1].to_int()])
	
	# Nicefy up stuff that isn't tagged.
	btext = _replace_outside(btext, TAG_OPENED, TAG_CLOSED, _preparse_untagged)
	
	return btext

# Parses anything outside of tags, like markdown and quotes.
func _preparse_untagged(btext: String) -> String:
	if btext == "":
		return btext
	
	# Open + closed quotes.
	if nicer_quotes_enabled:
		btext = _format_between(btext, '"', nicer_quotes_format)
	
	# Replace emojis.
	if autostyle_emojis:
		btext = replace_emojis(btext)
	
	if autostyle_numbers:
		btext = replace_numbers(btext)
	
	return btext

func _format_between(st: String, tag: String, frmt: String) -> String:
	return _replace_between(st, tag, func(strings): return frmt % strings[1])

# new version that works regardless of bbcode in the middle.
func _replace_between(st: String, tag: String, call: Callable) -> String:
	return _replace_between_both(st, tag, tag, call)

func _replace_between_both(st: String, head: String, tail: String, call: Callable) -> String:
	return _replace(st, escape_regex(head) + r"(.*?)" + escape_regex(tail), call)

func escape_regex(input: String) -> String:
	input = input.replace("\\", "\\\\")
	input = input.replace(".", "\\.")
	input = input.replace("^", "\\^")
	input = input.replace("$", "\\$")
	input = input.replace("*", "\\*")
	input = input.replace("+", "\\+")
	input = input.replace("?", "\\?")
	input = input.replace("(", "\\(")
	input = input.replace(")", "\\)")
	input = input.replace("[", "\\[")
	input = input.replace("]", "\\]")
	input = input.replace("{", "\\{")
	input = input.replace("}", "\\}")
	input = input.replace("|", "\\|")
	return input

func _replace(string: String, pattern: String, call: Callable) -> String:
	var regex := RegEx.create_from_string(pattern)
	var offset := 0
	var output := ""
	while true:
		var m := regex.search(string, offset)
		if not m:
			break
		output += string.substr(offset, m.get_start(0)-offset)
		output += str(call.call(m.strings))
		offset = m.get_end(0)
	output += string.substr(offset)
	return output

func replace_emojis(string: String) -> String:
	return _replace(string, r":([a-zA-Z0-9\+\-]+):", func(strings):
		if strings[1] in Emoji.NAMES:
			return "[:" + strings[1] + ":]"
		return strings[0])

func replace_context(string: String) -> String:
	# $pattern
	string = _replace(string, r"(?<!\\)\$[a-zA-Z0-9]+(?:_[a-zA-Z0-9]+)*(?:\.[a-zA-Z0-9]+(?:_[a-zA-Z0-9]+)*)*(?:\([^\)]*\))?(?![^\[\]]*\])", func(strings):
		var path = strings[0]
		return _get_expression_rich(path, path.trim_prefix("$")))
	
	# {} pattern
	string = _replace(string, r"\{.*?\}", func(strings):
		var exp: String = strings[0]
		return _get_expression_rich(exp, unwrap(exp, "{}")))
	
	return string

func _get_expression_rich(exp: String, exp_clean: String) -> String:
	var value = get_expression(exp_clean)
	if _expression_error != OK:
		return "[red]%s[]" % exp
	else:
		if typeof(value) == TYPE_INT and context_rich_ints:
			return commas(value)
		elif typeof(value) == TYPE_OBJECT and context_rich_objects and value.has_method(&"to_rich_string"):
			return value.to_rich_string()
		elif typeof(value) == TYPE_ARRAY and context_rich_array:
			var nice_array := []
			for item in value:
				match typeof(item):
					TYPE_OBJECT:
						if item.has_method(&"to_rich_string"):
							nice_array.append(item.to_rich_string())
						elif "name" in item:
							nice_array.append(item.name)
						else:
							nice_array.append(str(item))
					_: nice_array.append(str(item))
			value = ", ".join(nice_array)
		return str(value)

func replace_numbers(string: String) -> String:
	return _replace(string, r"\b\d{1,3}(?:,\d{3})*(?:\.\d+)?\b", func(strings):
		var numstr: String = strings[0]
		if autostyle_numbers_pad_decimals and "." in numstr:
			numstr = numstr.pad_decimals(autostyle_numbers_decimals)
		return autostyle_numbers_tag % numstr)

func _parse(btext: String):
	var regex := RegEx.create_from_string(r"\[\[.*?\]|\[.*?\]")
	var offset := 0
	var output := ""
	while true:
		var m := regex.search(btext, offset)
		if not m:
			break
		_add_text(btext.substr(offset, m.get_start()-offset))
		var tags := m.get_string()
		if tags.begins_with("[["):
			_add_text(tags.trim_prefix("["))
		else:
			_parse_tags(unwrap(tags, "[]"))
		offset = m.get_end()
	_add_text(btext.substr(offset))
	return output

func _parse_tags(tags_string: String):
	var p := tags_string.split(";")
	var tags := []
	for i in len(p):
		var tag = p[i]
		tags.append(tag)
	
	var added_stack := false
	for tag in tags:
		# Empty = close tags.
		if tag == "":
			if added_stack and len(_stack) and not len(_stack[-1]):
				_stack.pop_back()
			#if len(_stack) and not len(_stack[-1]):
				#_add_text("[]")
			_stack_pop()
			added_stack = false
		
		# Close everything.
		elif tag == "/":
			if added_stack and len(_stack) and not len(_stack[-1]):
				_stack.pop_back()
			while len(_stack):
				_stack_pop()
			added_stack = false
		
		# Close old fashioned way
		elif tag.begins_with("/"):
			# TODO
			push_error("Old fashioned closing not yet implemented.")
		
		else:
			if not added_stack:
				added_stack = true
				_stack.append([])
			_parse_tag(tag)
	
	if added_stack and len(_stack) and not len(_stack[-1]):
		_stack.pop_back()

func get_expression(ex: String, state2 := {}) -> Variant:
	if not is_inside_tree():
		if not Engine.is_editor_hint():
			push_error("Can't get_expression when outside tree.")
		return null
	
	var node := get_node(context_path)
	
	# If a pipe is present.
	if "|" in ex:
		# Get all pipes.
		var pipes := ex.split("|")
		var ex_prepipe := pipes[0]
		# Get initial value of expression.
		var got: Variant = get_expression(ex_prepipe)
		for i in range(1, len(pipes)):
			var pipe_parts := pipes[i].split(" ")
			# First arg is pipe method name.
			var pipe_meth := pipe_parts[0]
			# Rest are arguments. Convert to an array.
			# Does method exist in context node?
			if node and node.has_method(pipe_meth):
				var arg_str := "[%s]" % [", ".join(pipe_parts.slice(1))]
				var pipe_args: Array = [got] + get_expression(arg_str)
				got = node.callv(pipe_meth, pipe_args)
			else:
				var s2 := { "_GOT_": got }
				var arg_str := []
				for j in len(pipe_parts)-1:
					var key := "_ARG%s_" % j
					s2[key] = get_expression(pipe_parts[j+1])
					arg_str.append(key)
				var p_exp := "_GOT_.%s(%s)" % [pipe_meth, ", ".join(arg_str)]
				got = get_expression(p_exp, s2)
		return got
	
	_expression_error = OK
	var e := Expression.new()
	var returned: Variant = null
	var con_args := context_state.keys() if context_state else []
	var con_vals := context_state.values() if context_state else []
	if state2:
		con_args = con_args + state2.keys()
		con_vals = con_vals + state2.values()
		
	_expression_error = e.parse(ex, con_args)
	if _expression_error == OK:
		returned = e.execute(con_vals, node, false)
	
	if e.has_execute_failed():
		_expression_error = FAILED
		push_error(e.get_error_text())
		return null
	
	return returned

func _parse_tag(tag: String):
	# COLOR. This allows doing: "[%s]Text[]" % Color.RED
	if is_wrapped(tag, "()"):
		var rgba = unwrap(tag, "()").split_floats(",")
		_push_color(Color(rgba[0], rgba[1], rgba[2], rgba[3]))
		return
	
	# Pipe. TODO
	if tag.begins_with("|"):
		_push_pipe(tag.substr(1))
		return
	
	var tag_name: String
	var tag_info: String
	
	var a = tag.find("=")
	var b = tag.find(" ")
	# [tag=value]
	if a != -1 and (b == -1 or a < b):
		tag_name = tag.substr(0, a)
		tag_info = tag
	# [tag key=val]
	elif b != -1 and (a == -1 or b < a):
		tag_name = tag.substr(0, b)
		tag_info = tag.substr(b).strip_edges()
	# [tag]
	else:
		tag_name = tag
		tag_info = ""
	
	_parse_tag_info(tag_name, tag_info, tag)

func _passes_condition(cond: String, raw: String) -> bool:
	match cond:
		"if":
			var test := raw.split(" ", true, 1)[1]
			_state.condition = true if get_expression(test) else false
			_stack_push(T_CONDITION)
			
		"elif":
			if "condition" in _state and _state.condition == false:
				var test := raw.split(" ", true, 1)[1]
				_state.condition = true if get_expression(test) else false
		
		"else":
			if "condition" in _state:
				_state.condition = not _state.condition
		
		_:
			if not "condition" in _state or _state.condition == true:
				return true
	
	return false

func _has_font(id: StringName) -> bool:
	return id in font_cache

func _get_font(id: StringName) -> Font:
	if font_cache[id] is String:
		font_cache[id] = load(font_cache[id])
	return font_cache[id]

func _has_emoji_font() -> bool:
	return "emoji_font" in font_cache

func _get_emoji_font() -> Font:
	return _get_font(&"emoji_font")

func _parse_tag_info(tag: String, info: String, raw: String):
	if not _passes_condition(tag, raw):
		return
	
	# font sizes
	if len(tag) and tag[0].is_valid_int():
		_push_font_size(int(_state.font_size * _number(tag)))
		return
	
	# emoji: old style
	if tag in Emoji.OLDIE:
		var efont := _get_emoji_font()
		if efont != null:
			push_font(efont)
			push_font_size(ceil(_state.font_size * emoji_scale))
			add_text(Emoji.OLDIE[tag])
			pop()
			pop()
		else:
			append_text(Emoji.OLDIE[tag])
		return
	
	# emoji: by name
	if tag.begins_with(":") and tag.ends_with(":"):
		var emoji_name := tag.trim_suffix(":").trim_prefix(":")
		if emoji_name in Emoji.NAMES:
			var efont := _get_emoji_font()
			if efont != null:
				push_font(efont, ceil(_state.font_size * emoji_scale))
				add_text(Emoji.NAMES[emoji_name])
				pop()
			else:
				append_text(Emoji.NAMES[emoji_name])
			return
	
	# is a custom font?
	if _has_font(tag):
		_push_font(tag)
		return
	
	match tag:
		"b": _push_bold()
		"i": _push_italics()
		"bi": _push_bold_italics()
		"s": _push_strikethrough()
		"u": _push_underline()
		
		"bg": _push_color_bg(to_color(info))
		"fg": _push_color_fg(to_color(info))
		
		"left": _push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		"right": _push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
		"center": _push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		"fill": _push_paragraph(HORIZONTAL_ALIGNMENT_FILL)
		
		"dim": _push_color(_state.color.darkened(.33))
		"dima": _push_color(Color(_state.color.darkened(.33), .5))
		"lit": _push_color(_state.color.lightened(.33))
		"lita": _push_color(Color(_state.color.lightened(.33), .5))
		"hide": _push_color(Color.TRANSPARENT)
		
		# Shift the hue. default to 50%.
		"hue": _push_color(hue_shift(_state.color, _number(info) if info else 0.5))
		
		"meta": _push_meta(info)
		"hint": _push_hint(info)
		
		_:
			if not _has_effect(tag):
				pass
			
			# Custom effect.
			if _has_effect(tag):
				_push_effect(tag, info)
			
			elif not _parse_tag_unused(tag, info, raw):
				append_text("[%s]" % raw)

static func _number(s: String) -> float:
	if s.is_valid_int():
		return s.to_int() / 100.0
	elif s.is_valid_float():
		return s.to_float()
	else:
		push_warning("Couldn't convert '%s' to number." % [s])
		return 1.0

func _parse_tag_unused(tag: String, _info: String, _raw: String) -> bool:
	# check if it's a color.
	var clr := Color.from_string(tag, Color.PAPAYA_WHIP)
	if clr != Color.PAPAYA_WHIP:
		_push_color(clr)
		return true
	return false

func _add_text(t: String):
	if _state.pipes:
		var exp := "|".join([var_to_str(t)] + _state.pipes)
		var got = get_expression(exp)
		t = str(got)
		append_text(t)
		return
		
	add_text(t)

func _push_meta(data: Variant):
	if "^" in data:
		var p = data.split("^", true, 1)
		push_meta(p[0].strip_edges())
		push_hint(p[1].strip_edges())
		_stack_push(T_META)
		_stack_push(T_HINT)
	else:
		push_meta(data.strip_edges())
		_stack_push(T_META)

func _push_hint(data: Variant):
	_stack_push(T_HINT)
	push_hint(data)

func _push_bold():
	_stack_push(T_BOLD)
	push_bold()
	
func _push_italics():
	_stack_push(T_ITALICS)
	push_italics()

func _push_bold_italics():
	_stack_push(T_BOLD_ITALICS)
	push_bold_italics()

func _push_strikethrough():
	_stack_push(T_STRIKE_THROUGH)
	push_strikethrough()

func _push_underline():
	_stack_push(T_UNDERLINE)
	push_underline()

func _push_paragraph(align :int):
	_stack_push(T_PARAGRAPH, _state.align)
	_state.align = align
	push_paragraph(align)

func _pop_paragraph(data):
	_state.align = data
	pop()

func _push_effect(effect: String, info: String):
	if effects == EffectsMode.OFF:
		return
	
	if effects == EffectsMode.OFF_IN_EDITOR and Engine.is_editor_hint():
		return
	
	_install_effect(effect)
	_stack_push(T_EFFECT, effect)
	var effect_text := ("[%s]" % effect) if info == "" else ("[%s %s]" % [effect, info])
	append_text(effect_text)

func _push_pipe(pipe: String):
	_stack_push(T_PIPE)
	_state.pipes.append(pipe)

func _pop_pipe():
	_state.pipes.pop_back()

func _push_font(font: String):
	_stack_push(T_FONT, _state.font)
	_state.font = font
	push_font(_get_font(font))

func _pop_font(last_font):
	_state.font = last_font
	pop()

func _push_font_size(s: int):
	s = clampi(s, MIN_FONT_SIZE, MAX_FONT_SIZE)
	_stack_push(T_FONT_SIZE, _state.font_size)
	_state.font_size = s
	push_font_size(s)

func _pop_font_size(last_size):
	_state.font_size = last_size
	pop()

func _push_color_bg(clr: Color):
	_stack_push(T_COLOR_BG, _state.color_bg)
	_state.color = clr
	push_bgcolor(clr)

func _push_color_fg(clr: Color):
	_stack_push(T_COLOR_FG, _state.color_fg)
	_state.color = clr
	push_bgcolor(clr)

func _push_color(clr: Color):
	_stack_push(T_COLOR, _state.color)
	_state.color = clr
	push_color(clr)
	
	# Outline color.
	var outline_color := _get_outline_color(clr)
	push_outline_color(outline_color)
	
	# Outline size.
	if outline_size > 0:
		push_outline_size(outline_size)

func _get_outline_color(clr: Color) -> Color:
	var out := clr
	match outline_mode:
		OutlineStyle.DARKEN: out = clr.darkened(outline_adjust)
		OutlineStyle.LIGHTEN: out = clr.lightened(outline_adjust)
	return hue_shift(out, outline_hue_adjust)

func _pop_color(data):
	_state.color = data
	pop()
	if outline_mode != OutlineStyle.OFF:
		pop()
	if outline_size > 0:
		pop()

func _pop_color_bg(data):
	_state.color_bg = data
	pop()

func _pop_color_fg(data):
	_state.color_fg = data
	pop()

# remove the last tag or set of tags.
func _stack_pop():
	if len(_stack):
		var last = _stack.pop_back()
		for i in range(len(last)-1, -1, -1):
			var type = last[i][0]
			var data = last[i][1]
			var nopop = last[i][2]
			match type:
				T_COLOR: _pop_color(data)
				T_COLOR_BG: _pop_color_bg(data)
				T_COLOR_FG: _pop_color_fg(data)
				T_PARAGRAPH: _pop_paragraph(data)
				T_PIPE: _pop_pipe()
				T_FONT: _pop_font(data)
				T_FONT_SIZE: _pop_font_size(data)
				T_CONDITION: _state.erase("condition")
				T_NONE, _:
					if not nopop:
						pop()
			_tag_closed(type, data)

# called when a tag is closed
func _tag_closed(_tag: int, _data: Variant):
	pass

# push a single tag to the last set of tags.
func _stack_push(item: int = -1, data: Variant = null, nopop: bool = false):
	if len(_stack):
		_stack[-1].append([item, data, nopop])

func _replace_outside(s: String, head: String, tail: String, fr: Callable) -> String:
	var parts := []
#	var safety := 100
	while true:
#		safety -= 1
#		if safety <= 0:
#			push_error("tripped safey")
#			break
		if head in s:
			var p1 := s.split(head, true, 1)
			if tail in p1[1]:
				var p2 := p1[1].split(tail, true, 1)
				var l := p1[0]
				var m := p2[0]
				var r := p2[1]
				parts.append(str(fr.call(l)))
				parts.append(head + m + tail)
				s = r
			else:
				parts.append(s)
				break
		else:
			break
	
	parts.append(str(fr.call(s)))
	return "".join(parts)

# similar to python style substr: s[1:-1]
func _part(s :String, begin: int=0, end=null) -> String:
	if end == null:
		end = len(s)
	
	elif end < 0:
		end = len(s) - end
	
	return s.substr(begin, end-begin)

static func info_to_dict(info: String) -> Dictionary:
	var out := {}
	if "=" in info:
		var re := RegEx.create_from_string(r'(?:"[^"]*"|\[[^\]]*\]|\([^)]*\)|\S)+')
		for rm in re.search_all(info):
			var kv = rm.get_string().split("=", true, 1)
			out[kv[0]] = _str2var(kv[1])
	return out

# Allows setting .2 without erroring.
static func _str2var(s: String) -> Variant:
	# allow floats starting with a decimal: .5
	if s.begins_with(".") and s.substr(1).is_valid_int():
		return ("0" + s).to_float()
	return str_to_var(s)

#TODO
# [if name == "Paul"]Hey Paul.[elif name != ""]Hey friend.[else]Who are you?[endif]
#func _get_if_chain(s:String) -> Array:
#	var p := s.split("]", true, 1)
#	var elifs := [Array(p)]
#
#	while "[elif " in elifs[-1][-1]:
#		p = elifs[-1][-1].split("[elif ", true, 1)
#		elifs[-1][-1] = p[0]
#		p = p[1].split("]", true, 1)
#		elifs.append(Array(p))
#
#	if "[else]" in elifs[-1][-1]:
#		p = elifs[-1][-1].split("[else]", true, 1)
#		elifs[-1][-1] = p[0]
#		elifs.append(["true", p[1]])
#
#	return elifs

#func _replace_conditions(s: String):
#	for test in _get_if_chain(s):
#		if execute_expression(test[0]):
#			return test[1]
#	return ""

func clear_meta():
	_meta.clear()

func do_clickable(label: String, data: Variant, hint := "", tags := "", is_internal := false) -> String:
	var h = ("_%s" if is_internal else "-%s") % hash(data)
	_meta[h] = data
	if hint:
		if tags:
			return "[meta %s^%s;%s]%s[]" % [h, hint, tags, label]
		else:
			return "[meta %s^%s]%s[]" % [h, hint, label]
	elif tags:
		return "[meta %s;%s]%s[]" % [h, tags, label]
	else:
		return "[meta %s]%s[]" % [h, label]

func _has_effect(id:String) -> bool:
	for e in custom_effects:
		if e.resource_name == id:
			return true
	
	for dir in [DIR_TEXT_EFFECTS, DIR_TEXT_TRANSITIONS]:
		var path = dir.path_join("rte_%s.gd" % id)
		if FileAccess.file_exists(path):
			return true

	return false

func _get_character_random(index: int) -> int:
	if index >= 0 and index < len(_random):
		return _random[index]
	return 0

func _install_effect(id:String) -> bool:
	# Already installed?
	for e in custom_effects:
		if e.resource_name == id:
			return true
	
	for dir in [DIR_TEXT_EFFECTS, DIR_TEXT_TRANSITIONS]:
		var path: String = dir.path_join("rte_%s.gd" % id)
		if FileAccess.file_exists(path):
			var effect: RichTextEffect = load(path).new()
			effect.resource_name = id
			effect.set_meta(&"rt", get_instance_id())
			install_effect(effect)
			return true
	
	return false

static func is_style(s: String, style: String) -> bool:
	return s.begins_with(style) and s.ends_with(style)

static func unwrap_stype(s: String, style: String) -> String:
	return s.trim_prefix(style).trim_suffix(style)

static func is_wrapped(t: String, w: String) -> bool:
	return len(t) >= 2 and t[0] == w[0] and t[-1] == w[1]

static func unwrap(t: String, w: String) -> String:
	return t.trim_prefix(w[0]).trim_suffix(w[-1])

static func to_color(s: String, default: Variant = Color.WHITE) -> Variant:
	# From name?
	var out := Color.WHITE
	var clr := Color.from_string(s, Color.PAPAYA_WHIP)
	if clr != Color.PAPAYA_WHIP:
		return clr
	# From hex?
	if s.is_valid_html_color():
		return Color(s)
	# From floats?
	if "," in s:
		# form (0,0,0,0)
		if is_wrapped(s, "()"):
			s = unwrap(s, "()")
		# floats?
		var floats := s.split_floats(",")
		return Color(floats[0], floats[1], floats[2], 1.0)
#	push_error("Can't convert '%s' to color." % s)
	return default

# @mairod https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786
# converted to godot by teebar. no credit needed.
const kRGBToYPrime = Vector3(0.299, 0.587, 0.114)
const kRGBToI = Vector3(0.596, -0.275, -0.321)
const kRGBToQ = Vector3(0.212, -0.523, 0.311)
const kYIQToR = Vector3(1.0, 0.956, 0.621)
const kYIQToG = Vector3(1.0, -0.272, -0.647)
const kYIQToB = Vector3(1.0, -1.107, 1.704)
static func hue_shift(color: Color, adjust: float) -> Color:
	var colorv = Vector3(color.r, color.g, color.b)
	var YPrime = colorv.dot(kRGBToYPrime)
	var I = colorv.dot(kRGBToI)
	var Q = colorv.dot(kRGBToQ)
	var hue = atan2(Q, I)
	var chroma = sqrt(I * I + Q * Q)
	hue += adjust * TAU
	Q = chroma * sin(hue)
	I = chroma * cos(hue)
	var yIQ = Vector3(YPrime, I, Q)
	return Color(yIQ.dot(kYIQToR), yIQ.dot(kYIQToG), yIQ.dot(kYIQToB), color.a)

#static func colorize_path(path: String, color: Color = Color.DEEP_SKY_BLUE) -> String:
#	var out := "[%s]" % color
#	if "//" in path:
#		var head_tail := path.split("//", true, 1)
#		out += head_tail[0]
#		out += head_tail[1]
#
#	var tail_parts := head_tail[1].split("/")
#	return out + "[]"

# 1234567 => 1,234,567
static func commas(number: Variant) -> String:
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
