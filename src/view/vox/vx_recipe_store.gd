# Index: logical path lookup (exists/read), directory enumeration, index helpers.
class_name VxRecipeStore
extends RefCounted
## Legacy files and indexed JSON shards share the same logical recipe paths.
## Each read owns its FileAccess and returns fresh data, including on workers.

const ROOT := "res://data/voxels"
const INDEX := "_catalog/index.json"


static func exists(path: String, root: String = ROOT) -> bool:
	if FileAccess.file_exists(path):
		return true
	return _entries(root).has(_key(path, root))


static func read(path: String, root: String = ROOT) -> Variant:
	if FileAccess.file_exists(path):
		return JsonFile.read(path)
	var key := _key(path, root)
	var entry: Variant = _entries(root).get(key)
	if entry == null:
		return JsonFile.read(path)
	if not entry is Array or entry.size() != 3:
		push_error("Invalid voxel catalog index entry: " + path)
		return null
	var shard := str(entry[0])
	var offset := int(entry[1])
	var length := int(entry[2])
	if shard != shard.get_file() or not shard.ends_with(".json"):
		push_error("Invalid voxel catalog shard: " + shard)
		return null
	var file := FileAccess.open(root.path_join("_catalog").path_join(shard), FileAccess.READ)
	if file == null or offset < 0 or length <= 0 or offset + length > file.get_length():
		push_error("Missing or truncated voxel catalog record: " + path)
		return null
	file.seek(offset)
	var bytes := file.get_buffer(length)
	var record: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not record is Dictionary or record.get("path") != key or not record.get("recipe") is Dictionary:
		push_error("Invalid voxel catalog record: " + path)
		return null
	return record["recipe"]


## Match the legacy nonrecursive directory listing, with stable path order.
static func paths(dir_path: String = ROOT, root: String = ROOT) -> PackedStringArray:
	var found := {}
	if DirAccess.dir_exists_absolute(dir_path):
		for path: String in JsonFile.list_dir(dir_path):
			found[path] = true
	for key: String in _entries(root):
		var path := root.path_join(key)
		if path.get_base_dir() == dir_path.trim_suffix("/"):
			found[path] = true
	var out := PackedStringArray()
	for path: String in found:
		out.append(path)
	out.sort()
	return out


static func _key(path: String, root: String) -> String:
	var prefix := root.trim_suffix("/") + "/"
	return path.trim_prefix(prefix) if path.begins_with(prefix) else ""


static func _entries(root: String) -> Dictionary:
	var index_path := root.path_join(INDEX)
	if not FileAccess.file_exists(index_path):
		return {}
	var raw: Variant = JsonFile.read(index_path)
	if not raw is Dictionary or raw.get("version") != 1 or not raw.get("entries") is Dictionary:
		push_error("Invalid voxel catalog index: " + index_path)
		return {}
	return raw["entries"]
