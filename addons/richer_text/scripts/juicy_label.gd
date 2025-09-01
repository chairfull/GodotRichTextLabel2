@tool
class_name JuicyLabel extends Control

enum EffectState { DEFAULT, HOVERED, CLICKED }

@export var font_db: FontDB:
	set(f):
		if f == null and FileAccess.file_exists("res://assets/font_db.tres"):
			f = load("res://assets/font_db.tres")
		font_db = f

@export_storage var font_id: String

@export var font_size: int = 64:
	set(s):
		font_size = s
		queue_redraw()

@export var text := "": set=set_text
@export var color := Color(.17, .78, .45, 1.0)

@export_range(0.0, 1.0, 0.01) var effect_weight := 1.0 ## Scales some effects by this amount.
@export var effect_state := EffectState.DEFAULT: set=set_effect_state
@export_storage var _effect_state := EffectState.DEFAULT ## True effect_state.
@export var default_effect: RTxtEffect:
	set(e):
		if e == null: e = RTE_Mega.new()
		if e: e._juicy = self
		default_effect = e
@export var hovered_effect: RTxtEffect:
	set(e):
		if e == null: e = RTE_Mega.new()
		if e: e._juicy = self
		hovered_effect = e
@export var clicked_effect: RTxtEffect:
	set(e):
		if e == null: e = RTE_Mega.new()
		if e: e._juicy = self
		clicked_effect = e
@export var disable_effects := false ## Disables any effects. Debug.

var _anim := 0.0
var _smoothed_mouse_position := Vector2.ZERO
var _rects: Array[Rect2]
var _tween: Tween
var _tween_amount := 0.0
var font: Font:
	get: return font_db.get_font(font_id) if font_db else ThemeDB.fallback_font

@export var outlines: Array[RTxtOutline]
@export var style := RTxtOutline.Style.OUTLINE
@export var outline_size := 1 ## Only used if style is Outline or OutlineAndText.

var horizontal_alignment := HORIZONTAL_ALIGNMENT_CENTER ## TODO
var vertical_alignment := VERTICAL_ALIGNMENT_CENTER ## TODO.

func set_text(t: String):
	text = t
	
	var total_size := Vector2.ZERO
	var offset := Vector2.ZERO
	var chr_offset := Vector2.ZERO
	_rects.resize(text.length())
	for i in _rects.size():
		var chr := text[i]
		var chr_pos := offset + chr_offset
		var chr_size := font.get_string_size(chr, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		_rects[i] = Rect2(chr_pos, chr_size)
		chr_offset.x += chr_size.x
		total_size.x = maxf(total_size.x, chr_offset.x)
		total_size.y = maxf(total_size.y, chr_size.y)
	
	size = total_size
	custom_minimum_size = total_size
	
	queue_redraw()

func set_effect_state(s: EffectState):
	effect_state = s
	_tween_amount = 0.0
	
	var from := _get_effect(_effect_state)
	var to := _get_effect(effect_state)
	if from and to:
		if _tween: _tween.kill()
		_tween = create_tween()
		_tween.tween_property(self, "_tween_amount", 1.0, to.tween_duration)\
			.set_trans(to.tween_trans)\
			.set_ease(to.tween_ease)
		_tween.tween_callback(func(): _effect_state = effect_state)

func _process(delta: float) -> void:
	_anim += delta
	_smoothed_mouse_position = _smoothed_mouse_position.lerp(get_local_mouse_position(), 10.0 * delta)
	queue_redraw()

func _get_effect(s: EffectState) -> RTxtEffect:
	match s:
		EffectState.DEFAULT: return default_effect
		EffectState.HOVERED: return hovered_effect
		EffectState.CLICKED: return clicked_effect
	return default_effect

func _draw() -> void:
	# Debug boxes.
	#for i in _rects.size():
		#draw_rect(_rects[i], Color(Color.BLACK, 0.5), false, 1, true)
	
	var baseline := Vector2(0.0, font.get_ascent(font_size))
	var diff := (size - custom_minimum_size)
	
	match horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER: baseline.x += diff.x * .5
		HORIZONTAL_ALIGNMENT_RIGHT: baseline.x += diff.x
		HORIZONTAL_ALIGNMENT_FILL: baseline.x += diff.x * .5
	
	match vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER: baseline.y += diff.y * .5
		VERTICAL_ALIGNMENT_BOTTOM: baseline.y += diff.y
		VERTICAL_ALIGNMENT_FILL: baseline.y += diff.y * .5
	
	if disable_effects:
		pass
	
	elif effect_state != _effect_state:
		var a_effect := _get_effect(_effect_state)
		var b_effect := _get_effect(effect_state)
		if a_effect and b_effect:
			a_effect._juicy = self
			b_effect._juicy = self
			
			var cfx := CharFXTransform.new()
			cfx.elapsed_time = _anim
			
			for i in _rects.size():
				var rect := _rects[i]
				
				cfx.relative_index = i
				cfx.range = Vector2(i, 0)
				
				var a_trans: Transform2D 
				var a_color: Color
				cfx.transform = Transform2D(0.0, Vector2.ONE, 0.0, rect.position)
				cfx.color = color
				if a_effect._process_custom_fx(cfx):
					a_trans = cfx.transform
					a_color = cfx.color
				
				var b_trans: Transform2D
				var b_color: Color
				cfx.transform = Transform2D(0.0, Vector2.ONE, 0.0, rect.position)
				cfx.color = color
				if b_effect._process_custom_fx(cfx):
					b_trans = cfx.transform
					b_color = cfx.color
				
				var mix_trans := a_trans.interpolate_with(b_trans, _tween_amount)
				var mix_color := a_color.lerp(b_color, _tween_amount)
				draw_set_transform_matrix(mix_trans)
				draw_string(font, baseline, text[i], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, mix_color)
			return
	else:
		var text_server = TextServerManager.get_primary_interface()
		var effect := _get_effect(effect_state)
		if effect:
			effect._juicy = self
			
			var states: Array[CharFXTransform]
			states.resize(_rects.size())
			
			for i in _rects.size():
				var rect := _rects[i]
				var half_size := rect.size * .5
				var cfx := CharFXTransform.new()
				cfx.font = font.get_rid()
				cfx.elapsed_time = _anim
				cfx.relative_index = i
				cfx.range = Vector2(i, 0)
				cfx.transform = Transform2D(0.0, Vector2.ONE, 0.0, rect.position + half_size)
				cfx.color = color
				cfx.glyph_index = text_server.font_get_glyph_index(font.get_rids()[0], font_size, text[i].unicode_at(0), 0)
				var outline_states := outlines.map(func(o: RTxtOutline):
					return {} if not o else { style=o.style, color=o.color, position=o.position, size=o.size, rotation=o.rotation, skew=o.skew, scale=o.scale })
				cfx.set_meta(&"outlines", outlines)
				cfx.set_meta(&"outline_states", outline_states)
				states[i] = cfx
				
				if effect._process_custom_fx(cfx):
					pass
			
			for o in range(outlines.size()-1, -1, -1):
				if not outlines[o]:
					continue
				for i in _rects.size():
					var cfx := states[i]
					var rect := _rects[i]
					var half_size := rect.size * .5
					var outline: Dictionary = cfx.get_meta(&"outline_states")[o]
					var off: Vector2 = outline.position
					var chr := char(text_server.font_get_char_from_glyph_index(font.get_rids()[0], font_size, cfx.glyph_index))
					draw_set_transform_matrix(cfx.transform * Transform2D(outline.rotation, outline.scale, outline.skew, outline.position))
					if outline.style != RTxtOutline.Style.OUTLINE:
						draw_string(font, baseline - half_size, chr, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline.color)
					if outline.style != RTxtOutline.Style.TEXT:
						draw_string_outline(font, baseline - half_size, chr, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline.size, outline.color)
			
			for i in _rects.size():
				var cfx = states[i]
				var rect := _rects[i]
				var half_size := rect.size * .5
				var chr := char(text_server.font_get_char_from_glyph_index(font.get_rids()[0], font_size, cfx.glyph_index))
				draw_set_transform_matrix(cfx.transform)
				if style != RTxtOutline.Style.OUTLINE:
					draw_string(font, baseline - half_size, chr, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, cfx.color)
				if style != RTxtOutline.Style.TEXT:
					draw_string_outline(font, baseline - half_size, chr, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline_size, cfx.color)
		return
	
	for i in _rects.size():
		var rect := _rects[i]
		draw_string(font, rect.position + baseline, text[i], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

#region Editor
func _property_can_revert(property: StringName) -> bool:
	return property in JuicyLabel.new()

func _property_get_revert(property: StringName) -> Variant:
	return JuicyLabel.new().get(property)

func _get_property_list() -> Array[Dictionary]:
	return EditorProperties.new()\
		.string_enum(&"font_id", font_db.paths.keys() if font_db else [])\
		.integer_enum(&"horizontal_alignment", "Left,Center,Right,Fill")\
		.integer_enum(&"vertical_alignment", "Top,Center,Bottom,Fill")\
		.end()
#endregion
