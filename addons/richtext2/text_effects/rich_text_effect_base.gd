@tool
extends RichTextEffect
class_name RichTextEffectBase

var label: RicherTextLabel
const c1 := 1.70158
const c3 := c1 + .5

#func ease_back(x):
	#return c3 * x * x * x - c1 * x * x

func ease_back_in(t: float, s: float = 1.70158) -> float:
	return t * t * ((s + 1) * t - s)

func ease_back_out(t: float, s: float = 1.70158) -> float:
	t -= 1
	return t * t * ((s + 1) * t + s) + 1

func ease_back_in_out(t: float, s: float = 1.70158) -> float:
	s *= 1.525
	if t < 0.5:
		t *= 2
		return 0.5 * (t * t * ((s + 1) * t - s))
	t -= 1
	t *= 2
	return 0.5 * (t * t * ((s + 1) * t + s) + 2)

func ease_back(t: float, s: float = 1.70158) -> float:
	t -= 1
	return t * t * ((s + 1) * t + s) + 1

func get_label() -> RichTextLabel:
	if not label:
		label = instance_from_id(get_meta(&"rt"))
	return label

func get_label2() -> RicherTextLabel:
	return get_label()

func get_label_animated() -> RichTextAnimation:
	return get_label()

func get_mouse_pos(c: CharFXTransform) -> Vector2:
	var lb := get_label()
	var frame := lb.get_tree().get_frame()
	if frame != lb.get_meta(&"frame", 0):
		var mp := lb.get_local_mouse_position()
		lb.set_meta(&"mouse_position", mp)
		lb.set_meta(&"frame", frame)
		return mp
	return lb.get_meta(&"mouse_position")

func get_text() -> String:
	return get_label().get_parsed_text()

func get_char(c: CharFXTransform) -> String:
	return get_text()[c.range.x]

func set_char(c: CharFXTransform, new_char: String):
	var text_server = TextServerManager.get_primary_interface()
	c.glyph_index = text_server.font_get_glyph_index(c.font, 16, new_char.unicode_at(0), 0)

func get_char_size(c: CharFXTransform) -> Vector2:
	return get_label2().get_normal_font().get_string_size(get_char(c))

func rand2(c: CharFXTransform, wrap := 1.0) -> float:
	return fmod(c.relative_index * .25 + get_label2()._get_character_random(c.range.x) * .03, wrap)

func rand(c: CharFXTransform, wrap := 1.0) -> float:
	return fmod(c.relative_index * .25 + get_label2()._get_character_random(c.range.x) * .01, wrap)

func rand_anim(c: CharFXTransform, anim_speed := 1.0, wrap := 1.0) -> float:
	return fmod(c.elapsed_time * anim_speed + c.relative_index * .25 + get_label2()._get_character_random(c.range.x) * .01, wrap)

func get_rand(c: CharFXTransform) -> int:
	return get_label2()._get_character_random(c.range.x)

# Only works for RichTextAnimation effects.
func get_animation_delta(c: CharFXTransform) -> float:
	var label := get_label_animated()
	return 1.0 if not label else label._get_character_alpha(c.range.x)

func is_animation_fading_out() -> bool:
	return get_label_animated().fade_out

# Returns the last characters transformation so we can use it for end of text animations.
func send_back_transform(c: CharFXTransform):
	var label := get_label_animated()
	var index := c.relative_index
	if index > 0 and index < len(label._transforms):
		var ts := TextServerManager.get_primary_interface()
		var font_size := get_label2().font_size
		var off_x := ts.font_get_glyph_size(c.font, Vector2i(font_size, 0), c.glyph_index).x
		var off_y := ts.font_get_ascent(c.font, font_size) - ts.font_get_descent(c.font, font_size)
		label._char_size[index] = Vector2(off_x, off_y)
		label._transforms[index] = c.transform
