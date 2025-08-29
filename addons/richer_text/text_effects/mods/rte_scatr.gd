@tool
extends RTxtEffect
## Draws text at a nodes position. Allowing for a single label to draw in multiple places.

## [scatr id=node instance id]]
var bbcode := "scatr"

func _update() -> bool:
	var scatter: RTxtScatterer = get_instance()
	var opos := _char_fx.transform.origin
	
	var point: Node = get_instance(&"pid")
	var line_index: int = get_float("ln")
	var rect := scatter._rects[line_index]
	var point_rotation := 0.0
	var point_scale := Vector2.ONE
	
	if point:
		if point is CanvasItem:
			rect.position -= point.global_position
			if point is Node2D:
				if scatter.copy_rotation:
					point_rotation = (point as Node2D).rotation
				if scatter.copy_scale:
					point_scale = (point as Node2D).scale
		elif point is Node3D:
			var vp := label.get_viewport()
			var cam := vp.get_camera_3d()
			var pos := cam.unproject_position(point.global_position)
			rect.position += pos
		
		match scatter.horizontal_alignment:
			HORIZONTAL_ALIGNMENT_CENTER: rect.position.x += rect.size.x * .5
			HORIZONTAL_ALIGNMENT_RIGHT: rect.position.x += rect.size.x
		
		match scatter.vertical_alignment:
			VERTICAL_ALIGNMENT_CENTER: rect.position.y += rect.size.y * .5
			VERTICAL_ALIGNMENT_BOTTOM: rect.position.y += rect.size.y
		
		if scatter.viewport_clamp:
			var min_x := -scatter.viewport_margin.x
			var min_y := -scatter.viewport_margin.y
			var max_x: int = ProjectSettings.get("display/window/size/viewport_width") - scatter.viewport_margin.x
			var max_y: int = ProjectSettings.get("display/window/size/viewport_height") - scatter.viewport_margin.y
			if rect.position.x > min_x: rect.position.x = min_x
			if rect.position.x - rect.size.x < -max_x: rect.position.x = -max_x + rect.size.x
			if rect.position.y > min_y: rect.position.y = min_y
			if rect.position.y - scatter._line_height < -max_y: rect.position.y = -max_y + scatter._line_height
			
		rect.position += label.global_position
		
		if point_rotation != 0.0 or point_scale != Vector2.ONE:
			var pivot := rect.size * 0.5
			var rel := position - pivot - Vector2(0.0, scatter._line_height * line_index)
			rel = rel * point_scale
			rel = rel.rotated(point_rotation)
			
			var new_origin := pivot + rel
			_char_fx.transform = Transform2D(point_rotation, new_origin)
		else:
			rect.position.y += scatter._line_height * line_index
		
		if point_scale != Vector2.ONE:
			_char_fx.transform = _char_fx.transform.scaled_local(point_scale)
		
		position -= rect.position
	
	var r := Rect2(Vector2.ZERO, Vector2(size.x, -label.font_size))
	r = r.grow_individual(1, 0, 1, 0)
	var rect_points: PackedVector2Array = [
		r.position, Vector2(r.position.x, r.end.y), r.end, Vector2(r.end.x, r.position.y)
	]
	rect_points *= Transform2D(0.0, _char_fx.transform.get_scale(), 0.0, Vector2.ZERO)
	rect_points *= Transform2D(_char_fx.transform.get_rotation(), Vector2.ONE, 0.0, _char_fx.transform.get_origin()).affine_inverse()
	scatter._char_bounds[_char_fx.range.x] = rect_points
	
	return true
