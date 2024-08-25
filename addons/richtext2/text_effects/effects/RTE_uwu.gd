@tool
extends RichTextEffectBase
## Makes text cuter.
## "R" & "L" become "W" -> Royal Rumble = Woyaw Wumbwe.
## Requires a monospaced font.

## Syntax: [uwu][]
var bbcode = "uwu"

const r = "r"
const R = "R"
const l = "l"
const L = "L"

const w = "w"
const W = "W"

func _process_custom_fx(c: CharFXTransform):
	match get_char(c):
		r, l: set_char(c, "w")
		R, L: set_char(c, "W")
	return true
