@tool
class_name RTE_Mega extends RTxtEffect
## Add noise or a simple sway to the position, rotation, scale, or skew.

## Syntax: [meta][/meta]
## Meant to be used by JuicyText.
var bbcode := "meta"

@export_group("Color", "mega_color_")
@export var mega_color_enabled := true ## Animate colors?
@export var mega_color_include_own := true ## Will blend between it's own and the list.
@export var mega_color_list: PackedColorArray ## List of colors to blend between.
@export_range(0.0, 1.0) var mega_color_freq := 1.0
@export_range(0.0, 1.0) var mega_color_noise := 1.0
@export var mega_color_speed := 1.0

@export_group("Position", "mega_position_")
@export var mega_position_enabled := true ## Animate position?
@export var mega_position_scale := Vector2(0.0, 0.2) ## Scaled to font_size.
@export_range(0.0, 1.0) var mega_position_freq := 1.0
@export_range(0.0, 1.0) var mega_position_noise := 1.0
@export var mega_position_speed := 1.0

@export_group("Rotation", "mega_rotation_")
@export var mega_rotation_enabled := true
@export_range(0.0, 1.0) var mega_rotation_scale := 0.1
@export_range(0.0, 1.0) var mega_rotation_freq := 1.0
@export_range(0.0, 1.0) var mega_rotation_noise := 1.0
@export var mega_rotation_speed := 1.0

@export_group("Scale", "mega_scale_")
@export var mega_scale_enabled := true
@export var mega_scale_scale := Vector2(0.1, 0.1)
@export_range(0.0, 1.0) var mega_scale_freq := 1.0
@export_range(0.0, 1.0) var mega_scale_noise := 1.0
@export var mega_scale_speed := 1.0

@export_group("Skew", "mega_skew_")
@export var mega_skew_enabled := true
@export_range(0.0, 1.0) var mega_skew_scale := 0.1
@export_range(0.0, 1.0) var mega_skew_freq := 1.0
@export_range(0.0, 1.0) var mega_skew_noise := 1.0
@export var mega_skew_speed := 1.0
## center = (0.5, 0.5)
## bottom = (0.5, 1.0)
## top = (0.5, 0.0)
@export var mega_skew_pivot := Vector2(0.5, 0.5)

func _update() -> bool:
	if mega_position_enabled:
		var x := rnd_noise(mega_position_noise, mega_position_speed, mega_position_freq, PI)
		var y := rnd_noise(mega_position_noise, mega_position_speed, mega_position_freq, TAU)
		position += Vector2(x, y) * mega_position_scale * font_size  * weight
	
	if mega_rotation_enabled:
		rotation = rnd_noise(mega_rotation_noise, mega_rotation_speed, mega_rotation_freq, 0.0) * TAU * mega_rotation_scale * weight
	
	if mega_scale_enabled:
		scale = Vector2.ONE + mega_scale_scale * rnd_noise(mega_scale_noise, mega_scale_speed, mega_scale_freq, 3.0) * weight
	
	if mega_skew_enabled:
		skew_pivoted(rnd_noise(mega_skew_noise, mega_skew_speed, mega_skew_freq, 2.0) * mega_skew_scale * weight, mega_skew_pivot)
	
	if mega_color_enabled:
		var new_color: Color
		# TODO: Improve this. I just guessed around.
		var t := time * mega_color_speed + index * mega_color_freq
		t += lerpf(0.0, rnd(mega_color_freq, 321), mega_color_noise)
		if mega_color_include_own:
			new_color = cycle_colors(mega_color_list + PackedColorArray([color]), t, color)
		else:
			new_color = cycle_colors(mega_color_list, t, color)
		color = lerp_hsv(color, new_color, weight)
	
	if _char_fx.has_meta(&"outline_states"):
		var list: Array = _char_fx.get_meta(&"outline_states")
		var n := list.size()
		for i in n:
			var phase := fmod(time + float(i), 1.0)
			var osize := lerp(i*10, i*10+10, phase)
			var is_odd := int(fmod(time + float(i), 2.)) % 2 == 0
			var ocolr := Color.GREEN_YELLOW if is_odd else Color.DEEP_PINK
			if i == n-1:
				ocolr.a = 1.0-phase
			list[i].size = osize
			list[i].color = ocolr
	
	return true
