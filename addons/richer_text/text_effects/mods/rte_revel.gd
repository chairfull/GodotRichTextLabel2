extends RTxtEffect

var bbcode := "revel"

var xpos := 0.0

func _update() -> bool:
	var re := get_instance()
	var x := get_bool("x")
	var y := get_int("y")
	#_char_fx.visible = x != re.visible
	alpha = (1.0 - re.amount) if x else re.amount
	if not x:
		position.y -= font_height
	position.y -= font_height * y
	#if index == 0:
		#xpos = position.x * .5
	#if not x:
		#position.x -= label.get_content_width() * .5
		#position.x -= xpos
	#position.x += label.size.x * .5
	#position.x -= label.size.x * .5
	#position.x -= label.size.x * .5
	
	return true
