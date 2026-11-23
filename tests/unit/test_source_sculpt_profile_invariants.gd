extends TestCase
## Relative silhouette tests, not hard-coded authoring coordinates.
## These catch regressions toward generic upright bodies while remaining
## indifferent to voxel size, posing, and future refactoring of the outlines.


static func _source(chassis: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/" + chassis + ".json")


static func _part(data: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in data.get("parts", []):
		if String(p.get("name", "")) == name:
			return p
	return {}


static func _extent(part: Dictionary, axis: int, maximum: bool) -> float:
	var result := -INF if maximum else INF
	for s: Dictionary in part.get("shapes", []):
		if s.has("box"):
			var endpoints: Array = s["box"]
			var value: float = float(endpoints[1 if maximum else 0][axis])
			result = maxf(result, value) if maximum else minf(result, value)
		elif s.has("loft"):
			var loft: Dictionary = s["loft"]
			if String(loft.get("axis", "y")) != "y":
				continue
			for section: Dictionary in loft.get("sections", []):
				if axis == 1:
					var station: float = float(section["at"])
					result = maxf(result, station) if maximum else minf(result, station)
				elif axis == 0 or axis == 2:
					var index: int = 0 if axis == 0 else 1
					for corner: Array in section["polygon"]:
						var side: float = float(corner[index])
						result = maxf(result, side) if maximum else minf(result, side)
	return result


func test_koshi_dorsal_open_ducts_overtop_cockpit() -> void:
	var d := _source("koshi_standard")
	var intake := _part(d, "lt")
	var head := _part(d, "hd")
	check(_extent(intake, 1, true) > _extent(head, 1, true),
		"Koshi source radiator towers rise above the round cockpit")
	var cutouts := 0
	for s: Dictionary in intake["shapes"]:
		if s.has("erase"):
			cutouts += 1
	check(cutouts >= 2, "both vertical gaps in each mirrored intake are cut open")


func test_vulture_mk_iv_beak_and_arm_nacelles_project_well_ahead_of_torso() -> void:
	var d := _source("vulture_mk_iv")
	var core := _part(d, "ct")
	var front: float = _extent(core, 2, false)
	var head: float = _extent(_part(d, "hd"), 2, false)
	check(head < front, "cockpit projects ahead of core instead of a flat head")
	for arm in ["la", "ra"]:
		check(_extent(_part(d, arm), 2, false) < front,
			arm + " gun extends beyond belly without a deep torso slab")


func test_hawkwolf_racks_are_truly_raked_not_upright_boxes() -> void:
	var d := _source("hawkwolf_hwk4f")
	for arm in ["la", "ra"]:
		var p := _part(d, arm)
		var first: Dictionary = p["shapes"][1]["loft"]["sections"][0]
		var last: Dictionary = p["shapes"][1]["loft"]["sections"][-1]
		var bottom_front := INF
		var top_front := INF
		for point: Array in first["polygon"]:
			bottom_front = minf(bottom_front, float(point[1]))
		for point: Array in last["polygon"]:
			top_front = minf(top_front, float(point[1]))
		check(bottom_front < top_front,
			arm + " launcher noses must rake forward below the shoulders")
		var holes := 0
		for s: Dictionary in p["shapes"]:
			if s.has("erase"):
				holes += 1
		check_eq(holes, 15, "15 physical bores on each HawkWolf arm")


func test_solitaire_dorsal_housing_and_heterogeneous_profiles() -> void:
	var d := _source("solitaire")
	check(_extent(_part(d, "lt"), 1, true) > _extent(_part(d, "ct"), 1, true),
		"elevated offset dorsal hull remains visible above shoulder-level torso")
	var v := _source("dominator")
	check(_extent(_part(v, "ra"), 2, false) < _extent(_part(v, "la"), 2, false),
		"Dominator long PPC has a different profile than the left fist")
	var c := _source("hellhound_conjurer")
	check(_extent(_part(c, "ra"), 2, false) < _extent(_part(c, "la"), 2, false),
		"Conjurer right gun and left hand are not indistinguishable clones")


func test_new_chassis_bores_remain_physical_after_resculpt() -> void:
	for id in ["vulture_mk_iv", "koshi_standard", "hawkwolf_hwk4f",
			"hellhound_conjurer", "dominator"]:
		var d := _source(id)
		d["subdivide"] = 1
		var m := VxModel.from_dict(d)
		check(m.errors.is_empty(), id + " has valid source geometry")
		check_eq(int(m.quality_report.get("floating_islands", -1)), 0,
			id + " must not add floating detail islands")


func test_black_hawk_standard_has_higher_split_shoulders_than_head() -> void:
	var d := _source("black_hawk_standard")
	check(_extent(_part(d, "lt"), 1, true) > _extent(_part(d, "hd"), 1, true),
		"Black Hawk Standard shoulders frame a low inset pilot, not a generic head atop the shoulders")
	var right: Dictionary = _part(d, "rt")
	check_eq(String(right.get("mirror", "")), "lt",
		"new shoulder mass is reflected as a matched independent moving part")
