@tool
extends RichTextEffectBase
## Converts numbers to letters in a way that is still readable with effort.

## Syntax: [l33t][]
var bbcode = "l33t"

var leet = {
	"L": "1",
	"l": "1",
	"I": "1",
	"i": "1",
	"E": "3",
	"e": "3",
	"T": "7",
	"t": "7",
	"S": "5",
	"s": "5",
	"A": "4",
	"a": "4",
	"O": "0",
	"o": "0",
}

func _process_custom_fx(c: CharFXTransform):
	var ch := get_char(c)
	if ch in leet:
		if rand_anim(c) > .2:
			set_char(c, leet[ch])
	return true
