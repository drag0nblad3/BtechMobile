extends TestCase
## Distinct body profiles in the second 20-chassis imported model cohort.

const CHASSIS := [
	"jenner_iic", "jinggau", "kingfisher", "locust_iic", "mad_cat_mk_ii",
	"marauder_ii", "peacekeeper", "raptor", "rattlesnake", "rattlesnake_ii",
	"shadow_hawk_iic", "shiro", "stealth", "sunder", "tempest",
	"templar", "thunder", "thunderbolt_iic", "tian_zong", "tiburon"
]
const SCULPT := ["ct", "lt", "rt", "la", "ra"]


func _recipe(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


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


func test_imported_model_tiers_have_identical_primary_contours() -> void:
	for chassis: String in CHASSIS:
		var low := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		check_eq(low["unit"], high["unit"], "wrong unit %s" % chassis)
		check_eq(low["legs"], high["legs"], "rig gait mismatch %s" % chassis)
		check(low.get("muzzles", {}) == high.get("muzzles", {}),
				"changed muzzle positions between tiers %s" % chassis)
		for name: String in SCULPT:
			var a := _loft(_part(low, name))
			var b := _loft(_part(high, name))
			check(not a.is_empty() and not b.is_empty(), "missing %s/%s" % [
					chassis, name])
			check(a == b, "wrong sculpt tier %s/%s" % [chassis, name])


func test_imported_model_lofts_have_nonzero_area() -> void:
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		for name: String in SCULPT:
			var loft := _loft(_part(data, name))
			check_eq(loft.get("axis", ""), "y", "wrong axis %s/%s" % [chassis, name])
			for sec: Dictionary in loft.get("sections", []):
				var pts: Array = sec.get("polygon", [])
				check(pts.size() >= 3, "invalid polygon %s/%s" % [chassis, name])
				if pts.size() < 3:
					continue
				var area := 0.0
				for i in pts.size():
					var a: Array = pts[i]
					var b: Array = pts[(i + 1) % pts.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.02, "collapsed armor loft %s/%s" % [
						chassis, name])


func test_imported_models_keep_hit_location_rigs_and_recon_legs() -> void:
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		for name: String in ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not _part(data, name).is_empty(), "missing animated part %s/%s" % [
					chassis, name])
	for chassis: String in ["jenner_iic", "locust_iic", "mad_cat_mk_ii",
			"raptor", "rattlesnake", "stealth", "tiburon"]:
		check_eq(_recipe(chassis, "_shape")["legs"], "digitigrade",
				"lost digitigrade leg setup: %s" % chassis)
