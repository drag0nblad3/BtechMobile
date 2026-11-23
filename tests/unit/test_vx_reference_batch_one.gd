extends TestCase
## Paired resolution and structural geometry coverage for reference sculpt batch one.

const CHASSIS := [
	"javelin", "enforcer", "black_knight", "vindicator", "quickdraw",
	"battlemaster", "centurion", "thunderbolt", "dragon", "commando",
	"locust", "urbanmech", "awesome", "stalker", "king_crab",
	"annihilator", "banshee", "highlander", "orion", "trebuchet"
]


func _data(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(data: Dictionary, part_name: String) -> Dictionary:
	for part: Dictionary in data.get("parts", []):
		if part.get("name", "") == part_name:
			return part
	return {}


func _primary_loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_main_contours_match_between_both_resolution_tiers() -> void:
	for chassis: String in CHASSIS:
		var low := _data(chassis, "_shape")
		var high := _data(chassis, "")
		check_eq(low["unit"], high["unit"], "different chassis IDs: %s" % chassis)
		check_eq(low["legs"], high["legs"], "different gait rigs: %s" % chassis)
		for part_name: String in ["ct", "lt", "la"]:
			var a := _primary_loft(_part(low, part_name))
			var b := _primary_loft(_part(high, part_name))
			check(not a.is_empty(), "missing low-res sculpt %s:%s" % [chassis, part_name])
			check(not b.is_empty(), "missing high-res sculpt %s:%s" % [chassis, part_name])
			check(a == b, "unmatched geometry tier %s:%s" % [chassis, part_name])


func test_refined_bodies_keep_noncollapsed_cross_sections() -> void:
	for chassis: String in CHASSIS:
		for tier: String in ["_shape", ""]:
			var data := _data(chassis, tier)
			for part_name: String in ["ct", "lt", "la"]:
				var loft := _primary_loft(_part(data, part_name))
				if loft.is_empty():
					continue
				for section: Dictionary in loft.get("sections", []):
					var points: Array = section.get("polygon", [])
					check(points.size() >= 3, "incomplete loft: %s%s/%s" % [
						chassis, tier, part_name])
					if points.size() < 3:
						continue
					var min_a := INF
					var min_b := INF
					var max_a := -INF
					var max_b := -INF
					for vertex: Array in points:
						min_a = minf(min_a, float(vertex[0]))
						max_a = maxf(max_a, float(vertex[0]))
						min_b = minf(min_b, float(vertex[1]))
						max_b = maxf(max_b, float(vertex[1]))
					check(min_a < max_a and min_b < max_b,
							"collapsed polygon: %s%s/%s" % [chassis, tier, part_name])


func test_refined_mechs_still_load_all_animated_hit_locations() -> void:
	for chassis: String in CHASSIS:
		for tier: String in ["_shape", ""]:
			var data := _data(chassis, tier)
			data["subdivide"] = 1
			var model := VxModel.from_dict(data)
			check(model.errors.is_empty(), "model errors %s%s: %s" % [
				chassis, tier, model.errors])
			for loc in Location.COUNT:
				check(not model.parts_at(loc).is_empty(), "missing %s on %s%s" % [
					Location.code(loc), chassis, tier])


func test_nonhuman_silhouettes_and_distinctive_racks_survive() -> void:
	for chassis: String in ["locust", "stalker"]:
		for tier: String in ["_shape", ""]:
			check_eq(_data(chassis, tier)["legs"], "digitigrade",
					"reverse-jointed silhouette lost: %s%s" % [chassis, tier])
	for tier: String in ["_shape", ""]:
		var urban := _data("urbanmech", tier)
		var crab := _data("king_crab", tier)
		var thunder := _data("thunderbolt", tier)
		check(not _part(urban, "ra").is_empty(), "UrbanMech cannon arm missing")
		check(not _part(crab, "la").is_empty() and not _part(crab, "ra").is_empty(),
				"King Crab cannon claws missing")
		check(not _part(thunder, "rt_rack").is_empty(),
				"Thunderbolt raised missile pod missing")
