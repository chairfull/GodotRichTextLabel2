# Turns words into babble.
# "R" & "L" become "W" -> Royal Rumble = Woyaw Wumbwe.
# Requires a monospaced font.
@tool
extends RichTextEffect

# Syntax: [uwu][/uwu]
var bbcode = "uwu"

const r = "r"
const R = "R"
const l = "l"
const L = "L"

const w = "w"
const W = "W"

func _process_custom_fx(char_fx):
	match char_fx.character:
		r, l: char_fx.character = w
		R, L: char_fx.character = W
	return true
