extends TestCase
## Fourth 20-chassis reference geometry batch, including real four-legged models.

const CHASSIS := [
	"goliath", "scorpion", "rakshasa", "warlord", "chameleon",
	"cobra", "hornet", "imp", "nightstar", "pillager",
	"salamander", "shogun", "thug", "titan", "turkina",
	"executioner", "nova", "summoner", "hellbringer", "dire_wolf"
]


func _recipe(chassis: String, tier: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, tier])


func _part(data: Dictionary, name: String) -> Dictionary:
	for part: Dictionary in data.get("parts", []):
		if part.get("name", "") == name:
			return part
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_reference_contours_match_resolution_sources() -> void:
	for chassis: String in CHASSIS:
		var shape := _recipe(chassis, "_shape")
		var detailed := _recipe(chassis, "")
		if detailed.has("source"):
			check_eq(detailed["source"], "res://data/voxels/%s_shape.json" % chassis,
					"alias no longer shares sculpt %s" % chassis)
			continue
		check_eq(shape["unit"], detailed["unit"], "different designs %s" % chassis)
		for part_name: String in ["ct", "lt", "ll_shin"]:
			var low := _loft(_part(shape, part_name))
			var high := _loft(_part(detailed, part_name))
			check(not low.is_empty() and not high.is_empty(),
					"missing anatomical loft %s/%s" % [chassis, part_name])
			check(low == high, "resolution-specific skeleton %s/%s" % [
					chassis, part_name])


func test_primitive_profiles_are_closed_nonzero_cross_sections() -> void:
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		for part_name: String in ["ct", "lt", "ll_shin"]:
			var loft := _loft(_part(data, part_name))
			check(not loft.is_empty(), "missing profile %s/%s" % [chassis, part_name])
			for sec: Dictionary in loft.get("sections", []):
				var points: Array = sec.get("polygon", [])
				check(points.size() >= 3, "not a polygon %s/%s" % [chassis, part_name])
				if points.size() < 3:
					continue
				var area := 0.0
				for i in points.size():
					var a: Array = points[i]
					var b: Array = points[(i + 1) % points.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed loft %s/%s" % [
						chassis, part_name])


func test_quad_limb_rigs_remain_four_legged_and_separate() -> void:
	for chassis: String in ["goliath", "scorpion"]:
		var recipe := _recipe(chassis, "_shape")
		for name: String in ["la", "la_shin", "la_foot", "ra", "ra_shin",
				"ra_foot", "ll", "ll_shin", "ll_foot", "rl", "rl_shin", "rl_foot"]:
			check(not _part(recipe, name).is_empty(),
					"lost load-bearing leg %s/%s" % [chassis, name])


func test_clan_gaits_and_independent_gun_housings_survive() -> void:
	for chassis: String in ["rakshasa", "hornet", "nightstar", "turkina",
			"nova", "summoner", "hellbringer"]:
		check_eq(_recipe(chassis, "_shape")["legs"], "digitigrade",
				"reverse-knee signature lost %s" % chassis)
	for spec: Dictionary in [
		{"chassis": "rakshasa", "part": "la_rotary"},
		{"chassis": "warlord", "part": "ct_housing"},
		{"chassis": "cobra", "part": "la_housing"},
		{"chassis": "imp", "part": "ra_lrm"},
		{"chassis": "salamander", "part": "lt_housing"},
		{"chassis": "titan", "part": "lt_housing"}
	]:
		check(not _part(_recipe(spec["chassis"], "_shape"), spec["part"]).is_empty(),
				"distinctive weapon body erased: %s/%s" % [
					spec["chassis"], spec["part"]])
