extends TestCase
## Eight twenty-chassis imported-model source sculpt regression checks.

const CHASSIS := [
	"hound", "initiate", "jackal", "jackrabbit", "jagermech_iii",
	"juggernaut", "kabuto", "koschei", "koto", "lightray",
	"lineholder", "lynx", "marshal", "nexus", "night_hawk",
	"onslaught", "orochi", "phoenix", "raijin", "rampage"
]


func _source(chassis: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s_shape.json" % chassis)


func _part(data: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in data.get("parts", []):
		if p.get("name", "") == name:
			return p
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for s: Dictionary in part.get("shapes", []):
		if s.has("loft"):
			return s["loft"]
	return {}


func test_detailed_models_share_the_original_source_contours() -> void:
	for chassis: String in CHASSIS:
		var high: Dictionary = JsonFile.read("res://data/voxels/%s.json" % chassis)
		if high.has("source"):
			check_eq(high["source"], "res://data/voxels/%s_shape.json" % chassis,
					"source alias broken: %s" % chassis)
		else:
			check_eq(high["unit"], _source(chassis)["unit"],
					"detailed design points elsewhere: %s" % chassis)
			for name: String in ["ct", "la", "ll_shin"]:
				check(_loft(_part(high, name)) == _loft(_part(_source(chassis), name)),
						"source loft mismatch: %s/%s" % [chassis, name])


func test_primary_cross_sections_stay_nonzero_area() -> void:
	for chassis: String in CHASSIS:
		var data := _source(chassis)
		for name: String in ["ct", "la", "ll_shin"]:
			var loft := _loft(_part(data, name))
			check(not loft.is_empty(), "missing sculpt %s/%s" % [chassis, name])
			for sec: Dictionary in loft.get("sections", []):
				var points: Array = sec.get("polygon", [])
				check(points.size() >= 3, "invalid ring %s/%s" % [chassis, name])
				if points.size() < 3:
					continue
				var area := 0.0
				for i in points.size():
					var a: Array = points[i]
					var b: Array = points[(i + 1) % points.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed cross section %s/%s" % [
						chassis, name])


func test_rare_shoulder_shell_and_digitigrade_gait_survive() -> void:
	# Jackrabbit has a shell+frame shoulder, not a generic LT loft.
	var shoulder := _part(_source("jackrabbit"), "lt")
	var found_shell := false
	for s: Dictionary in shoulder.get("shapes", []):
		if s.has("shell"):
			found_shell = true
	check(found_shell, "Jackrabbit's LT shell replaced with a generic hull")
	for chassis: String in ["jackal", "nexus", "phoenix"]:
		check_eq(_source(chassis)["legs"], "digitigrade",
				"reverse-jointed rig lost: %s" % chassis)


func test_animations_keep_eight_independent_hit_locations() -> void:
	for chassis: String in CHASSIS:
		var source := _source(chassis)
		for loc: String in ["hd", "ct", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not _part(source, loc).is_empty(),
					"missing articulated part %s/%s" % [chassis, loc])
