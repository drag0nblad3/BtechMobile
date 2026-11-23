extends TestCase
## The second 20-chassis sculpt batch must retain loft anatomy and animated rigs.

const CHASSIS := [
	"assassin", "blackjack", "bushwacker", "charger", "cicada",
	"clint", "crusader", "dervish", "grasshopper", "kintaro",
	"ostsol", "ostroc", "cyclops", "hatamoto_chi", "mauler",
	"raven", "cataphract", "spider", "whitworth", "hussar"
]
const RIG_PARTS := ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]


func _data(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(recipe: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in recipe.get("parts", []):
		if p.get("name", "") == name:
			return p
	return {}


func _primary_loft(part: Dictionary) -> Dictionary:
	for s: Dictionary in part.get("shapes", []):
		if s.has("loft"):
			return s["loft"]
	return {}


func test_refined_lofts_are_shared_by_coarse_and_detailed_sources() -> void:
	for chassis: String in CHASSIS:
		var coarse := _data(chassis, "_shape")
		var detailed := _data(chassis, "")
		if detailed.has("source"):
			check_eq(detailed["source"], "res://data/voxels/%s_shape.json" % chassis,
					"unexpected alias %s" % chassis)
			continue
		check_eq(coarse["unit"], detailed["unit"], "design ID changed %s" % chassis)
		for part_name: String in ["ct", "lt", "la", "ll_shin"]:
			var a := _primary_loft(_part(coarse, part_name))
			var b := _primary_loft(_part(detailed, part_name))
			check(not a.is_empty() and not b.is_empty(),
					"tier is missing %s for %s" % [part_name, chassis])
			check(a == b, "source geometry mismatch: %s/%s" % [chassis, part_name])


func test_refined_anatomy_keeps_rig_and_has_finite_polygon_area() -> void:
	for chassis: String in CHASSIS:
		var data := _data(chassis, "_shape")
		for name: String in RIG_PARTS:
			check(not _part(data, name).is_empty(), "missing joint %s/%s" % [
					chassis, name])
		for name: String in ["ct", "lt", "la", "ll_shin"]:
			var loft := _primary_loft(_part(data, name))
			check(not loft.is_empty(), "missing core volume %s/%s" % [chassis, name])
			for section: Dictionary in loft.get("sections", []):
				var points: Array = section.get("polygon", [])
				check(points.size() >= 3, "underdefined profile %s/%s" % [chassis, name])
				if points.size() < 3:
					continue
				var area := 0.0
				for i in points.size():
					var a: Array = points[i]
					var b: Array = points[(i + 1) % points.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed profile %s/%s" % [chassis, name])


func test_recon_digitigrade_and_named_weapon_components_persist() -> void:
	for chassis: String in ["cicada", "raven", "hussar"]:
		check_eq(_data(chassis, "_shape")["legs"], "digitigrade",
				"digitigrade gait changed: %s" % chassis)
	for suffix: String in ["_shape", ""]:
		var recipe := _data("hussar", suffix)
		if recipe.has("source"):
			continue
		check(not _part(recipe, "ct_laser").is_empty(),
				"Hussar front laser pod disconnected from recipe")
		check(not _part(recipe, "ll_tarsus").is_empty(),
				"Hussar leg assembly lost")
