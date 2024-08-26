@tool
extends RicherTextLabel
class_name RichTextAnimation

## A symbols [#symbol] tag was triggered at a point in the animation.
signal on_bookmark(symbol: String)
## A single character became visible at a point in the animation.
signal on_character(index: int)
signal on_quote_started(quote: String)
signal on_quote_finished()
signal on_stars_started(star: String)
signal on_stars_finished()

## Animation started.
signal anim_started()
## Hold or Wait started.
signal anim_paused()
## Hold or Wait ended.
signal anim_continued()
signal anim_finished()

signal wait_started()
signal wait_finished()

signal hold_started()
signal hold_finished()

enum {
	TRIG_NONE = 1000, # Offset because it's built on the enum of the RicherTextLabel class.
	TRIG_WAIT,	## [wait] or [w]: Delays animation for a time.
	TRIG_PACE,	## [pace] or [p]: Changes the animation speed.
	TRIG_HOLD,	## [hold] or [h]: Hold until player pressed advance.
	TRIG_SKIP_STARTED,	## [skip] For displaying a chunk of text at once.
	TRIG_SKIP_FINISHED,	## [] End of skip.
	TRIG_EXPRESSION,	## [$expression]
	TRIG_BOOKMARK,		## [#bookmark]
	TRIG_QUOTE_STARTED,	## Quote has started.
	TRIG_QUOTE_FINISHED,## Quote has ended.
	TRIG_STARS_STARTED,		## * started
	TRIG_STARS_FINISHED,	## * ended
}

enum Style {
	LETTER,	## Fade per letter.
	WORD	## Fade per word.
}

## Animation to play.
@export_storage var animation: String = "fader":
	set(a):
		animation = a
		_redraw()

## True when animation is playing.
## False when a [hold] is called.
@export_storage var _play := true
## Is hold waiting?
@export_storage var _hold := false
## Automatically play when bbcode is set.
## Otherwise you need to call advance().
@export var play_on_bbcode := true
## Default speed of the animation.
@export var play_speed := 30.0
## Enabled when transitioning out.
## Triggers will be disabled.
@export var fade_out := false
## How quickly characters fade in.
## Longer is whispier. Slower is sharper.
@export var fade_in_speed := 10.0
## How quickly characters fade out when fade_out = true.
## This should be very fast so the user isn't bored.
@export var fade_out_speed := 120.0
## Current state of animation. Manually tweaking is meant for in editor, otherwise you should be calling advance().
@export_range(0.0, 1.0) var progress := 0.0: set=set_progress
## Current character that is fully visible.
@export_storage var visible_character := -1
## Used internally by animation effects.
var effect_time := 0.0

## How long to wait before automatically playing again.
@export_storage var _wait := 0.0
@export_storage var _wait_max := 0.0
## How long to wait when [w] is called.
@export var default_wait_time := 1.0
## How fast to display characters. Multiplied by play_speed.
@export_storage var _pace := 1.0
@export_storage var _skip := false
## Events that will go off once a character is reached.
## See the TRIG_ enums above.
@export_storage var _triggers := {}
## Animations will send back their transform state, which may be useful for effects.
@export_storage var _transforms: Array[Transform2D]
## Returns the character width. Used for CTC.
@export_storage var _char_size: Array[Vector2]
## Current alpha value of a character.
@export_storage var _alpha: Array[float] = []
## Goal alpha value of a character.
@export_storage var _alpha_goal: Array[float] = []

@export_group("Click2Continue", "ctc_")
## Node displayed at end of text when waiting for user input.
@export var ctc_node: CanvasItem
## By default, ctc_node will be positioned at end of final character, half way up.
@export var ctc_offset := Vector2(1.0, -0.5):
	set(p):
		ctc_offset = p
		_update_ctc_position()
## Show the ctc when finished?
@export var ctc_on_finished := false
## Show the ctc when waiting?
@export var ctc_on_wait := false
@export_storage var _showing_ctc := false
var ctc_tween: Tween

@export_group("Shortcuts", "shortcut_")
## Allow using <expression> pattern instead of just [$expression].
@export var shortcut_expression := true
## Allow using #bookmark pattern instead of just [#bookmark].
@export var shortcut_bookmark := true

@export_group("Signal", "signal_")
## Will signal when "quotes" have started and finished.
## Useful for triggering sounds or animations.
@export var signal_quotes := true
## Will signal when *stars* have started and finished.
## Usefulf for triggering sounds or animations.
@export var signal_stars := true

const FORCED_FINISH_DELAY := 0.1
@export_storage var _forced_finish := false
@export_storage var _forced_finish_delay := FORCED_FINISH_DELAY

func _set_bbcode():
	_triggers.clear()
	_skip = false
	_wait = 0.0
	_wait_max = 0.0
	_pace = 1.0
	_forced_finish = false
	progress = 0.0
	effect_time = 0.0
	visible_character = -1
	_showing_ctc = false
	
	if ctc_node:
		ctc_node.modulate.a = 0.0
	
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
	
	if play_on_bbcode:
		_play = true
	
	_hide_ctc()

## Wait time between 0.0 - 1.0.
func get_wait_delta() -> float:
	return 0.0 if _wait_max == 0.0 else 1.0 - (_wait / _wait_max)

## Animation played all the way through.
func is_finished() -> bool:
	return progress == 0 if fade_out else progress == 1.0

## Waiting for a timer.
func is_waiting() -> bool:
	return _wait > 0.0

## Waiting for user to advance().
func is_holding() -> bool:
	return not _play and not is_finished()

## User should call this to advance the animation if it is paused.
## Returns true if still playing.
func advance() -> bool:
	if is_waiting():
		_wait = 0.0
		_wait_max = 0.0
		wait_finished.emit()
		if _hold:
			_hold = false
			hold_finished.emit()
		_continued()
		return true
	elif is_holding():
		_play = true
		_hold = false
		hold_finished.emit()
		_continued()
		return true
	else:
		# Check if there are more triggers ahead.
		for i in range(visible_character+1, get_total_character_count()):
			if i in _triggers:
				for trig in _triggers[i]:
					# Check if there is a trigger that will pause.
					if trig[0] in [TRIG_WAIT, TRIG_HOLD]:
						# Fast forward to next trigger.
						_jumpto(i)
						return true
	
	# Otherwise we will force finished.
	if not is_finished():
		_forced_finish = true
		_forced_finish_delay = FORCED_FINISH_DELAY
		finish()
		return true
	
	if _forced_finish_delay > 0.0:
		return true
	
	return false

func _jumpto(to: int):
	progress = float(to) / float(len(_alpha))

func _paused():
	anim_paused.emit()

func _continued():
	_wait = 0.0
	_wait_max = 0.0
	_play = true
	_hide_ctc()
	anim_continued.emit()

func _show_ctc():
	if ctc_node and not _showing_ctc:
		_showing_ctc = true
		if ctc_tween:
			ctc_tween.kill()
		ctc_tween = ctc_node.create_tween()
		ctc_tween.tween_property(ctc_node, "modulate:a", 1.0, 0.25)

func _hide_ctc():
	if ctc_node and _showing_ctc:
		_showing_ctc = false
		if ctc_tween:
			ctc_tween.kill()
		ctc_tween = ctc_node.create_tween()
		ctc_tween.tween_property(ctc_node, "modulate:a", 0.0, 0.01)

func finish():
	set_progress(1.0)
	_triggers.clear()
	_wait = 0.0
	_wait_max = 0.0
	_alpha.fill(1.0)

func _preparse(btext: String) -> String:
	if signal_quotes:
		btext = _replace(btext, r'"([^"]*)"', func(strings):
			var a = strings[0]
			return "\"[quote %s]%s[]\"" % [a, unwrap(a, '""')])
	
	if signal_stars:
		btext = _replace(btext, r'\*([^*]+)\*', func(strings):
			var a = strings[0]
			return "[stars %s]*%s*[]" % [unwrap(a, "**"), unwrap(a, "**")])
	
	# Converts <code pattern> into [$code pattern].
	if shortcut_expression:
		btext = _replace(btext, r"<([^>]+)>", func(strings):
			var a = strings[0]
			if a.begins_with("<<"):
				return a.replace("<<", "<")
			return "[$%s]" % unwrap(a, "<>"))
	
	# Converts #bookmark into [#bookmark].
	if shortcut_bookmark:
		btext = _replace(btext, r"(?<!#)(?<!\[)#\w*[^_\W](?!\])", func(strings):
			return "[%s]" % strings[0])
		btext = btext.replace("##", "#")
	
	# Wraps the animation tag.
	btext = "[%s]%s[]" % [animation, super(btext)]
	
	return btext

func _parse_tag_unused(tag: String, info: String, raw: String) -> bool:
	if raw.begins_with("$"):
		return _register_trigger(TRIG_EXPRESSION, raw.trim_prefix("$"))
	# The user may want to fire things off, with their own signal.
	elif raw.begins_with("#"):
		return _register_trigger(TRIG_BOOKMARK, raw.trim_prefix("#"))
	
	match tag:
		"skip":
			_stack_push(TRIG_SKIP_STARTED, null, true)
			return _register_trigger(TRIG_SKIP_STARTED, info_to_dict(info))
		"w", "wait": return _register_trigger(TRIG_WAIT, info_to_dict(info))
		"h", "hold": return _register_trigger(TRIG_HOLD, info_to_dict(info))
		"p", "pace": return _register_trigger(TRIG_PACE, info_to_dict(info))
		"quote":
			_stack_push(TRIG_QUOTE_STARTED, null, true)
			return _register_trigger(TRIG_QUOTE_STARTED, info)
		"stars":
			_stack_push(TRIG_STARS_STARTED, null, true)
			return _register_trigger(TRIG_STARS_STARTED, info)
	
	return super(tag, info, raw)

func _tag_closed(tag: int, data: Variant):
	match tag:
		TRIG_SKIP_STARTED: _register_trigger(TRIG_SKIP_FINISHED)
		TRIG_QUOTE_STARTED: _register_trigger(TRIG_QUOTE_FINISHED)
		TRIG_STARS_STARTED: _register_trigger(TRIG_STARS_FINISHED)

func _trigger(type: int, data: Variant):
	match type:
		TRIG_EXPRESSION:
			var _returned = get_expression(data)
		TRIG_BOOKMARK:
			on_bookmark.emit(data)
		TRIG_WAIT:
			_wait = data.get("wait", data.get("w", default_wait_time))
			_wait_max = _wait
			wait_started.emit()
			_paused()
			if ctc_on_wait:
				_show_ctc()
		TRIG_HOLD:
			_play = false
			_hold = true
			hold_started.emit()
			_paused()
			_show_ctc()
		TRIG_PACE: _pace = data.get("pace", data.get("p", 1.0))
		TRIG_SKIP_STARTED: _skip = true
		TRIG_SKIP_FINISHED: _skip = false
		TRIG_QUOTE_STARTED: on_quote_started.emit(data)
		TRIG_QUOTE_FINISHED: on_quote_finished.emit()
		TRIG_STARS_STARTED: on_stars_started.emit(data)
		TRIG_STARS_FINISHED: on_stars_finished.emit()
		_: push_warning("UNKOWN TRIGGER")

func _register_trigger(type: int, data = null) -> bool:
	var at := get_total_character_count()-1
	var tr = [type, data]
	
	if not at in _triggers:
		_triggers[at] = [tr]
	else:
		_triggers[at].append(tr)
	
	return true

func set_progress(p: float):
	var last_progress := progress
	var last_visible_character := visible_character
	
	var next_progress := clampf(p, 0.0, 1.0)
	var next_visible_character := int(floor(get_total_character_count() * next_progress))
	
	if last_progress == next_progress:
		return
	
	# Going forward? Emit signal and pop triggers.
	if last_visible_character < next_visible_character:
		for i in range(last_visible_character, next_visible_character):
			
			if i in _triggers:
				if not is_waiting():
					for t in _triggers[i]:
						_trigger(t[0], t[1])
				
				# Break at next trigger, unless being forced.
				if is_waiting() and not _forced_finish:
					next_progress = (i+1) / float(len(_alpha))
					next_visible_character = (i+1)
					break
			
			# Breaking on trigger, unless being forced.
			if is_waiting() and not _forced_finish:
				break
	
	progress = next_progress
	visible_character = next_visible_character
	
	# Set alpha goal.
	for i in len(_alpha_goal):
		_alpha_goal[i] = 1.0 if i <= visible_character else 0.0
	
	# Emit signals.
	if last_visible_character < visible_character:
		if visible_character == 0:
			anim_started.emit()
		
		for i in range(last_visible_character, visible_character):
			on_character.emit(i)
		
		if visible_character == get_total_character_count():
			anim_finished.emit()
			_show_ctc()
	
	if fade_out:
		if progress == 0.0:
			finish()
	else:
		if progress == 1.0:
			finish()
	
	_update_ctc_position()

func _update_ctc_position():
	if not ctc_node:
		return
	
	var index  = visible_character
	while index > 0 and index < len(_char_size) and _char_size[index] == Vector2.ZERO:
		index -= 1
	index = clampi(index, 0, len(_char_size)-1)
	
	if _char_size[index] != Vector2.ZERO:
		ctc_node.position = _transforms[index].origin + _char_size[index] * ctc_offset

func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and _play:
		effect_time += delta
	
	if _forced_finish_delay > 0.0:
		_forced_finish_delay -= delta
	
	if len(_alpha) != get_total_character_count():
		return
	
	if fade_out:
		for i in len(_alpha):
			if _alpha[i] > 0.0:
				_alpha[i] = maxf(0.0, _alpha[i] - delta * fade_in_speed)
		
		if progress > 0.0:
			progress -= delta * fade_out_speed
	
	else:
		var fs := delta * fade_in_speed
		
		for i in len(_alpha):
			if _alpha[i] > _alpha_goal[i]:
				_alpha[i] = maxf(_alpha_goal[i], _alpha[i] - fs)
			
			elif _alpha[i] < _alpha_goal[i]:
				_alpha[i] = minf(_alpha_goal[i], _alpha[i] + fs)
		
		if _wait > 0.0:
			_wait -= delta
			if _wait <= 0.0:
				_jumpto(visible_character+1) # TODO: Look into why this is needed now?
				wait_finished.emit()
				_continued()
		
		elif _play and progress < 1.0 and len(_alpha):
			if _skip:
				while _skip:
					progress += 1.0 / float(len(_alpha))
			else:
				var t := 1.0 / float(len(_alpha))
				progress += delta * t * play_speed * _pace

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
