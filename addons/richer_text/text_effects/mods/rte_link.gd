@tool
class_name RTxtLinkEffect extends RTxtEffect
## Customize animation by overriding _update_unhovered() _update_hovered() and _update_clicked()
## Change timing.

const PROPS: PackedStringArray = ["color", "elapsed_time", "glyph_count", "glyph_flags", "glyph_index", "outline", "range", "relative_index", "transform", "offset", "font"]

@export var hover_duration := 0.2
@export var hover_trans := Tween.TRANS_LINEAR
@export var hover_ease := Tween.EASE_IN_OUT

@export var unhover_duration := 0.1
@export var unhover_trans := Tween.TRANS_LINEAR
@export var unhover_ease := Tween.EASE_IN_OUT

@export var clicked_in_duration := 0.2
@export var clicked_in_trans := Tween.TRANS_LINEAR
@export var clicked_in_ease := Tween.EASE_IN_OUT
@export var clicked_wait := 0.5
@export var clicked_out_duration := 0.2
@export var clicked_out_trans := Tween.TRANS_LINEAR
@export var clicked_out_ease := Tween.EASE_IN_OUT

var bbcode := "link"
var _states: Dictionary[int, float]
var _states_clicked: Dictionary[int, float]
var _clicked: Dictionary[int, bool]
var _tweens: Dictionary[int, Tween]
var _tweens_clicked: Dictionary[int, Tween]
var _hovered := -1

func _clear():
	_states.clear()
	_states_clicked.clear()
	_clicked.clear()
	_tweens.clear()
	_tweens_clicked.clear()
	_hovered = -1

## Override for unhovered state animation.
func _update_unhovered() -> bool:
	color = Color.HOT_PINK
	return true

## Override for hovered state animation.
func _update_hovered() -> bool:
	color = Color.GREEN_YELLOW
	return true

## Override for clicked state animation.
func _update_clicked() -> bool:
	color = Color.DEEP_SKY_BLUE
	return true

func _get_rank_order() -> int:
	return 100

func _tween(index: int, from: float, to: float, duration: float, trans: int, ease: int):
	var tween: Tween = _tweens.get(index)
	if tween: tween.kill()
	tween = label.create_tween()
	tween.tween_method(func(x): _states[index] = x, _states.get(index, from), to, duration).set_trans(trans).set_ease(ease)
	_tweens[index] = tween
	return tween
	
func _link_hovered(index: int):
	_tween(index, 0.0, 1.0, hover_duration, hover_trans, hover_ease)
	
func _link_unhovered(index: int):
	_tween(index, 1.0, 0.0, unhover_duration, unhover_trans, unhover_ease)

func _link_clicked(index: int):
	var tween: Tween = _tweens_clicked.get(index)
	if tween: tween.kill()
	_clicked[index] = true
	tween = label.create_tween()
	tween.tween_method(func(x): _states_clicked[index] = x, _states_clicked.get(index, 0.0), 1.0, clicked_in_duration).set_trans(clicked_in_trans).set_ease(clicked_in_ease)
	tween.tween_interval(clicked_wait)
	tween.tween_method(func(x): _states_clicked[index] = x, 1.0, 0.0, clicked_out_duration).set_trans(clicked_out_trans).set_ease(clicked_out_ease)
	tween.tween_callback(func(): _clicked[index] = false)
	_tweens_clicked[index] = tween

func _duplicate(c: CharFXTransform) -> CharFXTransform:
	var out := CharFXTransform.new()
	for prop in PROPS:
		out[prop] = c[prop]
	return out

func _update() -> bool:
	var link_index := get_int()
	var cfx := _char_fx
	var amount := _states.get(link_index, 0.0)
	
	if amount == 0.0:
		_update_unhovered()
	elif amount == 1.0:
		_update_hovered()
	else:
		var a := _duplicate(cfx)
		_char_fx = a
		_update_unhovered()
		var b := _duplicate(cfx)
		_char_fx = b
		_update_hovered()
		
		cfx.color = lerp(a.color, b.color, amount)
		cfx.transform = a.transform.interpolate_with(b.transform, amount)
		cfx.offset = lerp(a.offset, b.offset, amount)
	
	if _clicked.get(link_index, false):
		var a := _duplicate(cfx)
		_char_fx = a
		_update_clicked()
		
		var amount_clicked := _states_clicked.get(link_index, 0.0)
		cfx.color = lerp(cfx.color, a.color, amount_clicked)
		cfx.transform = cfx.transform.interpolate_with(a.transform, amount_clicked)
		cfx.offset = lerp(cfx.offset, a.offset, amount_clicked)
	
	if not label:
		return false #????
	
	# HACK: Record which character is part of which link.
	var link_data := label._link_regions
	if not link_index in link_data:
		link_data[link_index] = PackedInt32Array()
	if not range.x in link_data[link_index]:
		link_data[link_index].append(range.x)
	
	## TODO: Apply transform.
	var poly := PackedVector2Array([
		Vector2(position.x, position.y),
		Vector2(position.x + size.x, position.y),
		Vector2(position.x + size.x, position.y - font_size),
		Vector2(position.x, position.y - font_size)
	])
	if index == 0:
		#label.add_draw(func(c: RicherTextLabel):
			#var ply := label._link_rects[link_index]
			#var clrs: PackedColorArray
			#clrs.resize(ply.size())
			#clrs.fill(Color(Color.RED, 0.1))
			#c.draw_polygon(ply, clrs))
		label._link_rects[link_index] = poly
	else:
		label._link_rects[link_index] = Geometry2D.convex_hull(label._link_rects[link_index] + poly)
	
	return true

## Called by RicherTextLabel in _input().
func _check_mouse_over(lbl: RicherTextLabel, mouse_position: Vector2):
	var link_data: Dictionary = lbl._link_regions
	var hovering := -1
	var scatter: RTxtScatterer = lbl.get_modifier(RTxtScatterer)
	if scatter:
		for link_index in link_data:
			var link_list: PackedInt32Array = link_data[link_index]
			for i in link_list:
				if i < scatter._char_bounds.size():
					var bounds: PackedVector2Array = scatter._char_bounds[i]
					if Geometry2D.is_point_in_polygon(mouse_position, bounds):
						hovering = link_index
	else:
		for link_index in label._link_rects:
			var bounds := label._link_rects[link_index]
			if Geometry2D.is_point_in_polygon(mouse_position, bounds):
				hovering = link_index
	label.hovered_link = hovering
