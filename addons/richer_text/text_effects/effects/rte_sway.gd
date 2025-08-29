@tool
extends RicherTextEffect
## Sways the character back and forth.

var bbcode := "sway"

func _update():
	var sway := sin(time * 2.0) * 0.25
	var s := size * Vector2(0.5, -0.25)
	transform *= Transform2D.IDENTITY.translated(s)
	transform *= Transform2D(0.0, Vector2.ONE, sway, Vector2.ZERO)
	transform *= Transform2D.IDENTITY.translated(-s)
	return true
