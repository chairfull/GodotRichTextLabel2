extends RTxtEffect

var bbcode := "ticker"

func _update() -> bool:
	var ticker: RTxtTicker = get_instance()
	var w := label.get_content_width()
	var x := time * ticker.speed * weight * (-1 if ticker.reverse else 1) * font_size
	position.x = wrapf(position.x - x, -font_size, w - font_size)
	return true
