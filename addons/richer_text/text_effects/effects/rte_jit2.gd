@tool
extends RichTextEffectBase
## Makes words shake around.

## Syntax: [jit2 scale=1.0 freq=8.0][]
var bbcode = "jit2"

func _process_custom_fx(c: CharFXTransform):
	var scale:float = c.env.get("scale", 1.0)
	var freq:float = c.env.get("freq", 16.0)
	
	var t = c.elapsed_time
	var s = fmod((c.relative_index + t) * PI * 1.25, TAU)
	var p = sin(t * freq + c.range.x) * .33
	c.offset.x += sin(s) * p * scale
	c.offset.y += cos(s) * p * scale

	return true
