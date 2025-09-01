@tool
class_name FontDB extends Resource
## Font Database scans for fonts so they can be easily used.

const EXT_FONT: PackedStringArray = ["otf", "ttf", "ttc", "otc", "woff", "woff2", "pfb", "pfm", "fnt", "font"]
const PATH_DEFAULT_DB := "res://assets/font_db.tres"

@export_dir var parent_dir := "res://" ## Directory to start scanning from.
@export var paths: Dictionary[StringName, String] ## Paths organized by a nickname.
@export var emoji: String ## Path to emoji font.
@export var sanitize_ids := true ## Make names lowercase without symbols.

## Scans parent_dir for fonts.
@export_tool_button("Find Fonts") var _tool_button := find_fonts

static func get_default() -> FontDB:
	if Engine.is_editor_hint():
		if not FileAccess.file_exists(PATH_DEFAULT_DB):
			if not DirAccess.dir_exists_absolute(PATH_DEFAULT_DB.get_base_dir()):
				DirAccess.make_dir_recursive_absolute(PATH_DEFAULT_DB.get_base_dir())
			var fontdb := FontDB.new()
			fontdb.find_fonts()
			var err := ResourceSaver.save(fontdb, PATH_DEFAULT_DB)
			if err != OK:
				push_error("FontDB: ", error_string(err))
	return load(PATH_DEFAULT_DB)

func get_nice_names() -> PackedStringArray:
	return paths.keys().map(func(s: String): return s.capitalize())

func get_font(id: StringName) -> Font:
	id = _sanitise(id)
	#print("SAN ", id)
	return load(paths[id]) if id in paths else ThemeDB.fallback_font

func find_fonts():
	if not Engine.is_editor_hint():
		push_error("Shouldn't scan for fonts when not in editor.")
		return
	
	_scan_dir(parent_dir)
	notify_property_list_changed()

func _sanitise(id: String) -> StringName:
	var out := ""
	for c in id.to_snake_case():
		if c in "abcdefghijklmnopqrstuvwxyz0123456789":
			out += c
		elif out and out[-1] != "-":
			out += "-"
	return out
	
func _scan_dir(dir: String):
	for subdir in DirAccess.get_directories_at(dir):
		_scan_dir(dir.path_join(subdir))
	
	for file in DirAccess.get_files_at(dir):
		if file.get_extension().to_lower() in EXT_FONT:
			var font_path := dir.path_join(file)
			var font_id := file.get_basename().get_file()
			if "emoji" in font_id.to_lower():
				print("Found emoji font: %s" % font_path)
				emoji = font_path
			elif not paths.find_key(font_path):
				if sanitize_ids:
					font_id = _sanitise(font_id)
				print("Found font: %s" % font_id)
				paths[font_id] = font_path
			else:
				print("Already found font at %s" % font_path)
