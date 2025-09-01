@tool
class_name RTE_Woo extends RTxtEffect

## Syntax: [woo scale=1.0 freq=8.0][/woo]
var bbcode = "woo"

func _update() -> bool:
	var spd := get_float(&"spd", 2.0)
	var freq := get_float(&"freq", 2.0)
	if rnd_smooth(spd, freq) > 0.5:
		var c := chr
		chr = c.to_upper() if c == c.to_lower() else c.to_upper()
	return true
