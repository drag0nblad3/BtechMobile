extends TestCase
## Third reference-sculpt batch: source parity and distinctive geometry survival.

const CHASSIS := [
	"axman", "wolfhound", "hermes_ii", "sentinel", "panther",
	"wasp", "stinger", "firefly", "mercury", "mongoose",
	"vulcan", "hatchetman", "wraith", "watchman", "crab",
	"exterminator", "zeus", "victor", "flashman", "guillotine"
]


func _load(chassis: String, tier: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, tier])


func _part(recipe: Dictionary, part_name: String) -> Dictionary:
	for p: Dictionary in recipe.get("parts", []):
		if p.get("name", "") == part_name:
			return p
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for s: Dictionary in part.get("shapes", []):
		if s.has("loft"):
			return s["loft"]
	return {}


func test_refined_chassis_primary_lofts_are_paired_or_explicitly_sourced() -> void:
	for chassis: String in CHASSIS:
		var shape := _load(chassis, "_shape")
		var high := _load(chassis, "")
		if high.has("source"):
			check_eq(high["source"], "res://data/voxels/%s_shape.json" % chassis,
					"wrong high-resolution source: %s" % chassis)
			continue
		check_eq(high["unit"], shape["unit"], "different units %s" % chassis)
		for name: String in ["ct", "lt", "la", "ll_shin"]:
			var a := _loft(_part(shape, name))
			var b := _loft(_part(high, name))
			check(not a.is_empty() and not b.is_empty(), "missing loft %s/%s" % [
					chassis, name])
			check(a == b, "high/low silhouette differs %s/%s" % [chassis, name])


func test_source_lofts_remain_bounded_and_have_real_cross_sections() -> void:
	for chassis: String in CHASSIS:
		var data := _load(chassis, "_shape")
		for name: String in ["ct", "lt", "la", "ll_shin"]:
			var loft := _loft(_part(data, name))
			check(not loft.is_empty(), "lost sculpt primitive %s/%s" % [
					chassis, name])
			for sec: Dictionary in loft.get("sections", []):
				var polygon: Array = sec.get("polygon", [])
				check(polygon.size() >= 3, "too few vertices %s/%s" % [
						chassis, name])
				if polygon.size() < 3:
					continue
				var area := 0.0
				for i in polygon.size():
					var a: Array = polygon[i]
					var b: Array = polygon[(i + 1) % polygon.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed loft %s/%s" % [chassis, name])


func test_melee_and_cannon_components_are_not_replaced_with_generic_arms() -> void:
	for chassis: String in ["axman", "hatchetman"]:
		var data := _load(chassis, "_shape")
		var axe_arm := _part(data, "ra")
		check(axe_arm.has("mirror"), "missing melee arm rig: %s" % chassis)
		check(not axe_arm.get("add", []).is_empty(),
				"missing right-hand axe tool geometry: %s" % chassis)
	var panther_recipe := _load("panther", "_shape")
	var panther_arm := _part(panther_recipe, "ra")
	var panther_ppc := _part(panther_recipe, "ra_ppc")
	check(not panther_arm.get("add", []).is_empty() or not panther_ppc.is_empty(),
			"lost Panther right-arm PPC")
	if not panther_ppc.is_empty():
		check_eq(panther_ppc.get("parent", ""), "ra",
				"independent PPC must still animate with the right arm")
		check(not panther_ppc.get("shapes", []).is_empty(),
				"independent PPC retains physical barrel geometry")
	var crab := _load("crab", "_shape")
	check(not _part(crab, "la").is_empty() and not _part(crab, "ra").is_empty(),
			"lost Crab paired claw hands")


func test_all_chassis_keep_eight_animated_hit_locations() -> void:
	for chassis: String in CHASSIS:
		var data := _load(chassis, "_shape")
		for name: String in ["hd", "ct", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not _part(data, name).is_empty(),
					"lost articulated location %s/%s" % [chassis, name])
