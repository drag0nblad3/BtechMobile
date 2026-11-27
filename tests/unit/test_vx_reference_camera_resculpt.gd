extends TestCase
## Camera-aware source resculpt safety guards for six P1 BattleMechs.

const CHASSIS := {
	"blackjack": ["ct", "lt", "la"],
	"crusader": ["ct", "lt", "la"],
	"rifleman": ["ct", "lt", "la"],
	"phoenix_hawk": ["ct", "ll", "ll_shin"],
	"trebuchet": ["ct", "lt", "la"],
	"locust": ["ct", "lt", "la"],
}


func _recipe(chassis: String, suffix: String) -> Dictionary:
	return VxRecipeStore.read("res://data/voxels/%s%s.json" % [chassis, suffix])


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


func _signed_area(points: Array) -> float:
	var twice := 0.0
	for i: int in range(points.size()):
		var a: Array = points[i]
		var b: Array = points[(i + 1) % points.size()]
		twice += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
	return 0.5 * twice


func test_sculpted_sections_match_between_quality_tiers() -> void:
	for chassis: String in CHASSIS:
		var low := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		check_eq(low["unit"], high["unit"], "variant changed for %s" % chassis)
		check_eq(low["legs"], high["legs"], "leg rig changed for %s" % chassis)
		for part_name: String in CHASSIS[chassis]:
			var lo := _loft(_part(low, part_name))
			var hi := _loft(_part(high, part_name))
			check(not lo.is_empty(), "missing shape loft %s/%s" % [chassis, part_name])
			check_eq(lo, hi, "low/detail contour drift %s/%s" % [chassis, part_name])


func test_all_sculpted_lofts_keep_winding_and_full_stations() -> void:
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		for part_name: String in CHASSIS[chassis]:
			var loft := _loft(_part(data, part_name))
			if loft.is_empty():
				continue
			var previous_at := -INF
			var winding := 0.0
			for section: Dictionary in loft["sections"]:
				var at := float(section["at"])
				check(at > previous_at, "unsorted loft station %s/%s" % [
						chassis, part_name])
				previous_at = at
				var points: Array = section["polygon"]
				check(points.size() >= 3, "collapsed contour %s/%s" % [
						chassis, part_name])
				var area := _signed_area(points)
				check(absf(area) > 0.1, "degenerate contour %s/%s" % [
						chassis, part_name])
				if winding != 0.0:
					check(area * winding > 0.0, "flipped winding %s/%s" % [
							chassis, part_name])
				winding = area


func test_camera_resculpts_preserve_animated_parts_and_hits() -> void:
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		data["subdivide"] = 1
		var model := VxModel.from_dict(data)
		check(model.errors.is_empty(), "model load failed %s: %s" % [
				chassis, model.errors])
		for loc in Location.COUNT:
			check(not model.parts_at(loc).is_empty(),
					"missing location %s for %s" % [Location.code(loc), chassis])
		var joints := VxConnectivity.audit(model)
		check(joints["pass"], "unsupported joint or island %s: %s" % [
				chassis, joints["faults"]])
