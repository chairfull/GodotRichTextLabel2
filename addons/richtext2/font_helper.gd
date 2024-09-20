@tool
class_name FontHelper
extends RefCounted

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

## Scans entire project now.
## If you set it to res://fonts you could save a lot of time on large projects.
const FONT_DIR := "res://"

## TODO: Cache fonts here.
static var cache: Dictionary

static func _static_init() -> void:
	if Engine.is_editor_hint():
		var sig := EditorInterface.get_resource_filesystem().filesystem_changed
		if not sig.is_connected(_filesystem_changed):
			sig.connect(_filesystem_changed)

static func _filesystem_changed():
	update_cached_fonts()

static func clear_cache():
	cache.clear()

## Search the fonts folder for all fonts.
static func update_cached_fonts():
	clear_cache()
	_scan_for_fonts(cache)

static func has_font(id: StringName) -> bool:
	return id in cache

static func get_font(id: StringName) -> Font:
	if cache[id] is String:
		cache[id] = load(cache[id])
	return cache[id]

static func has_emoji_font() -> bool:
	return &"emoji_font" in cache

static func get_emoji_font() -> Font:
	return get_font(&"emoji_font")

## Scans recursively, populating the dictionary with fonts it finds.
static func _scan_for_fonts(dict: Dictionary, path := FONT_DIR) -> Dictionary:
	if not DirAccess.dir_exists_absolute(FONT_DIR):
		return dict
	
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				_scan_for_fonts(dict, path.path_join(file_name))
			else:
				if file_name.get_extension().to_lower() in FONT_FORMATS:
					# Ignore emoji fonts, unless it is explicitly wanted.
					if "emoji" in file_name.get_file().to_lower():
						if not &"emoji_font" in dict:
							dict[&"emoji_font"] = path.path_join(file_name)
					else:
						var full_path := path.path_join(file_name)
						var id := full_path.get_file().get_basename()
						for pt in PATTERN_ALL:
							id = id.replace(pt, "")
						dict[id] = full_path
				elif file_name.get_file().ends_with("emoji_font.tres"):
					dict[&"emoji_font"] = path.path_join(file_name)
			
			file_name = dir.get_next()
	else:
		push_error("No path: %s." % path)
	return dict

static func _find_variant(fonts: Dictionary, head: String, tails: Array) -> String:
	for tail in tails:
		if head + tail in fonts:
			return fonts[head + tail]
	return ""

static func set_fonts(node: Node, fname: String, bold_weight := BOLD_WEIGHT, italics_slant := ITALICS_SLANT, italics_weight := ITALICS_WEIGHT, font_paths := {}):
	var fonts := get_fonts(fname, bold_weight, italics_slant, italics_weight, font_paths)
	if node is RichTextLabel:
		for font_name in fonts:
			node.add_theme_font_override(font_name, fonts[font_name])
	else:
		push_error("TODO")

static func get_fonts(fname: String, bold_weight := BOLD_WEIGHT, italics_slant := ITALICS_SLANT, italics_weight := ITALICS_WEIGHT, font_paths: Variant = null) -> Dictionary:
	var fonts := font_paths if font_paths else _scan_for_fonts({})
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
