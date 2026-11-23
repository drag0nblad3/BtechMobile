extends TestCase
## Batch thirteen: 20 formerly untreated sculpted chassis, including two quads.

const CHASSIS := [
	"shockwave", "shootist", "snake", "spartan", "spector", "starslayer",
	"striker", "suburbanmech", "swordsman", "talon", "talos", "tarantula",
	"thanatos", "thorn", "thunder_hawk", "thunder_stallion", "tsunami",
	"valkyrie", "venom", "verfolger"
]
const QUADS := ["tarantula", "thunder_stallion"]
const PRIMARY := ["ct", "lt", "la", "ll_shin"]
const RIG := ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]


func _read(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(recipe: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in recipe.get("parts", []):
		if p.get("name", "") == name:
			return p
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for s: Dictionary in part.get("shapes", []):
		if s.has("loft"):
			return s["loft"]
	return {}


func test_all_twenty_keep_rigs_and_detail_sources() -> void:
	for chassis: String in CHASSIS:
		var low := _read(chassis, "_shape")
		var high := _read(chassis, "")
		for part_name: String in RIG:
			check(not _part(low, part_name).is_empty(), "missing %s/%s" % [
					chassis, part_name])
		if high.has("source"):
			check_eq(high["source"], "res://data/voxels/%s_shape.json" % chassis,
					"unexpected detailed source for %s" % chassis)
		else:
			check_eq(high["unit"], low["unit"], "different model tiers: %s" % chassis)


func test_primary_contours_remain_valid_volumes() -> void:
	for chassis: String in CHASSIS:
		var low := _read(chassis, "_shape")
		for part_name: String in PRIMARY:
			var loft := _loft(_part(low, part_name))
			check(not loft.is_empty(), "missing principal loft %s/%s" % [
					chassis, part_name])
			for sec: Dictionary in loft.get("sections", []):
				var polygon: Array = sec.get("polygon", [])
				check(polygon.size() >= 3, "incomplete cross-section %s/%s" % [
						chassis, part_name])
				if polygon.size() < 3:
					continue
				var area := 0.0
				for i in polygon.size():
					var a: Array = polygon[i]
					var b: Array = polygon[(i + 1) % polygon.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed cross-section %s/%s" % [
						chassis, part_name])


func test_quads_remain_four_legged_with_joint_children() -> void:
	for chassis: String in QUADS:
		for suffix: String in ["_shape", ""]:
			var data := _read(chassis, suffix)
			check_eq(bool(data.get("quad", false)), true,
					"four-legged rig lost %s%s" % [chassis, suffix])
			for name: String in ["la", "la_shin", "la_foot", "ra", "ra_shin",
					"ra_foot", "ll", "ll_shin", "ll_foot", "rl", "rl_shin",
					"rl_foot"]:
				check(not _part(data, name).is_empty(), "lost quad chain %s/%s" % [
					chassis, name])


func test_scouts_keep_digitigrade_legs() -> void:
	for chassis: String in ["shockwave", "snake", "talon", "tsunami"]:
		check_eq(_read(chassis, "_shape")["legs"], "digitigrade",
				"scout gait changed %s" % chassis)
