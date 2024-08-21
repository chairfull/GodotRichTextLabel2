@tool
extends Resource
class_name FontHelper

const BOLD_WEIGHT := 1.2
const ITALICS_SLANT := 0.25
const ITALICS_WEIGHT := -.25

const PATTERN_R := ["-r", "_r", "-regular", "_regular", "-Regular", "_Regular"]
const PATTERN_B := ["-b", "_b", "-bold", "_bold", "-Bold", "_Bold"]
const PATTERN_I := ["-i", "_i", "-italic", "_italic", "-Italic", "_Italic"]
const PATTERN_BI :=  ["-bi", "_bi", "-bold_italic", "_bold_italic", "-BoldItalic", "_BoldItalic"]
const PATTERN_M := ["-m", "_m", "-mono", "_mono"]
const PATTERN_ALL := PATTERN_R + PATTERN_B + PATTERN_I + PATTERN_BI + PATTERN_M
const FONT_FORMATS := ["otf", "ttf", "ttc", "otc", "woff", "woff2", "pfb", "pfm", "fnt", "font"]

const FONT_DIR := "res://"

## Search the fonts folder for all fonts.
static func get_font_paths(out: Dictionary, path := FONT_DIR) -> Dictionary:
	if not DirAccess.dir_exists_absolute(FONT_DIR):
		return {}
	
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				get_font_paths(out, path.path_join(file_name))
			else:
				if file_name.get_extension().to_lower() in FONT_FORMATS:
					var full_path := path.path_join(file_name)
					var id := full_path.get_file().get_basename()
					for pt in PATTERN_ALL:
						id = id.replace(pt, "")
					out[id] = full_path
			file_name = dir.get_next()
	else:
		push_error("No path: %s." % path)
	return out

static func _find_variant(fonts: Dictionary, head: String, tails: Array) -> String:
	for tail in tails:
		if head + tail in fonts:
			return fonts[head + tail]
	return ""

static func set_fonts(node: Node, fname: String, bold_weight := BOLD_WEIGHT, italics_slant := ITALICS_SLANT, italics_weight := ITALICS_WEIGHT):
	var fonts := get_fonts(fname, bold_weight, italics_slant, italics_weight)
	if node is RichTextLabel:
		for font_name in fonts:
			node.add_theme_font_override(font_name, fonts[font_name])
	else:
		push_error("TODO")

static func get_fonts(fname: String, bold_weight := BOLD_WEIGHT, italics_slant := ITALICS_SLANT, italics_weight := ITALICS_WEIGHT) -> Dictionary:
	var fonts := get_font_paths({})
	var out := {}
	
	# Normal font.
	var normal_font_path: String = fonts[fname] if fname in fonts else _find_variant(fonts, fname, PATTERN_R)
	if normal_font_path:
		out.normal_font = load(normal_font_path)
	else:
		out.normal_font = ThemeDB.fallback_font
	
	# Bold font.
	var bold_font_path := _find_variant(fonts, fname, PATTERN_B)
	if bold_font_path:
		out.bold_font = load(bold_font_path)
	else:
		var fv := FontVariation.new()
		fv.setup_local_to_scene()
		fv.set_base_font(out.normal_font)
		fv.set_variation_embolden(bold_weight)
		out.bold_font = fv
	
	# Italics font.
	var italics_font_path := _find_variant(fonts, fname, PATTERN_I)
	if italics_font_path:
		out.italics_font = load(italics_font_path)
	else:
		var fv := FontVariation.new()
		fv.set_base_font(out.normal_font)
		fv.set_variation_embolden(italics_weight)
		fv.set_variation_transform(Transform2D(Vector2(1, italics_slant), Vector2(0, 1), Vector2(0, 0)))
		out.italics_font = fv
	
	# Bold Italics font.
	var bold_italics_font_path := _find_variant(fonts, fname, PATTERN_BI)
	if bold_italics_font_path:
		out.bold_italics_font = load(bold_italics_font_path)
	else:
		var fv := FontVariation.new()
		fv.set_base_font(out.normal_font)
		fv.set_variation_embolden(bold_weight)
		fv.set_variation_transform(Transform2D(Vector2(1, italics_slant), Vector2(0, 1), Vector2(0, 0)))
		out.bold_italics_font = fv
	
	return out
