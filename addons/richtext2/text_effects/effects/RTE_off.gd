# Offsets characters by an amount.
@tool
extends RichTextEffect

# Syntax: [off][]
var bbcode = "off"

func _get_method_info(method: String):
	return {
		desc="Offset characters by an amount",
		kwargs={
			x={desc="X distance to offset"},
			y={desc="Y distance to offset"}
		}
	}

func to_float(s: String):
	if s.begins_with("."):
		return ("0" + s).to_float()
	return s.to_float()

func _process_custom_fx(c:CharFXTransform):
	var off = c.env.get("off", Vector2.ZERO)
	match typeof(off):
		TYPE_FLOAT, TYPE_INT: c.offset.y += off
		TYPE_VECTOR2: c.offset += off
		TYPE_ARRAY: c.offset += Vector2(off[0], off[1])
	return true
