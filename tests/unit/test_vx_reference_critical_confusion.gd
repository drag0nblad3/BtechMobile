extends TestCase
## Data-driven guard for the 31 critical nearest-neighbor identity resculpts.
## Silhouette similarity is a screening metric, not visual reference approval.

const CHASSIS := [
	"awesome", "battleaxe", "battlemaster", "chameleon", "crockett",
	"flashman", "goliath", "grasshopper", "guillotine", "gunslinger",
	"icarus_ii", "katana", "kintaro", "lancelot", "orion", "ostwar",
	"penetrator", "quickdraw", "sagittaire", "scorpion", "sentinel",
	"shogun", "spartan", "starslayer", "stormcrow", "tarantula",
	"thanatos", "thug", "valkyrie", "ymir", "zeus"
]
# Newer source-level sculpt cohorts on main take precedence for these chassis.
const SUPERSEDED_BY_NEWER_SCULPTS := ["icarus_ii","katana","lancelot","ostwar","penetrator","spartan","starslayer","tarantula","thanatos","valkyrie","ymir"]
const QUADS := ["goliath", "scorpion", "tarantula"]
const SPOT_CHECK := ["chameleon", "lancelot", "icarus_ii", "sentinel",
		"goliath", "tarantula", "battleaxe", "sagittaire"]


func _recipe(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _first_y_loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft") and shape["loft"].get("axis", "y") == "y":
			return shape["loft"]
	return {}


func _area(poly: Array) -> float:
	var twice := 0.0
	for i in poly.size():
		var j := (i + 1) % poly.size()
		twice += float(poly[i][0]) * float(poly[j][1])
		twice -= float(poly[j][0]) * float(poly[i][1])
	return twice * 0.5


func test_all_critical_identity_recipes_have_paired_primary_resculpts() -> void:
	check_eq(CHASSIS.size(), 31, "critical cohort matches the named audit")
	var retained := 0
	for chassis: String in CHASSIS:
		var low := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		if chassis in SUPERSEDED_BY_NEWER_SCULPTS:
			# Retain latest, independently verified source geometry instead of
			# resurrecting this old branch\'s contours.
			continue
		retained += 1
		var revision: Dictionary = low.get("reference_identity_resculpt", {})
		check(String(revision.get("revision", "")).begins_with(
				"targeted-critical-confusion-20261122-"), chassis + " sculpt lineage")
		check(int(revision.get("primary_loft_vertices_reshaped", 0)) > 16,
				chassis + " altered real primary loft vertices")
		check(not String(revision.get("neighbor", "")).is_empty(),
				chassis + " names its silhouette confusion")
		check_eq(revision, high.get("reference_identity_resculpt", {}),
				chassis + " matching source and detailed edit")
		for key: String in ["unit", "legs", "weapons"]:
			check_eq(low.get(key), high.get(key), chassis + " " + key + " parity")
		# Separate, location-owned weapon subassemblies may exist in the
		# coarse rig without a dedicated detailed sculpt. Compare shared
		# damageable parts by identity, not by array index or total count.
		var parts_low: Array = low.get("parts", [])
		var parts_high: Array = high.get("parts", [])
		var low_by_name := {}
		var high_by_name := {}
		for part: Dictionary in parts_low:
			var part_name: String = String(part.get("name", ""))
			check(not low_by_name.has(part_name),
					chassis + " duplicate source part " + part_name)
			low_by_name[part_name] = part
		for part: Dictionary in parts_high:
			var part_name: String = String(part.get("name", ""))
			check(not high_by_name.has(part_name),
					chassis + " duplicate detail part " + part_name)
			high_by_name[part_name] = part
			check(low_by_name.has(part_name),
					chassis + " detailed part missing in source: " + part_name)
			if not low_by_name.has(part_name):
				continue
			var source_part: Dictionary = low_by_name[part_name]
			for key: String in ["name", "loc", "parent", "pivot", "joint", "mirror"]:
				check_eq(source_part.get(key), part.get(key),
						chassis + " " + part_name + " " + key)
			check_eq(_first_y_loft(source_part), _first_y_loft(part),
						chassis + " " + part_name + " main contour")
		for part: Dictionary in parts_low:
			var part_name: String = String(part.get("name", ""))
			if high_by_name.has(part_name):
				continue
			check(not String(part.get("parent", "")).is_empty(),
					chassis + " new articulated part needs a parent: " + part_name)
			check(not String(part.get("loc", "")).is_empty(),
					chassis + " new articulated part needs a hit location: " + part_name)
	check(retained >= 20, "preserve at least twenty unsuperseded identity resculpts")


func test_resculpted_primary_lofts_are_oriented_and_noncollapsed() -> void:
	for chassis: String in CHASSIS:
		var raw := _recipe(chassis, "_shape")
		var count := 0
		for part: Dictionary in raw.get("parts", []):
			var loft := _first_y_loft(part)
			if loft.is_empty():
				continue
			count += 1
			var stations: Array = loft.get("sections", [])
			check(stations.size() >= 2, chassis + " loft requires stations")
			var winding := 0.0
			var expected: int = -1
			var previous := -99999.0
			for section: Dictionary in stations:
				var at := float(section["at"])
				check(at > previous, chassis + " loft stations ordered")
				previous = at
				var points: Array = section["polygon"]
				if expected < 0:
					expected = points.size()
				check_eq(points.size(), expected, chassis + " contour correspondence")
				var area := _area(points)
				check(absf(area) > 1.0, chassis + " noncollapsed section")
				if winding != 0.0:
					check(winding * area > 0, chassis + " consistent winding")
				winding = area
		check(count >= 4, chassis + " distinct primary part profiles")


func test_quad_identity_is_real_four_leg_rig_not_decorative_appendages() -> void:
	for chassis: String in QUADS:
		var raw := _recipe(chassis, "_shape")
		var names := {}
		for part: Dictionary in raw.get("parts", []):
			names[part["name"]] = true
		for name: String in ["la", "ra", "ll", "rl",
				"la_shin", "ra_shin", "ll_shin", "rl_shin"]:
			check(names.has(name), chassis + " load-bearing " + name)


func test_selected_resculpts_load_all_hit_locations() -> void:
	for chassis: String in SPOT_CHECK:
		var raw := _recipe(chassis, "_shape")
		raw["subdivide"] = 1
		var model := VxModel.from_dict(raw)
		check(model.errors.is_empty(), chassis + " no load errors: " + str(model.errors))
		for loc in Location.COUNT:
			check(not model.parts_at(loc).is_empty(),
					chassis + " has location " + Location.code(loc))
