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


## A 'Mech from data/units/ by id.
func mech(def_id: String, side: int, at: Vector2i, facing: int = 0, uid: int = 0) -> Unit:
	var def := UnitDb.load_dir().get_def(def_id)
	return Unit.new(uid if uid > 0 else side * 10 + at.x + 1, def, side, at, facing)


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
