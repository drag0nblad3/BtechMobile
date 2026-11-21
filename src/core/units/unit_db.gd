class_name UnitDb
extends RefCounted
## All unit designs found in data/units/, keyed by id (each OmniMech
## configuration is its own design, see OmniConfig).

const DEFAULT_DIR := "res://data/units"

var by_id: Dictionary = {}  # String -> UnitDef
var weapons: WeaponDb


static func load_dir(dir_path: String = DEFAULT_DIR, weapon_db: WeaponDb = null) -> UnitDb:
	var db := UnitDb.new()
	db.weapons = weapon_db if weapon_db else WeaponDb.load_file()
	for path in JsonFile.list_dir(dir_path):
		for d: Dictionary in OmniConfig.expand(JsonFile.read(path)):
			var def := UnitDef.from_dict(d, db.weapons)
			db.by_id[def.id] = def
	return db


func get_def(id: String) -> UnitDef:
	return by_id.get(id)


## Designs sorted light to heavy, then by name.
func sorted_defs() -> Array[UnitDef]:
	var out: Array[UnitDef] = []
	for d: UnitDef in by_id.values():
		out.append(d)
	out.sort_custom(func(a: UnitDef, b: UnitDef):
			return a.name < b.name if a.tonnage == b.tonnage else a.tonnage < b.tonnage)
	return out
