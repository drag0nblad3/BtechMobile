# Index: ordered catalog records, logical design lookup.
class_name UnitCatalog
extends RefCounted
## Official arrays are sorted by original filename/ID before Omni expansion.
## Fixture and ad-hoc directories retain their legacy file/record order.

const OFFICIAL := ["res://data/units", "res://data/vehicles", "res://data/battle_armor"]


static func records(dir_path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for path: String in JsonFile.list_dir(dir_path):
		var raw: Variant = JsonFile.read(path)
		if raw is Dictionary:
			out.append(raw)
		elif raw is Array:
			for item: Variant in raw:
				if not item is Dictionary:
					push_error("UnitCatalog: invalid entry in " + path)
					return []
				out.append(item)
		else:
			push_error("UnitCatalog: invalid catalog " + path)
			return []
	if dir_path in OFFICIAL:
		out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("id", "")) < String(b.get("id", "")))
	return out


## Compatibility for tests/tools that inspect an individual authored design.
## This does not expand Omni configurations or change the record.
static func record(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var raw: Variant = JsonFile.read(path)
		return raw if raw is Dictionary else {}
	var dir_path := path.get_base_dir()
	if not dir_path in OFFICIAL:
		return {}
	var id := path.get_file().get_basename()
	for design: Dictionary in records(dir_path):
		if design.get("id", "") == id:
			return design
	return {}
