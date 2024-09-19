@tool
extends RichTextEffectBase
## "Censors" a word by replacing vowels with symbols.

## Syntax: [cuss][]
const bbcode = "cuss"

const VOWELS := "aeiouAEIOU"
const CUSS_CHARS := "&$!@*#%"
const IGNORE := " !?.,;\""

func _process_custom_fx(c: CharFXTransform):
	# Never censor first letter.
	if c.relative_index != 0:
		# Always censor vowels.
		if get_char(c) in VOWELS:
			set_char(c, CUSS_CHARS[int(rand_anim(c, 5.0, len(CUSS_CHARS)))])
			c.color = Color.RED
		# Don't censor last letter.
		elif c.range.x + 1 < len(get_text()) and not get_text()[c.range.x + 1] in IGNORE:
			# Sometimes censor other letters.
			if rand_anim(c) > 0.75:
				set_char(c, CUSS_CHARS[int(rand_anim(c, 5.0, len(CUSS_CHARS)))])
				c.color = Color.RED
	return true
