@tool
extends RicherTextEffect

## [sparkle]]
var bbcode := "sparkle"

func _update() -> bool:
	var s = 1.0 - color.s
	color.h = wrapf(color.h + sin(-time * 4.0 + _char_fx.glyph_index * 2.0) * s * .033, 0.0, 1.0)
	color.v = clamp(color.v + sin(time * 4.0 + _char_fx.glyph_index) * .25, 0.0, 1.0)
	return true
