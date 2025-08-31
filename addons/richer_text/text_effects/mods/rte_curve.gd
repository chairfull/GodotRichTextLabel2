@tool
extends RTxtEffect
## Used by the RichTextCurve modifier.

## [curve id=richer text curve instance id]]
var bbcode := "curve"

var path: Path2D

func _update():
	var curve: RTxtCurver = get_instance()
	if not path and curve and curve.curve:
		path = label.get_node(curve.curve)
	if path:
		var coffset := curve._sizes[index]
		coffset.x += curve.offset * (path.curve.get_baked_length() - label.get_content_width())
		var trans := path.curve.sample_baked_with_rotation(coffset.x)
		position = trans.origin + path.global_position - label.global_position
		#position.y += coffset.y
		if curve.rotate:
			rotate(trans.get_rotation())
		if curve.skew:
			skew = trans.get_rotation()
	return true
