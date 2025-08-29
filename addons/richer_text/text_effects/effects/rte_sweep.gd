@tool
extends RicherTextEffect

var bbcode := "sweep"

func _update() -> bool:
	var interval := 2.5
	var band_width := 0.15
	var total := text.length() - 1.0
	if total <= 0:
		return true
	
	var progress := fmod(time, interval) / interval
	var norm_index := float(range.x) / total
	
	if absf(norm_index - progress) < band_width:
		var strength := 1.0 - (absf(norm_index - progress) / band_width)
		color = color.lerp(Color(1, 1, 1), strength)
	
	return true
