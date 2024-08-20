@tool
extends RichTextEffectBase

# v2: last letter in each word won't be symbolized.

## Syntax: [cuss][]
const bbcode = "cuss"

const VOWELS := "aeiouAEIOU"
const CUSS_CHARS := "&$!@*#%"
const SPACE := " "
const IGNORE := "!?.,;\""

var _was_space := false
var _next_is_space := false

var _last_index := -1
var _length := 0
var _text := ""
var _temp_text := ""

func _process_custom_fx(c: CharFXTransform):
	if c.relative_index == 0:
		if _last_index > 0:
			_length = _last_index
			_last_index = -1
			_text = _temp_text
		_temp_text = ""
	
	var ch =  get_char(c)
	_temp_text += ch
	
	if not _was_space and not ch == SPACE and not ch in IGNORE:
		# not first or last letter
		if c.relative_index > 0 and c.relative_index < _length:
			# is not final letter in word
			if c.relative_index > len(_text)-1 or _text[c.relative_index+1] != " ":
				var t = c.elapsed_time + c.range.x * 10.2 + c.relative_index * 2
				t *= 4.3
				if ch in VOWELS or sin(t) > 0.0:
					set_char(c, CUSS_CHARS[int(t) % len(CUSS_CHARS)])
					
	_was_space = ch == SPACE
	_last_index = c.relative_index
	return true
