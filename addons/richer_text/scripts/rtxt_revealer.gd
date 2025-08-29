@tool
class_name RTxtRevealer extends RTxtModifier
## TODO: Shorts a short text unless hovered, then displays longer.

@export var visible := false
@export_range(0.0, 1.0, 0.01) var amount := 0.0:
	set(a):
		amount = a
		label.queue_redraw()
@export var style_box: StyleBoxFlat

#func _preparse(bbcode: String) -> String:
	#var id := get_instance_id()
	#var lines := bbcode.strip_edges().split("\n")
	#for i in lines.size():
		#var parts := lines[i].split(";", true, 0)
		#var short := parts[0].strip_edges()
		#var long := parts[1].strip_edges()
		#lines[i] = "[revel id=%s x=true y=%s]%s]\n[revel id=%s x=false y=%s]%s]" % [id, i, short, id, i, long]
	#return "\n".join(lines)

func  _debug_draw(rtl: RicherTextLabel):
	var y := 0.0
	for i in rtl.get_line_count():
		var h := rtl.get_line_height(i)
		rtl.draw_style_box(style_box, Rect2(0.0, y, rtl.size.x, h))
		y += h

func _pressed():
	print("Selected")
