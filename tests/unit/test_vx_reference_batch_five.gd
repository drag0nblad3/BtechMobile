extends TestCase
## Fifth twenty-chassis source geometry refinement, predominantly Clan silhouettes.

const CHASSIS := [
	"adder", "kit_fox", "fire_moth", "ice_ferret", "stormcrow",
	"shadow_cat", "gargoyle", "warhawk", "crossbow", "mad_dog",
	"viper", "mist_lynx", "grendel", "piranha", "night_gyr",
	"linebacker", "hunchback_iic", "supernova", "howler", "ostscout"
]
const PLANTIGRADE := ["night_gyr", "hunchback_iic", "supernova", "ostscout"]


func _recipe(chassis: String, tier: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, tier])


func _part(data: Dictionary, part_name: String) -> Dictionary:
	for part: Dictionary in data.get("parts", []):
		if part.get("name", "") == part_name:
			return part
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_edited_resolution_tiers_share_anatomical_section_data() -> void:
	for chassis: String in CHASSIS:
		var low := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		check_eq(low["unit"], high["unit"], "different model designs: %s" % chassis)
		for name: String in ["ct", "lt", "la", "ll_shin"]:
			var first := _loft(_part(low, name))
			var second := _loft(_part(high, name))
			check(not first.is_empty() and not second.is_empty(),
					"missing authored geometry %s/%s" % [chassis, name])
			check(first == second, "silhouette differs across tiers %s/%s" % [
					chassis, name])


func test_light_and_heavy_chassis_keep_their_individual_gaits() -> void:
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		var expected := "plantigrade" if chassis in PLANTIGRADE else "digitigrade"
		check_eq(data["legs"], expected, "wrong gait %s" % chassis)
		if expected == "digitigrade":
			for name: String in ["ll", "ll_shin", "ll_tarsus", "ll_foot",
					"rl", "rl_shin", "rl_tarsus", "rl_foot"]:
				check(not _part(data, name).is_empty(),
						"missing articulated reverse-knee part %s/%s" % [
								chassis, name])


func test_polygons_are_valid_without_collapsing_voxel_sculpt_sections() -> void:
	for chassis: String in CHASSIS:
		var data := _recipe(chassis, "_shape")
		for part_name: String in ["ct", "lt", "la", "ll_shin"]:
			var loft := _loft(_part(data, part_name))
			for section: Dictionary in loft.get("sections", []):
				var points: Array = section.get("polygon", [])
				check(points.size() >= 3, "bad polygon %s/%s" % [chassis, part_name])
				if points.size() < 3:
					continue
				var area := 0.0
				for i in points.size():
					var a: Array = points[i]
					var b: Array = points[(i + 1) % points.size()]
					area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
				check(absf(area) > 0.01, "collapsed section %s/%s" % [
						chassis, part_name])


func test_hit_location_segments_are_preserved_separately() -> void:
	for chassis: String in CHASSIS:
		var model := _recipe(chassis, "_shape")
		for name: String in ["hd", "ct", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not _part(model, name).is_empty(), "missing animated joint %s/%s" % [
					chassis, name])
