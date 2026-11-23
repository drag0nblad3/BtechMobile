extends TestCase
## Source-level anatomy parity and loadable rigs for reference-led silhouette sculpts.

const PAIRED := ["firestarter", "battleaxe", "sagittaire", "rifleman", "griffin"]
const SHAPE_ONLY := ["wolverine"]
const PRIMARY := ["ct", "lt", "la"]


func _data(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(data: Dictionary, name: String) -> Dictionary:
	for part: Dictionary in data.get("parts", []):
		if part.get("name", "") == name:
			return part
	return {}


func _first_loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_low_and_detailed_reference_anatomy_agree() -> void:
	for chassis: String in PAIRED:
		var low := _data(chassis, "_shape")
		var high := _data(chassis, "")
		for part_name: String in PRIMARY:
			var a := _first_loft(_part(low, part_name))
			var b := _first_loft(_part(high, part_name))
			check(not a.is_empty(), "%s missing %s low-res loft" % [chassis, part_name])
			check(not b.is_empty(), "%s missing %s detailed loft" % [chassis, part_name])
			check(a == b, "anatomical contour drift: %s/%s" % [chassis, part_name])


func test_refined_recipes_load_with_all_animated_locations() -> void:
	for chassis: String in PAIRED + SHAPE_ONLY:
		var suffixes := ["_shape"] if chassis in SHAPE_ONLY else ["_shape", ""]
		for suffix: String in suffixes:
			var data := _data(chassis, suffix)
			data["subdivide"] = 1
			var model := VxModel.from_dict(data)
			check(model.errors.is_empty(), "recipe errors for %s%s: %s" % [
				chassis, suffix, model.errors])
			for loc in Location.COUNT:
				check(not model.parts_at(loc).is_empty(), "%s%s missing location %s" % [
					chassis, suffix, Location.code(loc)])


func test_battleaxe_right_side_has_no_second_long_shield() -> void:
	for suffix: String in ["_shape", ""]:
		var rt := _part(_data("battleaxe", suffix), "rt")
		for shape: Dictionary in rt.get("add", []):
			if not shape.has("box") or shape.get("mat", "") != "plate":
				continue
			var bounds: Array = shape["box"]
			var depth := absf(float(bounds[1][2]) - float(bounds[0][2]))
			var width := absf(float(bounds[1][0]) - float(bounds[0][0]))
			check(depth <= maxf(width * 1.5, 6.0), "right-side armor is a long protruding shield")
