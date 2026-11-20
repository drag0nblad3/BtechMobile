class_name UnitDb
extends RefCounted
## All unit designs found in data/units/, keyed by id.

const DEFAULT_DIR := "res://data/units"

var by_id: Dictionary = {}  # String -> UnitDef


static func load_dir(dir_path: String = DEFAULT_DIR) -> UnitDb:
	var db := UnitDb.new()
	for path in JsonFile.list_dir(dir_path):
		var def := UnitDef.from_dict(JsonFile.read(path))
		db.by_id[def.id] = def
	return db


func get_def(id: String) -> UnitDef:
	return by_id.get(id)
