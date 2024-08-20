@tool
extends RichTextLabel2
class_name RichTextAnimation

signal symbol(command: String)	# triggered when a tag starting with either ~!?@%&* comes up.
signal character_shown(index: int)	# a single character was made visible. useful for character animation?

signal started()				# animation starts.
signal paused()					# 'play' is set to false.
signal ended()					# animation ended.
signal faded_in()				# ended fade in
signal faded_out()				# ended fade out

signal hold_started()			# called when waiting for user input
signal hold_ended()				# called when user ended a hold

signal wait_started()			# wait timer started.
signal wait_ended()				# wait timer ended.
signal quote_started()			# "quote" starts.
signal quote_ended()			# "quote" ends.

enum {
	TRIG_NONE = 1000, # offset because it's built on the enum of the RichTextLabel2 class.
	TRIG_WAIT, TRIG_PACE, TRIG_HOLD,
	TRIG_SKIP_STARTED, TRIG_SKIP_ENDED,
	TRIG_ACTION, TRIG_SYMBOL,
	TRIG_QUOTE_STARTED, TRIG_QUOTE_ENDED
}

enum Style { LETTER, WORD }

#@export_enum("","back","console","fader","focus","prickle","redact","wfc")
@export var animation:String = "fader":
	set(a):
		animation = a
		_redraw()

@export var play := true
@export var play_speed := 30.0
@export var fade_out := false
@export var fade_speed := 10.0
@export var fade_out_speed := 120.0

@export_range(0.0, 1.0) var progress := 0.0: set=set_progress
@export_storage var visible_character := -1
var effect_time := 0.0

@export_storage var _wait := 0.0
@export_storage var _pace := 1.0
@export_storage var _skip := false
@export_storage var _triggers := {}
@export_storage var _transforms: Array[Transform2D]
@export_storage var _char_size: Array[Vector2]
@export_storage var _alpha: Array[float] = []
@export_storage var _alpha_goal: Array[float] = []

@export_group("Click2Continue", "ctc_")
## Node displayed at end of text.
@export var ctc_node: CanvasItem
@export var ctc_always_show := false

func is_finished() -> bool:
	return progress == 0 if fade_out else progress == 1.0

func is_waiting() -> bool:
	return _wait > 0.0

func is_playing() -> bool:
	return play

func _set_bbcode():
	_triggers.clear()
	_skip = false
	_wait = 0.0
	_pace = 1.0
	progress = 0.0
	effect_time = 0.0
	visible_character = -1
	
	super()
	
	var l := get_total_character_count()
	_alpha.resize(l)
	_alpha_goal.resize(l)
	_transforms.resize(l)
	_char_size.resize(l)
	_alpha.fill(0.0)
	_alpha_goal.fill(0.0)
	_transforms.fill(Transform2D.IDENTITY)
	_char_size.fill(Vector2.ZERO)

func can_advance() -> bool:
	return not play or not is_finished()

func advance():
	if not play:
		play = true
	else:
		finish()

func finish():
	_triggers.clear()
	_wait = 0.0
	set_progress(1.0)
	_alpha.fill(1.0)
	_alpha_goal.fill(1.0)

func _preparse(btext: String) -> String:
	var final := "[%s]%s[]" % [animation, super._preparse(btext)]
	return final

func _parse_tag_unused(tag: String, info: String, raw: String) -> bool:
	# the user may want to fire things off, with their own signal.
	if raw[0] == "!":
		return _register_trigger(TRIG_ACTION, raw.substr(1))
	
	match tag:
		"skip":
			_stack_push(TRIG_SKIP_STARTED, null, true)
			return _register_trigger(TRIG_SKIP_STARTED, info_to_dict(info))
		"w", "wait": return _register_trigger(TRIG_WAIT, info_to_dict(info))
		"h", "hold": return _register_trigger(TRIG_HOLD, info_to_dict(info))
		"p", "pace": return _register_trigger(TRIG_PACE, info_to_dict(info))
		"q", "quote":
			_stack_push(TRIG_QUOTE_STARTED, null, true)
			return _register_trigger(TRIG_QUOTE_STARTED, info_to_dict(info))
	
	return super._parse_tag_unused(tag, info, raw)

func _tag_closed(tag: int, data: Variant):
	match tag:
		TRIG_SKIP_STARTED: _register_trigger(TRIG_SKIP_ENDED)
		TRIG_QUOTE_STARTED: _register_trigger(TRIG_QUOTE_ENDED)

func _trigger(type: int, data: Variant):
	match type:
		TRIG_SYMBOL: symbol.emit(data)
		#TRIG_ACTION: Sooty.actions.do(data)
		TRIG_WAIT: _wait += data.get("wait", data.get("w", 1.0))
		TRIG_HOLD: play = false
		TRIG_PACE: _pace = data.get("pace", data.get("p", 1.0))
		TRIG_QUOTE_STARTED: quote_started.emit()
		TRIG_QUOTE_ENDED: quote_ended.emit()
		TRIG_SKIP_STARTED: _skip = true
		TRIG_SKIP_ENDED: _skip = false
		_: push_warning("UNKOWN TRIGGER")

func _register_trigger(type: int, data = null) -> bool:
	var at := get_total_character_count()-1
	var tr = [type, data]
	
	if not at in _triggers:
		_triggers[at] = [tr]
	else:
		_triggers[at].append(tr)
	
	return true

func set_progress(p:float):
	var last_progress := progress
	var last_visible_character := visible_character
	
	var next_progress := clampf(p, 0.0, 1.0)
	var next_visible_character := int(floor(get_total_character_count() * next_progress))
	
	if ctc_node:
		if last_visible_character < next_visible_character or next_visible_character == 1:
			ctc_node.visible = true
		else:
			ctc_node.visible = false
		
	if last_progress == next_progress:
		return
	
	# Going forward? Emit signal and pop triggers.
	if last_visible_character < next_visible_character:
		for i in range(last_visible_character, next_visible_character):
			
			if i in _triggers:
				for t in _triggers[i]:
					if _wait > 0.0:
						var timer := get_tree().create_timer(_wait)
						timer.timeout.connect(_trigger.bind(t[0], t[1]))
					else:
						_trigger(t[0], t[1])
				
				if is_waiting():
					next_progress = (i+1) / float(len(_alpha))
					next_visible_character = (i+1)
					break
			
			if is_waiting():
				break
	
	progress = next_progress
	visible_character = next_visible_character
	
	# Set alpha goal.
	for i in len(_alpha_goal):
		_alpha_goal[i] = 1.0 if i < visible_character else 0.0
	
	# Emit signals.
	if last_visible_character < visible_character:
		if visible_character == 0:
			started.emit()
		
		for i in range(last_visible_character, visible_character):
			character_shown.emit(i)
			
			if ctc_node and get_parsed_text()[i] != " ":
				ctc_node.position = _transforms[i].origin + Vector2(_char_size[i].x, 0.0)
		
		if visible_character == get_total_character_count():
			ended.emit()
	
	if fade_out:
		if progress == 0.0:
			faded_out.emit()
	else:
		if progress == 1.0:
			faded_in.emit()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and play:
		effect_time += delta
	
	if len(_alpha) != get_total_character_count():
		return
	
	if fade_out:
		for i in len(_alpha):
			if _alpha[i] > 0.0:
				_alpha[i] = maxf(0.0, _alpha[i] - delta * fade_speed)
		
		if progress > 0.0:
			progress -= delta * fade_out_speed
	
	else:
		var fs := delta * fade_speed
		
#		if _advance_finished:
#			fs *= 4.0
		
		for i in len(_alpha):
			if _alpha[i] > _alpha_goal[i]:
				_alpha[i] = maxf(_alpha_goal[i], _alpha[i] - fs)
			
			elif _alpha[i] < _alpha_goal[i]:
				_alpha[i] = minf(_alpha_goal[i], _alpha[i] + fs)
		
		if _wait > 0.0:
			_wait = maxf(0.0, _wait - delta)
		
		elif play and progress < 1.0 and len(_alpha):
			if _skip:
				while _skip:
					progress += 1.0 / float(len(_alpha))
				
#				for i in get_total_character_count():
#					_alpha_real[i] = _alpha_goal[i]
			else:
				var t := 1.0 / float(len(_alpha))
				progress += delta * t * play_speed * _pace
	
	if ctc_node:
		var last_non_space := visible_character-1
		while last_non_space > 0 and get_parsed_text()[last_non_space] == " ":
			last_non_space -= 1
		ctc_node.modulate.a = _alpha[last_non_space]

func _get_character_alpha(index:int) -> float:
	if index < 0 or index >= len(_alpha):
		return 1.0
	return _alpha[index]

func _get_property_list() -> Array[Dictionary]:
	var animations: Array[String]
	for file in DirAccess.get_files_at(DIR_TEXT_TRANSITIONS):
		if file.begins_with("RTE_") and file.ends_with(".gd"):
			animations.append(file.get_basename().trim_prefix("RTE_"))
	return [{name="animation", type=TYPE_STRING, hint=PROPERTY_HINT_ENUM, hint_string=",".join(animations)}]
