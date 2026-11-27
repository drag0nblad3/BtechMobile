extends TestCase
## Shared shape/detail, loft, and articulated-rig contracts for 260 sculpts.

const MANIFEST := "res://tests/fixtures/voxel_reference_cohorts.json"
const RIG := ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]


func _cohorts() -> Array:
	return VxRecipeStore.read(MANIFEST).get("cohorts", [])


func _path(chassis: String, tier: String) -> String:
	return "res://data/voxels/%s%s.json" % [chassis, tier]


func _data(chassis: String, tier: String) -> Dictionary:
	return VxRecipeStore.read(_path(chassis, tier))


func _part(data: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in data.get("parts", []):
		if p.get("name", "") == name:
			return p
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_every_registered_source_is_present_once() -> void:
	var seen := {}
	for cohort: Dictionary in _cohorts():
		for chassis: String in cohort["models"]:
			check(not seen.has(chassis), "duplicate reference cohort %s" % chassis)
			seen[chassis] = true
			check(VxRecipeStore.exists(_path(chassis, "_shape")),
					"missing source profile %s" % chassis)
	check_eq(seen.size(), 260, "13 historical batches accounted for")


func test_primary_lofts_are_valid_volumes_in_every_cohort() -> void:
	for cohort: Dictionary in _cohorts():
		var area_min := float(cohort.get("areaMin", 0.01))
		for chassis: String in cohort["models"]:
			var low := _data(chassis, "_shape")
			for name: String in cohort.get("areaParts", cohort["primary"]):
				var loft := _loft(_part(low, name))
				check(not loft.is_empty(), "missing loft %s/%s" % [chassis, name])
				if loft.is_empty():
					continue
				if bool(cohort.get("axes", false)):
					check_eq(loft.get("axis", ""), "y", "incorrect loft axis %s/%s" % [chassis, name])
				for section: Dictionary in loft.get("sections", []):
					var poly: Array = section.get("polygon", [])
					check(poly.size() >= 3, "short profile %s/%s" % [chassis, name])
					if poly.size() < 3:
						continue
					var twice_area := 0.0
					for i in poly.size():
						var a: Array = poly[i]
						var b: Array = poly[(i + 1) % poly.size()]
						twice_area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
					check(absf(twice_area) * 0.5 > area_min * 0.5,
							"collapsed profile %s/%s" % [chassis, name])


func test_authored_detail_tiers_retain_primary_anatomy() -> void:
	for cohort: Dictionary in _cohorts():
		for chassis: String in cohort["models"]:
			if chassis in cohort.get("shapeOnly", []):
				continue
			check(VxRecipeStore.exists(_path(chassis, "")), "missing detailed tier %s" % chassis)
			var low := _data(chassis, "_shape")
			var high := _data(chassis, "")
			if high.has("source"):
				check_eq(high["source"], _path(chassis, "_shape"),
						"detail alias drift %s" % chassis)
				continue
			if chassis in cohort.get("independent", []):
				check(not high.has("source"), "independent detail lost %s" % chassis)
				continue
			check_eq(high.get("unit"), low.get("unit"), "design drift %s" % chassis)
			check_eq(high.get("legs"), low.get("legs"), "gait tier drift %s" % chassis)
			if bool(cohort.get("muzzles", false)):
				check_eq(high.get("muzzles", {}), low.get("muzzles", {}),
						"weapon sockets drift %s" % chassis)
			for name: String in cohort["primary"]:
				var a := _loft(_part(low, name))
				var b := _loft(_part(high, name))
				check(not a.is_empty() and not b.is_empty(),
						"missing paired contour %s/%s" % [chassis, name])
				check_eq(a, b, "sculpt tier mismatch %s/%s" % [chassis, name])


func test_animated_rigs_and_weapons_remain_separate() -> void:
	for cohort: Dictionary in _cohorts():
		for chassis: String in cohort["models"]:
			var low := _data(chassis, "_shape")
			for name: String in RIG:
				check(not _part(low, name).is_empty(),
						"missing articulated joint %s/%s" % [chassis, name])
			if bool(cohort.get("weapons", false)):
				check(not low.get("weapons", []).is_empty(), "weapons removed %s" % chassis)


func test_original_hit_location_models_still_load() -> void:
	for cohort: Dictionary in _cohorts():
		if not bool(cohort.get("load", false)):
			continue
		for chassis: String in cohort["models"]:
			var tiers := ["_shape"] if chassis in cohort.get("shapeOnly", []) else ["_shape", ""]
			for tier: String in tiers:
				var raw := _data(chassis, tier)
				raw["subdivide"] = 1
				var m := VxModel.from_dict(raw)
				check(m.errors.is_empty(), "model load errors %s%s: %s" % [
						chassis, tier, m.errors])
				for loc in Location.COUNT:
					check(not m.parts_at(loc).is_empty(),
							"missing damageable %s on %s%s" % [Location.code(loc), chassis, tier])
