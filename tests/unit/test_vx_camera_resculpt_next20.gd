extends TestCase
## Source-paired contour and rig checks for camera-triaged resculpt batch 2.

const SCULPTED := {
	"turkina": [
		"ll",
		"ll_shin"
	],
	"crossbow": [
		"ll",
		"ll_shin"
	],
	"hunchback_iic": [
		"ct",
		"lt"
	],
	"uziel": [
		"ct",
		"lt",
		"rt"
	],
	"cyclops": [
		"ct",
		"lt"
	],
	"jagermech": [
		"ct",
		"lt"
	],
	"dragon_fire": [
		"ct",
		"lt",
		"rt"
	],
	"nightstar": [
		"ll",
		"ll_shin"
	],
	"charger": [
		"ll",
		"ll_shin"
	],
	"highlander_iic": [
		"ct",
		"lt",
		"rt"
	],
	"banshee": [
		"ll",
		"ll_shin"
	],
	"warhammer": [
		"ct"
	],
	"ostsol": [
		"ct",
		"lt"
	],
	"victor": [
		"ll",
		"ll_shin"
	],
	"devastator": [
		"ll",
		"ll_shin"
	],
	"pillager": [
		"ll",
		"ll_shin"
	],
	"enforcer": [
		"ll",
		"ll_shin"
	],
	"annihilator": [
		"ll",
		"ll_shin"
	],
	"argus": [
		"ct",
		"lt"
	],
	"archer": [
		"ct"
	]
}


func _recipe(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(d: Dictionary, part_name: String) -> Dictionary:
	for p: Dictionary in d.get("parts", []):
		if p.get("name", "") == part_name:
			return p
	return {}


func _primary_loft(p: Dictionary) -> Dictionary:
	for shape: Dictionary in p.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func _signed_area(points: Array) -> float:
	var sum_area := 0.0
	for i: int in range(points.size()):
		var a: Array = points[i]
		var b: Array = points[(i + 1) % points.size()]
		sum_area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
	return 0.5 * sum_area


func test_low_and_detailed_tiers_keep_identical_modified_lofts() -> void:
	for chassis: String in SCULPTED:
		var lo := _recipe(chassis, "_shape")
		var hi := _recipe(chassis, "")
		check_eq(lo.get("unit", ""), hi.get("unit", ""), "wrong paired unit %s" % chassis)
		check_eq(lo.get("legs", ""), hi.get("legs", ""), "altered leg mode %s" % chassis)
		for name: String in SCULPTED[chassis]:
			var a := _primary_loft(_part(lo, name))
			var b := _primary_loft(_part(hi, name))
			check(not a.is_empty(), "missing source loft %s/%s" % [chassis, name])
			check_eq(a, b, "source/detail mismatch %s/%s" % [chassis, name])


func test_modified_lofts_have_strict_stations_and_solid_contours() -> void:
	for chassis: String in SCULPTED:
		var data := _recipe(chassis, "_shape")
		for name: String in SCULPTED[chassis]:
			var loft := _primary_loft(_part(data, name))
			if loft.is_empty():
				continue
			check_eq(loft.get("axis", ""), "y", "wrong sculpt axis %s/%s" % [
					chassis, name])
			var prior := -INF
			var first_winding := 0.0
			for station: Dictionary in loft["sections"]:
				var at := float(station["at"])
				check(at > prior, "out-of-order loft height %s/%s" % [
						chassis, name])
				prior = at
				var polygon: Array = station["polygon"]
				check(polygon.size() >= 3, "empty cross-section %s/%s" % [
						chassis, name])
				var signed_area := _signed_area(polygon)
				check(absf(signed_area) > 0.1, "collapsed loft %s/%s" % [
						chassis, name])
				if first_winding != 0.0:
					check(first_winding * signed_area > 0.0,
							"reversed polygon winding %s/%s" % [chassis, name])
				first_winding = signed_area


func test_resculpted_source_recipes_load_all_animated_hit_locations() -> void:
	for chassis: String in SCULPTED:
		var source := _recipe(chassis, "_shape")
		source["subdivide"] = 1
		var model := VxModel.from_dict(source)
		check(model.errors.is_empty(), "load errors %s: %s" % [
				chassis, model.errors])
		for loc in Location.COUNT:
			check(not model.parts_at(loc).is_empty(),
					"missing hit location %s in %s" % [
							Location.code(loc), chassis])


func test_no_reused_mirror_target_or_unparented_mirrored_arms() -> void:
	for chassis: String in SCULPTED:
		var source := _recipe(chassis, "_shape")
		var names := {}
		for p: Dictionary in source.get("parts", []):
			var name: String = str(p.get("name", ""))
			check(not names.has(name), "duplicate part %s/%s" % [chassis, name])
			names[name] = true
		for p: Dictionary in source.get("parts", []):
			var source_part: String = str(p.get("mirror", ""))
			if source_part != "":
				check(names.has(source_part),
						"dangling mirrored part %s/%s" % [chassis, p.get("name", "")])
