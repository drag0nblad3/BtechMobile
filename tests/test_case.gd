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
