class_name TestCase
extends RefCounted
## Base class for tests. Methods named test_* are run by tests/run_tests.gd.

var failures: Array[String] = []
var _current := ""


func check(cond: bool, msg: String = "") -> void:
	if not cond:
		failures.append("%s: %s" % [_current, msg])


func check_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		failures.append("%s: %s expected %s, got %s" % [_current, msg, expected, actual])


## Shared fixtures --------------------------------------------------------

func terrain() -> TerrainDb:
	return TerrainDb.load_file()


## Map from offset rows, e.g. ["c0 c0", "c1 w0d1"].
func make_map(rows: Array) -> BattleMap:
	return MapLoader.from_dict({"rows": rows}, terrain())


func make_def(walk: int, tons: int = 50) -> UnitDef:
	return UnitDef.from_dict({"id": "t", "name": "Test", "tonnage": tons, "walk_mp": walk})


func weapons() -> WeaponDb:
	return WeaponDb.load_file()


## Made-up loadouts that exercise one rule (tests/fixtures/units, ids "test_*").
const FIXTURES := "res://tests/fixtures/units"


## A 'Mech from data/units/ by id, or a test fixture ("test_...").
func mech(def_id: String, side: int, at: Vector2i, facing: int = 0, uid: int = 0) -> Unit:
	var def := (UnitDb.load_dir(FIXTURES) if def_id.begins_with("test_") else UnitDb.load_dir()).get_def(def_id)
	return Unit.new(uid if uid > 0 else side * 10 + at.x + 1, def, side, at, facing)


## Made-up Asset cards for rule tests (tests/fixtures/assets, ids "test_*").
const ASSET_FIXTURES := "res://tests/fixtures/assets"


## An Asset (vehicle, infantry) from data/assets/ or a test fixture card.
func asset(def_id: String, side: int, at: Vector2i, facing: int = 0, uid: int = 0) -> Unit:
	var db := UnitDb.new()
	db.weapons = WeaponDb.load_file()
	db.add_assets(ASSET_FIXTURES if def_id.begins_with("test_") else UnitDb.ASSET_DIR)
	return Unit.new(uid if uid > 0 else side * 10 + at.x + 1, db.get_def(def_id), side, at, facing)


## A combat vehicle from data/vehicles/.
func vehicle(def_id: String, side: int, at: Vector2i, facing: int = 0, uid: int = 0) -> Unit:
	var db := UnitDb.new()
	db.weapons = WeaponDb.load_file()
	db.add_vehicles(UnitDb.VEHICLE_DIR)
	return Unit.new(uid if uid > 0 else side * 10 + at.x + 1, db.get_def(def_id), side, at, facing)


## Index in u.weapons of the `nth` weapon with this id (-1 if none).
func gun_index(u: Unit, weapon_id: String, nth: int = 0) -> int:
	for i in u.weapons.size():
		if u.weapons[i].def.id == weapon_id:
			if nth == 0:
				return i
			nth -= 1
	return -1


func gun(u: Unit, weapon_id: String, nth: int = 0) -> MountedWeapon:
	return u.weapons[gun_index(u, weapon_id, nth)]


func hex_at(col: int, row: int) -> Vector2i:
	return Hex.from_offset(Vector2i(col, row))


## Map of `cols` x `rows` clear level-0 hexes.
func open_map(cols: int, rows: int) -> BattleMap:
	var lines := []
	for r in rows:
		var t := []
		for c in cols:
			t.append("c0")
		lines.append(" ".join(t))
	return make_map(lines)
