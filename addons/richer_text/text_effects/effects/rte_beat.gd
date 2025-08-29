@tool
extends RichTextEffectBase
## Pulses it's scale and color every second.

## [beat][]
var bbcode := "beat"

func _process_custom_fx(c: CharFXTransform):
	var cs := get_char_size(c) * Vector2(0.5, -0.3)
	var speed := 2.0
	var pulse := pow(maxf(sin(c.elapsed_time * speed), 0.0) * maxf(sin(c.elapsed_time * 2.0 * speed), 0.0), 4.0)
	c.transform *= Transform2D.IDENTITY.translated(cs)
	c.transform *= Transform2D.IDENTITY.scaled(Vector2.ONE + Vector2(1.4, 0.8) * pulse)
	c.transform *= Transform2D.IDENTITY.translated(-cs)
	c.color = lerp(Color.WHITE, c.color, pulse * 2.)
	return true
