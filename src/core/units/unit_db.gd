class_name UnitDb
extends RefCounted
## Unit catalogs accept individual dictionaries or arrays of dictionaries.
## Each OmniMech configuration is its own design (see OmniConfig).

const DEFAULT_DIR := "res://data/units"
## Battlefield Support Asset cards (vehicles, infantry): data/assets/.
const ASSET_DIR := "res://data/assets"
const VEHICLE_DIR := "res://data/vehicles"
const BA_DIR := "res://data/battle_armor"

var by_id: Dictionary = {}  # String -> UnitDef
var assets: Dictionary = {}  # String -> UnitDef with an AssetCard
var vehicles: Dictionary = {}  # String -> UnitDef with a VehicleSpec
var battle_armor: Dictionary = {}  # String -> UnitDef with a BaSpec
var weapons: WeaponDb


static func load_dir(dir_path: String = DEFAULT_DIR, weapon_db: WeaponDb = null) -> UnitDb:
	var db := UnitDb.new()
	db.weapons = weapon_db if weapon_db else WeaponDb.load_file()
	for path in JsonFile.list_dir(dir_path):
		for record: Dictionary in _read_designs(path):
			for d: Dictionary in OmniConfig.expand(record):
				var def := UnitDef.from_dict(d, db.weapons)
				db.by_id[def.id] = def
	if dir_path == DEFAULT_DIR:
		db.add_assets(ASSET_DIR)
		db.add_vehicles(VEHICLE_DIR)
		db.add_battle_armor(BA_DIR)
	return db


## Loads Asset cards from a folder (kept apart from the 'Mech catalog).
func add_assets(dir_path: String) -> void:
	for path in JsonFile.list_dir(dir_path):
		var def := UnitDef.from_dict(JsonFile.read(path), weapons)
		assets[def.id] = def


## Loads combat vehicle record sheets (kept apart from the 'Mech catalog).
func add_vehicles(dir_path: String) -> void:
	for path in JsonFile.list_dir(dir_path):
		for record: Dictionary in _read_designs(path):
			var def := UnitDef.from_dict(record, weapons)
			vehicles[def.id] = def


func add_battle_armor(dir_path: String) -> void:
	for path in JsonFile.list_dir(dir_path):
		for record: Dictionary in _read_designs(path):
			var def := UnitDef.from_dict(record, weapons)
			battle_armor[def.id] = def


## Normalize the on-disk container only; keep dictionary/array order intact.
static func _read_designs(path: String) -> Array[Dictionary]:
	var raw: Variant = JsonFile.read(path)
	var out: Array[Dictionary] = []
	if raw is Dictionary:
		out.append(raw)
	elif raw is Array:
		for record: Variant in raw:
			if not record is Dictionary:
				push_error("UnitDb: non-dictionary catalog entry in %s" % path)
				return []
			out.append(record)
	else:
		push_error("UnitDb: expected dictionary or array in %s" % path)
	return out


## Battle armor designs: Inner Sphere first, then by BV.
func sorted_battle_armor() -> Array[UnitDef]:
	var out: Array[UnitDef] = []
	for d: UnitDef in battle_armor.values():
		out.append(d)
	out.sort_custom(func(a: UnitDef, b: UnitDef):
			return a.bv < b.bv if a.is_clan() == b.is_clan() else not a.is_clan())
	return out


## Asset designs sorted by cost, then name.
func sorted_assets() -> Array[UnitDef]:
	var out: Array[UnitDef] = []
	for d: UnitDef in assets.values():
		out.append(d)
	out.sort_custom(func(a: UnitDef, b: UnitDef):
			return a.name < b.name if a.bv == b.bv else a.bv < b.bv)
	return out


## Combat vehicle designs sorted light to heavy, then by name.
func sorted_vehicles() -> Array[UnitDef]:
	var out: Array[UnitDef] = []
	for d: UnitDef in vehicles.values():
		out.append(d)
	out.sort_custom(func(a: UnitDef, b: UnitDef):
			return a.name < b.name if a.tonnage == b.tonnage else a.tonnage < b.tonnage)
	return out


func get_def(id: String) -> UnitDef:
	return by_id.get(id, assets.get(id, vehicles.get(id, battle_armor.get(id))))


## Designs sorted light to heavy, then by name.
func sorted_defs() -> Array[UnitDef]:
	var out: Array[UnitDef] = []
	for d: UnitDef in by_id.values():
		out.append(d)
	out.sort_custom(func(a: UnitDef, b: UnitDef):
			return a.name < b.name if a.tonnage == b.tonnage else a.tonnage < b.tonnage)
	return out
