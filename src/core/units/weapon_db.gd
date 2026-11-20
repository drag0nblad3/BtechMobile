class_name WeaponDb
extends RefCounted
## All weapon types from data/weapons.json, keyed by id.

const DEFAULT_PATH := "res://data/weapons.json"

var by_id: Dictionary = {}  # String -> WeaponDef


static func load_file(path: String = DEFAULT_PATH) -> WeaponDb:
	var db := WeaponDb.new()
	var data: Variant = JsonFile.read(path)
	for d in data["weapons"]:
		var w := WeaponDef.from_dict(d)
		db.by_id[w.id] = w
	return db


func get_def(id: String) -> WeaponDef:
	return by_id.get(id)
