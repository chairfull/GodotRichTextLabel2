@tool
class_name RicherTextLabel extends RichTextLabel

signal link_hovered(content: Variant)
signal link_unhovered(content: Variant)
signal link_clicked(content: Variant)
signal link_right_clicked(content: Variant)

class TooltipObject extends RefCounted:
	var id: String
	var tooltip_text: String
	func _to_string() -> String:
		return "Tooltip:%s(%s)" % [id, tooltip_text]

@export var parser: RTxtParser = RTxtParser.get_default(): set=set_parser
@export var bbcode_head: String: set=set_bbcode_head ## Will always prefix the bbcode.
@export_custom(PROPERTY_HINT_EXPRESSION, "") var bbcode: String: set=set_bbcode
var _image_keys: PackedInt32Array ## Allow us to change image color & alpha with effects.

## Scaled to the parser size.
@export var font_scale := 1.0:
	set(f):
		font_scale = f
		_changed_font_size()

## Scaled against effects like [sin] and [bounce].
@export_range(0.0, 1.0) var effect_weight := 1.0

@export var modifiers: Array[RTxtModifier]:
	set(m):
		modifiers = m
		for mod in modifiers:
			if mod:
				mod.label = self
				if not mod.changed.is_connected(refresh):
					mod.changed.connect(refresh)
		refresh()

@export var shadow: RTxtShadow:
	set(s):
		shadow = s
		if s: s.changed.connect(_changed_shadow)
		_changed_shadow()

var font: Font:
	get: return load(parser.font_default) if parser else ThemeDB.fallback_font

var font_size: float:
	get: return (parser.font_size if parser else ThemeDB.fallback_font_size) * font_scale

## Populated with [link] tag data.
@export var link_content: Dictionary[int, String]
var _link_regions: Dictionary[int, PackedInt32Array] ## Used internally for mouse over detection. Populated by RTxtLinkEffect.
var _link_rects: Dictionary[int, PackedVector2Array] ## Used internally for mouse over detection.
var hovered_link: int = -1:
	set(h):
		if h == hovered_link:
			return
		if hovered_link != -1:
			_link_unhovered(hovered_link)
			_set_cursor(Input.CURSOR_ARROW)
		hovered_link = h
		if hovered_link != -1:
			_link_hovered(hovered_link)
			if can_click(hovered_link):
				_set_cursor(parser.link_cursor if parser else Input.CURSOR_POINTING_HAND)
			else:
				_set_cursor(parser.link_tooltip_cursor if parser else Input.CURSOR_HELP)

func _set_cursor(shape: int):
	Input.set_default_cursor_shape(shape)
	mouse_default_cursor_shape = shape

## Converts a Callable into a clickable tag.
## WARNING: You still have to wrap it: "[%s]Test]" % to_link(my_func)
static func to_link(call: Callable) -> String:
	var id := call.get_object_id()
	var meth := call.get_method()
	var args := "&".join(call.get_bound_arguments().map(JSON.stringify))
	return "=call:%s:%s:%s" % [id, meth, args]

func set_bbcode_head(head: String):
	bbcode_head = head
	refresh()

func set_bbcode(bb: String):
	if bbcode == bb:
		return
	bbcode = bb
	refresh()

func refresh():
	link_content.clear()
	_link_regions.clear()
	_link_rects.clear()
	_image_keys.clear()
	set_process_input(false)
	
	var bb := bbcode
	
	for mod in modifiers:
		if mod and mod.enabled:
			bb = mod._preparse(bb)
	
	# Attach the head after the modifiers, since they tend to repeat stuff.
	var bb_head := bbcode_head.strip_edges()
	if bb_head:
		if not bb_head.begins_with("["): bb_head = "[" + bb_head
		if not bb_head.ends_with("]"): bb_head = bb_head + "]"
		bb = bb_head + bb
	
	if parser:
		if not is_inside_tree():
			await ready
		bb = parser.parse(bb, self, link_content)
		
		if link_content and parser.link_effect:
			_install_effect(parser.link_effect)
			set_process_input(true)
	
	if false and "[/img]" in bb:
		# HACK: To give images a key so we can update them with RichTextLabel effects.
		clear()
		var re := RegEx.create_from_string(r"(\[img[^\]]*\])(.+?)(\[/img\])")
		var offset := 0
		while offset < bb.length():
			var rm := re.search(bb, offset)
			if rm:
				append_text(bb.substr(offset, rm.get_start() - offset))
				var index := get_parsed_text().length()
				_image_keys.append(index)
				add_image(load(rm.strings[2]), 64, 64, Color.WHITE, INLINE_ALIGNMENT_CENTER, Rect2(), index)
				offset = rm.get_end()
			else:
				append_text(bb.substr(offset))
				offset = bb.length()
	else:
		set_text(bb)

var _debug_commands: Array[Callable]
func add_draw(drawcmd: Callable):
	if not _debug_commands:
		_debug_commands = []
	_debug_commands.append(drawcmd)
	queue_redraw()

func _init() -> void:
	set_process_input(false)
	
	if not parser:
		set_parser(null)
		bbcode_enabled = true
		fit_content = true
		autowrap_mode = TextServer.AUTOWRAP_OFF
		meta_underlined = false
		hint_underlined = false
	
	for mod in modifiers:
		if mod and not mod.changed.is_connected(refresh):
			mod.changed.connect(refresh)
	finished.connect(_finished)

func _exit_tree() -> void:
	# Clear states on the way out, since many nodes can share the effect.
	# TODO: At the moment you can't probably can't have RicherTextLabels with links.
	if link_content and parser.link_effect:
		parser.link_effect._clear()

func _input(event: InputEvent) -> void:
	if not link_content or not parser.link_effect:
		set_process_input(false)
		return
		
	if event is InputEventMouseMotion:
		if parser and parser.link_effect:
			parser.link_effect._check_mouse_over(self, get_local_mouse_position())
	elif event is InputEventMouseButton and event.pressed and hovered_link != -1:
		if can_click(hovered_link):
			if event.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				_link_clicked(hovered_link)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				get_viewport().set_input_as_handled()
				_link_clicked(hovered_link, true)

func _finished():
	for mod in modifiers:
		if mod and mod.enabled:
			mod._finished()

func _draw() -> void:
	for mod in modifiers:
		if mod and mod.enabled:
			mod._debug_draw(self)
	
	while _debug_commands:
		_debug_commands.pop_front().call(self)

## If false this is just a tooltip meta.
func can_click(index: int) -> bool:
	var link := get_link_content(index)
	if link is Callable:
		return true
	elif link is Object and (link.has_method(&"_richtext_clicked") or link.has_method(&"_richtext_right_clicked")):
		return true
	return false

func _link_clicked(index: int, right_clicked := false):
	var link := get_link_content(index)
	var result: Variant = null
	if link is Callable:
		var obj = link.get_object()
		var method = link.get_method()
		if right_clicked and obj.has_method(method + "_right_clicked"):
			result = obj.callv(method + "_right_clicked", link.get_bound_arguments())
		else:
			result = link.call()
	elif link is Object:
		if right_clicked:
			if link.has_method(&"_richtext_right_clicked"):
				result = link._richtext_right_clicked()
		else:
			if link.has_method(&"_richtext_clicked"):
				result = link._richtext_clicked()
	
	if not result:
		return
	
	if parser:
		if parser.link_effect:
			parser.link_effect._link_clicked(index)
		if parser.link_audio_enabled:
			if right_clicked:
				_play_sound(parser.link_audio_path_right_clicked)
			else:
				_play_sound(parser.link_audio_path_clicked)
	
	if right_clicked:
		if result != true:
			link_right_clicked.emit(link)
		RTxtParser.link_right_clicked.emit(self, index)
	else:
		if result != true:
			link_clicked.emit(link)
		RTxtParser.link_clicked.emit(self, index)

func _link_hovered(index: int):
	var link := get_link_content(index)
	var result: Variant
	if link is Object and link.has_method(&"_richtext_hovered"):
		result = link._richtext_hovered()
	elif link is Callable:
		var obj: Object = link.get_object()
		var hov_method: StringName = &"%s_hovered" % link.get_method()
		if obj.has_method(hov_method):
			result = obj.callv(hov_method, link.get_bound_arguments())
	elif link is TooltipObject:
		result = link.tooltip_text
	
	if result is String:
		tooltip_text = result
	elif result != true:
		return
	
	if parser:
		if parser.link_effect:
			parser.link_effect._link_hovered(index)
		if parser.link_audio_enabled:
			if can_click(index):
				_play_sound(parser.link_audio_path_hovered)
			else:
				_play_sound(parser.link_audio_path_tooltip_hovered)
	
	if result != true:
		link_hovered.emit(link)
	RTxtParser.link_hovered.emit(self, index)

func _link_unhovered(index: Variant):
	var link := get_link_content(index)
	var result: Variant
	if link is Object and link.has_method(&"_richtext_unhovered"):
		result = link._richtext_unhovered()
	elif link is Callable:
		var obj: Object = link.get_object()
		var hov_method: StringName = &"%s_unhovered" % link.get_method()
		if obj.has_method(hov_method):
			result = obj.callv(hov_method, link.get_bound_arguments())
	elif link is TooltipObject:
		result = ""
	
	if result is String:
		tooltip_text = result
	elif result != true:
		return
	
	if parser:
		if parser.link_effect:
			parser.link_effect._link_unhovered(index)
		if parser.link_audio_enabled:
			if can_click(index):
				_play_sound(parser.link_audio_path_unhovered)
			else:
				_play_sound(parser.link_audio_path_tooltip_unhovered)
	
	if result != true:
		link_unhovered.emit(link)
	RTxtParser.link_unhovered.emit(self, index)

func get_link_content(index: Variant) -> Variant:
	var link_str: String = link_content.get(int(index), "")
	if link_str.begins_with("id:"):
		return instance_from_id(int(link_str.trim_prefix("id:")))
	elif link_str.begins_with("call:"):
		var parts := link_str.split(":", true, 3)
		var object := instance_from_id(int(parts[1]))
		var method := parts[2]
		var args := [] if not parts[3] else Array(parts[3].split("&"))
		return Callable(object, method).bindv(args)
	elif link_str.begins_with("{"):
		return JSON.parse_string(link_str)
	elif "?" in link_str:
		var parts := link_str.split("?", true, 1)
		var tt := TooltipObject.new()
		tt.id = parts[0]
		tt.tooltip_text = parts[1]
		return tt
	return link_str

func _play_sound(path: String):
	if not path or not FileAccess.file_exists(path):
		return
	var snd := AudioStreamPlayer.new()
	add_child(snd)
	snd.stream = load(path)
	snd.play()
	snd.finished.connect(snd.queue_free)

func get_animation() -> RTxtAnimator:
	return get_modifier(RTxtAnimator)

func get_modifier(script: GDScript) -> RTxtModifier:
	for mod in modifiers:
		if mod.get_script() == script:
			return mod
	return null

func set_parser(p: RTxtParser):
	if p == null:
		p = RTxtParser.get_default()
	var last_parser := parser
	parser = p
	if p and parser != last_parser:
		p.started.connect(_started)
		p.install_effect.connect(_install_effect)
		p.changed_font.connect(_changed_font)
		p.changed_font_size.connect(_changed_font_size)
		p.changed_outline.connect(_changed_outline)
	_changed_font()
	_changed_font_size()
	_changed_shadow()

func _install_effect(effect: RichTextEffect):
	effect.resource_local_to_scene = true
	effect.set_meta(&"rt", get_instance_id())
	install_effect(effect)

func _started():
	uninstall_effects()
	bbcode_enabled = true

func uninstall_effects():
	while custom_effects:
		custom_effects.pop_back()

func _changed_font_size():
	_changed_shadow()
	if parser:
		add_theme_font_size_override(&"normal_font_size", parser.font_size)
		add_theme_font_size_override(&"bold_font_size", parser.font_size)
		add_theme_font_size_override(&"italics_font_size", parser.font_size)
		add_theme_font_size_override(&"bold_italics_font_size", parser.font_size)
	else:
		remove_theme_font_size_override(&"normal_font_size")
		remove_theme_font_size_override(&"bold_font_size")
		remove_theme_font_size_override(&"italics_font_size")
		remove_theme_font_size_override(&"bold_italics_font_size")

func _changed_font():
	if parser:
		var normal_font := ThemeDB.fallback_font
		if parser.font_db:
			if parser.font_default and parser.font_default in parser.font_db:
				normal_font = load(parser.font_db.font_paths[parser.font_default])
		add_theme_font_override(&"normal_font", normal_font)
		
		var bold_font := FontVariation.new()
		bold_font.setup_local_to_scene()
		bold_font.set_base_font(normal_font)
		bold_font.set_variation_embolden(parser.font_bold_weight)
		add_theme_font_override(&"bold_font", bold_font)
		
		var italics_font := FontVariation.new()
		italics_font.set_base_font(normal_font)
		italics_font.set_variation_embolden(parser.font_italics_weight)
		italics_font.set_variation_transform(Transform2D(Vector2(1, parser.font_italics_slant), Vector2(0, 1), Vector2(0, 0)))
		add_theme_font_override(&"italics_font", italics_font)
		
		var bold_italics_font := FontVariation.new()
		bold_italics_font.set_base_font(normal_font)
		bold_italics_font.set_variation_embolden(parser.font_bold_weight)
		bold_italics_font.set_variation_transform(Transform2D(Vector2(1, parser.font_italics_slant), Vector2(0, 1), Vector2(0, 0)))
		add_theme_font_override(&"bold_italics_font", italics_font)
	else:
		remove_theme_font_override(&"normal_font")
		remove_theme_font_override(&"bold_font")
		remove_theme_font_override(&"italics_font")
		remove_theme_font_override(&"bold_italics_font")

func _changed_outline():
	if parser:
		if parser.outline_size > 0 and parser.outline_mode != RTxtParser.OutlineMode.OFF:
			add_theme_constant_override(&"outline_size", parser.outline_size)
		else:
			remove_theme_constant_override(&"outline_size")
		
		if parser.font_color != Color.WHITE:
			add_theme_color_override(&"default_color", parser.font_color)
		else:
			remove_theme_color_override(&"default_color")
		
		match parser.outline_mode:
			RTxtParser.OutlineMode.OFF: remove_theme_color_override(&"font_outline_color")
			RTxtParser.OutlineMode.DARKEN: add_theme_color_override(&"font_outline_color", hue_shift(parser.font_color.darkened(parser.outline_adjust), parser.outline_hue_adjust))
			RTxtParser.OutlineMode.LIGHTEN: add_theme_color_override(&"font_outline_color", hue_shift(parser.font_color.lightened(parser.outline_adjust), parser.outline_hue_adjust))
			RTxtParser.OutlineMode.CUSTOM, RTxtParser.OutlineMode.CUSTOM_DARKEN, RTxtParser.OutlineMode.CUSTOM_LIGHTEN: add_theme_color_override(&"font_outline_color", parser.outline_color)
	else:
		remove_theme_constant_override(&"outline_size")
		remove_theme_color_override(&"font_outline_color")
		remove_theme_color_override(&"default_color")

func _changed_shadow():
	if shadow and shadow.enabled:
		add_theme_color_override(&"font_shadow_color", Color(shadow.color, shadow.alpha))
		add_theme_constant_override(&"shadow_offset_x", floor(cos(shadow.angle) * shadow.distance))
		add_theme_constant_override(&"shadow_offset_y", floor(sin(shadow.angle) * shadow.distance))
		add_theme_constant_override(&"shadow_outline_size", ceil(font_size * shadow.outline_size))
	else:
		remove_theme_color_override(&"font_shadow_color")
		remove_theme_constant_override(&"shadow_offset_x")
		remove_theme_constant_override(&"shadow_offset_y")
		remove_theme_constant_override(&"shadow_outline_size")

func _make_custom_tooltip(for_text: String) -> Object:
	if not for_text.strip_edges():
		return null
	var lbl := RicherTextLabel.new()
	lbl.size = Vector2.ZERO
	lbl.parser = parser
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.bbcode = "[0.6]%s]" % [for_text]
	return lbl

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
