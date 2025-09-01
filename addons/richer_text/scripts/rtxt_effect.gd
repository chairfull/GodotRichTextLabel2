@tool
@abstract class_name RTxtEffect extends RichTextEffect
## Use the _update() method.
## Designed to work like a shader: assumes char_fx is context.
## Instead of calling char_fx.color.a just call alpha.
## WARNING: When trying to animate images all we can really change is there color.
	## TODO: Write a custom drawer, make [img] transparent, and draw the controlable form overtop.

@export var tween_duration := 0.2 ## Used by JuicyLabel when transitioning to this effect.
@export var tween_trans := Tween.TRANS_LINEAR ## Used by JuicyLabel when transitioning to this effect.
@export var tween_ease := Tween.EASE_IN_OUT ## Used by JuicyLabel when transitioning to this effect.
@export_storage var _juicy: JuicyLabel

var _char_fx: CharFXTransform

## Used to sort effects. Lower get updated sooner.
## TODO
func _get_rank_order() -> int:
	return 0

var label_richtext: RichTextLabel:
	get:
		if _juicy:
			return
		if not label_richtext:
			var rtid := get_meta(&"rt")
			if rtid:
				label_richtext = instance_from_id(rtid)
		return label_richtext

var label: RicherTextLabel:
	get: return label_richtext

var anim: RTxtAnimator:
	get: return get_instance()

var text: String = "":
	get: return _juicy.text if _juicy else label.get_parsed_text()

## Global weight scaler for effects.
var weight: float:
	get: return _juicy.effect_weight if _juicy else label.effect_weight if label else 1.0

var font: RID:
	get: return _juicy.font.get_rids()[0] if _juicy else _char_fx.font

## Ideally effects are scaled to this.
var font_size: int:
	get: return _juicy.font_size if _juicy else label.parser.font_size if label and label.parser else 16

var font_height: float:
	get:
		var ts := TextServerManager.get_primary_interface()
		return ts.font_get_ascent(font, font_size) + ts.font_get_descent(font, font_size)

func is_image() -> bool:
	return false if _juicy else _char_fx.glyph_index == 0 and _char_fx.range.x in label._image_keys

var color: Color:
	get: return _char_fx.color if _juicy or not is_image() else Color.WHITE 
	set(c):
		if _juicy or not is_image():
			_char_fx.color = c
		else:
			label.update_image(_char_fx.range.x, RichTextLabel.UPDATE_COLOR, null, 0, 0, c)

## Get/set character transparency.
var alpha: float:
	get: return color.a
	set(a): color = Color(color, a)

## Index in a styled block.
var index: int:
	get: return _char_fx.relative_index

## Index in the full text.
## For _juicy this will absolute_index == index.
var absolute_index: int:
	get: return _char_fx.range.x

## Get/set actual character string. (Changing this isn't ideal for non-monospaced fonts.)
var chr: String:
	get: return text[absolute_index]
	set(c):
		var text_server = TextServerManager.get_primary_interface()
		var new_glyph := text_server.font_get_glyph_index(font, font_size, c.unicode_at(0), 0)
		_char_fx.glyph_index = new_glyph

## Previous character in the text.
var chr_prev: String:
	get: return text[absolute_index-1] if absolute_index-1 > 0 else ""

## Next character in the text.
var chr_next: String:
	get: return text[absolute_index+1] if absolute_index+1 < text.length() else ""

## Size of this specific character. Use label.size for 
var size: Vector2:
	get:
		if _juicy: return _juicy._rects[index].size
		if is_image(): return Vector2(font_size, font_size)
		var ts := TextServerManager.get_primary_interface()
		return ts.font_get_glyph_size(font, Vector2i(font_size, 0), _char_fx.glyph_index)

var transform: Transform2D:
	get: return _char_fx.transform
	set(t): _char_fx.transform = t

var position: Vector2:
	get: return transform.origin
	set(o): transform.origin = o

var scale: Vector2:
	get: return transform.get_scale()
	set(s): transform *= Transform2D.IDENTITY.scaled(s)

var rotation: float:
	get: return transform.get_rotation()
	set(r): transform = Transform2D(r, transform.origin)

var skew: float:
	get: return _char_fx.transform.get_skew()
	set(s):
		var t := transform
		transform = Transform2D(t.get_rotation(), t.get_scale(), s, t.get_origin())

var skew_y: float:
	get:
		# Extract from basis
		return atan2(transform.y.x, transform.y.y)
	set(s):
		var t := transform
		var shear := Transform2D(Vector2(1, tan(s)), Vector2(0, 1), Vector2.ZERO)  
		var new_basis := Transform2D(t.get_rotation(), Vector2.ZERO)
		new_basis = new_basis.scaled(t.get_scale())
		new_basis = shear * new_basis
		transform = Transform2D(new_basis.x, new_basis.y, t.get_origin())

func skew_pivoted(sk: float, pivot: Vector2):
	var t := transform
	var p := (Vector2(0.5, 0.5) - pivot) * size
	transform *= Transform2D.IDENTITY.translated(-p)
	transform *= Transform2D(Vector2(1.0, 0.0), Vector2(tan(sk), 1.0), Vector2.ZERO)
	transform *= Transform2D.IDENTITY.translated(p)

## Prefer using position or transform.origin.
var offset: Vector2:
	get: return _char_fx.offset
	set(o): _char_fx.offset = o

## Only works for RichTextAnimation effects.
var delta: float:
	get:
		if anim and _char_fx.range.x < anim._alphas.size():
			return anim._alphas[_char_fx.range.x]
		return 1.0

## Local mouse position.
## This function seems slow, so we attempt to cache it.
## It might not work if the first character in an effect doesn't try to access it.
var mouse: Vector2:
	get:
		if _juicy: return _juicy._smoothed_mouse_position
		if index == 0:
			mouse = label.get_local_mouse_position()
		return mouse

## Distance from character to the cursor.
var cursor_delta: Vector2:
	get:
		var off := (position - mouse)
		off.x = (off.x / font_size) / (1 + abs(off.x / font_size))
		off.y = (off.y / font_size) / (1 + abs(off.y / font_size))
		return off

## Distance from character to the center of the label.
var center_delta: Vector2:
	get:
		if _juicy: return (position - _juicy.size * .5) / font_size
		return (position - label.size * .5) / font_size

## Elapsed time. Useful for animations.
var time: float:
	get: return _juicy._anim if _juicy else _char_fx.elapsed_time

var range: Vector2i:
	get: return _char_fx.range

func rotate(angle: float):
	var cs := size * Vector2(0.5, -0.5)
	_char_fx.transform *= Transform2D.IDENTITY.translated(cs)
	_char_fx.transform *= Transform2D.IDENTITY.rotated_local(angle)
	_char_fx.transform *= Transform2D.IDENTITY.translated(-cs)

## Prefer overriding this instead of _process_custom_fx()
func _update() -> bool:
	return true

## Prefer overriding _update().
func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	_char_fx = char_fx
	return _update()

func get_int(key: StringName = &"id", default := 0) -> int:
	return _char_fx.env.get(key, default)

func get_float(key: StringName, default := 0.0) -> float:
	return _char_fx.env.get(key, default)

func get_bool(key: StringName, default := true) -> bool:
	return _char_fx.env.get(key, default)

func get_instance(key := &"id", default: Object = null) -> Object:
	if key in _char_fx.env:
		return instance_from_id(int(_char_fx.env[key]))
	return default

## Returns: 0.0 to TAU
func rnd(freq := 1.0, seed := 0.0) -> float:
	return fmod(float(index * freq + seed) * 12.9898, TAU)

## Returns: -1.0 to 0.0
func rnd_smooth(speed := 1.0, freq := 1.0, seed := 0.0) -> float:
	var phase := rnd(freq, seed)
	var t := time * speed
	return sin(t + phase) * 0.5 + sin(t * 1.73 + phase * 2.31) * 0.5

## Unsigned version: 0.0 to 1.0
func rnd_smoothu(speed := 1.0, seed := 0.0) -> float:
	return rnd_smooth(speed, seed) * .5 + .5

## Lerp between a basic sin() and a noise()
func rnd_noise(amount: float, speed := 1.0, freq := 1.0, seed := 0.0) -> float:
	var base := sin(time * speed + (index * freq + seed) * 12.9898)
	return lerpf(base, rnd_smooth(speed, freq, seed), amount)

## Returns the last characters transformation so we can use it for end of text animations.
## Should be applied last (so in an animation effect)
func _send_transform_back():
	if is_image():
		return
	
	var index := _char_fx.relative_index
	if index > 0 and index < anim._transforms.size():
		var ts := TextServerManager.get_primary_interface()
		var fsize := font_size
		var off_x := ts.font_get_glyph_size(font, Vector2i(fsize, 0), _char_fx.glyph_index).x
		var off_y := ts.font_get_ascent(font, fsize) - ts.font_get_descent(font, fsize)
		anim._char_size[index] = Vector2(off_x, off_y)
		anim._transforms[index] = _char_fx.transform

func cycle_colors(colors: PackedColorArray, t: float, default := Color.WHITE) -> Color:
	var n = colors.size()
	if n == 0: return default
	var idxf := fmod(t, float(n))
	var i := int(floor(idxf))
	var frac := idxf - float(i)
	var c1 = colors[i]
	var c2 = colors[(i + 1) % n]
	return lerp_hsv(c1, c2, frac)

func lerp_hsv(c1: Color, c2: Color, t: float) -> Color:
	var h1 = c1.h
	var h2 = c2.h
	var s1 = c1.s
	var s2 = c2.s
	var v1 = c1.v
	var v2 = c2.v
	var a1 = c1.a
	var a2 = c2.a
	var dh = fmod(h2 - h1 + 1.5, 1.0) - 0.5
	var h = fmod(h1 + dh * t, 1.0)
	var s = lerpf(s1, s2, t)
	var v = lerpf(v1, v2, t)
	var a = lerpf(a1, a2, t)
	return Color.from_hsv(h, s, v, a)
