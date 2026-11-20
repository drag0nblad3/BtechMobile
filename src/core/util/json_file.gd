class_name JsonFile
extends RefCounted
## Tiny helper for reading JSON data files. Fails loudly on bad data.


static func read(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("JsonFile: cannot read %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("JsonFile: invalid JSON in %s" % path)
	return parsed


## Paths of all .json files in a res:// directory, sorted.
static func list_dir(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".json"):
			out.append(dir_path.path_join(f))
	out.sort()
	return out
