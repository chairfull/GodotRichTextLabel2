@tool
class_name RTxtAnimator extends RTxtModifier
#TODO: When not animating, remove the Effect, so it's less cpu intensive.
#TODO: Fade out previous lines. This will allow for cool things with Scatterer.

signal started() ## Caused once animation begins.
signal paused() ## When paused by <hold> or <wait>.
signal continued() ## User advanced or timer finished.
signal finished() ## Animation finished, and indicator should probably be shown.
signal progressed(p: float) ## Better than using progress float, as this is smoothly updated by the tween.
signal indicator_enabled() ## Fires when paused, finished, or waiting started.
signal indicator_disabled() ## Fires when started, continued, or waiting ended.
signal timer_started() ## Timer until advance.
signal timer_progressed(p: float) ## 1.0 -> 0.0: Time until auto-advance.
signal timer_finished() ## Timer finished.

## Unit of characters to animate at a time.
## Look at `delay`.
enum Unit {
	CHAR,	## Each character fades one by one.
	WORD,	## All characters in a word fade together.
	LINE	## All characters in a line fade together.
}

## Where the indicator will align itself.
enum IndicatorAlignment {
	CharTop,	## Top of last character.
	CharCenter,	## Center of last character.
	CharBottom,	## Bottom of last character.
	LineBottom,	## Bottom of last visible line.
	LineRight,	## x=Right edge of bounding box, y=last visible line.
}

enum NewLineStyle {
	None,
	WaitForUser,		## Wait for user to press advance.
	WaitForUserJoin,	## Wait for user, and join lines.
	WaitForTime,		## Wait for timer to advance.
	WaitForTimeJoin	## Wait for timer, and join lines.
}

var unit := Unit.WORD: set=set_unit
var duration := 1.0  ## How long before a unit is faded in.
var delay := 0.2 ## Delay between units fading it.
var trans := Tween.TRANS_LINEAR ## Transition to use for fade.
var ease := Tween.EASE_IN_OUT	## Ease to use for fade.
#var uninstall_effect_after_fade := true
var progress := 1.0: set=set_progress
var animation := &"fader" ## Animation to fade with.
@export var new_line_style := NewLineStyle.WaitForUser
@export_group("Continue Arrow", "arrow_")
@export_node_path("CanvasItem") var arrow_node_path: NodePath ## Node that will be moved to the end of the characters.
@export var arrow_offset := Vector2.ZERO ## Ideally it's better to use a node child, but this is for convenience.
@export var arrow_alignment := IndicatorAlignment.CharCenter
@export var arrow_show_on_finished := true ## Show the indicator even after animation is finished.

## TODO:
## Hides lines when a new one started animating.
## Useful for the scatter and ticker effect.
@export var hide_previous_lines := false

var _total_chars := 0
var _total_words := 0
var _total_lines := 0
var _tool_button_advance := advance
var _tool_button_reset = reset
var _waypoints: Dictionary[int, String]
var _alphas: PackedFloat32Array
var _chars: PackedInt32Array
var _words: PackedInt32Array
var _lines: PackedInt32Array
var _transforms: Array[Transform2D]
var _char_size: Array[Vector2] ## Returns the character width. Used for CTC.
var _tween: Tween
var _waiting_for_time := false
var _waiting_for_user := false
var _tween_timer: Tween

func set_unit(u: Unit):
	unit = u
	
	var stripped := label.get_parsed_text()
	var units := [""]
	var last_unit := 0
	var ulist := _chars
	if u == Unit.WORD: ulist = _words
	if u == Unit.LINE: ulist = _lines
	for i in stripped.length():
		if ulist[i] == last_unit:
			units[-1] += stripped[i]
		else:
			units.append(stripped[i])
		last_unit = ulist[i]

func set_progress(p: float):
	var last_progress := progress
	progress = clampf(p, 0.0, 1.0)
	
	if not label:
		return
	
	var last_u := floori(last_progress * _total_chars)
	var u := floori(progress * _total_chars)
	
	if last_u > u:
		if _tween: _tween.kill()
		
		for i in _alphas.size():
			set("alphas_%s" % i, 0.0)
	else:
		if last_progress == 0:
			started.emit()
		else:
			continued.emit()
		indicator_disabled.emit()
		
		progressed.emit(progress)
		
		var ulist: PackedInt32Array = _chars
		match unit:
			Unit.CHAR: ulist = _chars
			Unit.WORD: ulist = _words
			Unit.LINE: ulist = _lines
		var last_visible := -1
		if _tween: _tween.kill()
		_tween = label.create_tween()
		_tween.set_parallel()
		var last_unit_index := 0
		var unit_delay := 0.0
		var max_duration := 0.0
		for i in _alphas.size():
			var unit_index := ulist[i]
			var char_index := _chars[i]
			var was_visible: bool = char_index <= last_u
			var visible: bool = char_index <= u
			if visible:
				last_visible = i
			if visible and not was_visible:
				if unit_index != last_unit_index:
					unit_delay += delay
			_tween.tween_property(self, "alphas_%s" % i, 1.0 if visible else 0.0, duration)\
				.set_delay(unit_delay)\
				.set_trans(trans)\
				.set_ease(ease)
			max_duration = maxf(max_duration, duration + unit_delay)
			last_unit_index = unit_index
		_tween.tween_method(progressed.emit, last_progress, progress, max_duration)
		
		# HACK: TODO: Why do i need to do this?
		if progress == 1.0:
			last_visible = _total_chars
		
		_tween.chain().tween_callback(_update_indicator.bind(last_visible))
		
		if last_visible in _waypoints:
			for waypoint in _waypoints[last_visible].split(";"):
				match waypoint:
					"user": pass
					"time":
						_tween.chain().tween_callback(timer_started.emit)
						_tween.chain().tween_callback(set.bind("_waiting_for_time", true))
						_tween.chain().tween_method(timer_progressed.emit, 1.0, 0.0, 1.0)
						_tween.chain().tween_callback(advance)
						_tween.chain().tween_callback(set.bind("_waiting_for_time", false))
						_tween.tween_callback(timer_finished.emit)
		
		_tween.chain().tween_callback(_advance_finished)

func _update_indicator(last_visible: int):
	
	# Move indicator into position.
	var arrow_node := label.get_node_or_null(arrow_node_path)
	if arrow_node:
		if last_visible != -1:
			arrow_node.position = Vector2.ZERO
			
			match arrow_alignment:
				IndicatorAlignment.CharTop:
					var trans := _transforms[last_visible]
					arrow_node.position = trans.origin
					arrow_node.position.y -= label.font_size
				IndicatorAlignment.CharCenter:
					var trans := _transforms[last_visible]
					arrow_node.position = trans.origin
					arrow_node.position.y -= label.font_size * .5
				IndicatorAlignment.CharBottom:
					var trans := _transforms[last_visible]
					arrow_node.position = trans.origin
				IndicatorAlignment.LineBottom:
					var trans := _transforms[last_visible]
					arrow_node.position = trans.origin
					arrow_node.position.x = label.size.x * .5
				IndicatorAlignment.LineRight:
					var trans := _transforms[last_visible]
					arrow_node.position = trans.origin
					arrow_node.position.x = label.size.x
					arrow_node.position.y -= label.font_size * .5
			arrow_node.position += arrow_offset
	
func _advance_finished():
	# Fire signals.
	if progress == 1.0:
		finished.emit()
		if arrow_show_on_finished:
			indicator_enabled.emit()
	else:
		paused.emit()
		indicator_enabled.emit()

func reset():
	progress = 0.0

func advance_to_char(char_index: int):
	progress = float(char_index) / float(_total_chars)

func get_anim_char() -> int:
	return floori(progress * float(_total_chars))

func advance():
	var current := get_anim_char()
	var next := -1
	for i in range(current+1, _total_chars):
		if i in _waypoints:
			next = i
			break
	advance_to_char(next if next != -1 else _total_chars)

func is_finished() -> bool:
	return progress == 1.0

func _preparse(bbcode: String) -> String:
	if not Engine.is_editor_hint():
		indicator_disabled.emit()
		progress = 0.0
	match new_line_style:
		NewLineStyle.WaitForUser: bbcode = "<user>\n".join(bbcode.split("\n"))
		NewLineStyle.WaitForUserJoin: bbcode = "<user> ".join(bbcode.split("\n"))
		NewLineStyle.WaitForTime: bbcode = "<time>\n".join(bbcode.split("\n"))
		NewLineStyle.WaitForTimeJoin: bbcode = "<time> ".join(bbcode.split("\n"))
	return super("[%s id=%s]%s]" % [animation, get_instance_id(), bbcode])
	
func _finished():
	_waypoints = {}
	if label.parser:
		var stripped := label.get_parsed_text()
		_waypoints.merge(label.parser._waypoints)
		_total_chars = stripped.length()
		_total_words = 0
		_total_lines = 0
		_transforms.resize(_total_chars+1) # Not sure why I have to +1
		_char_size.resize(_total_chars+1)
		_alphas.resize(_total_chars)
		_chars.resize(_total_chars)
		_words.resize(_total_chars)
		_lines.resize(_total_chars)
		var spaced := false
		for i in _total_chars:
			var c := stripped[i]
			if c == " ":
				spaced = true
			elif c == "\n":
				_total_lines += 1
				spaced = true
			else:
				if spaced:
					_total_words += 1
					spaced = false
			_chars[i] = i
			_words[i] = _total_words
			_lines[i] = _total_lines
		
		var words := {}
		for i in _chars.size():
			var w := _words[i]
			var c := stripped[i]
			words[w] = words.get(w, "") + c

#region Internal
func _property_can_revert(property: StringName) -> bool:
	return RTxtAnimator.new().get(property) != null

func _property_get_revert(property: StringName) -> Variant:
	return RTxtAnimator.new().get(property)

func _get_property_list() -> Array[Dictionary]:
	var files := Array(DirAccess.get_files_at("res://addons/richer_text/text_effects/anims"))\
		.filter(func(x: String): return x.begins_with("rte_") and x.ends_with(".gd"))\
		.map(func(x: String): return x.trim_prefix("rte_").trim_suffix(".gd"))
	var list := EditorProperties.new(super())\
		.dict("_waypoints", "int;String")\
		.button(&"_tool_button_advance", "Advance")\
		.button(&"_tool_button_reset", "Reset")\
		.string_enum(&"animation", files)\
		.number_range(&"progress")\
		.integer_enum(&"unit", Unit)\
		.number(&"duration")\
		.number(&"delay")\
		.tween_trans(&"trans")\
		.tween_ease(&"ease")\
		.group("Alphas", "alphas_")\
		.end()
	for i in _alphas.size():
		list.append({ name="alphas_%s" % i, type=TYPE_FLOAT, hint=PROPERTY_HINT_RANGE, hint_string="0.0,1.0" })
	return list

func _get(property: StringName) -> Variant:
	if property.begins_with("alphas_"):
		var index := int(property.trim_prefix("alphas_"))
		return _alphas[index] if index < _alphas.size() else 1.0
	return

func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("alphas_"):
		var index := int(property.trim_prefix("alphas_"))
		if index < _alphas.size():
			_alphas[index] = value
		return true
	return false
#endregion
