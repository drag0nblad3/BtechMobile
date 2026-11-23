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
	for chassis: String in CHASSIS:
		var low := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		var revision: Dictionary = low.get("reference_identity_resculpt", {})
		check(String(revision.get("revision", "")).begins_with(
				"targeted-critical-confusion-20261122-"), chassis + " sculpt lineage")
		check(int(revision.get("primary_loft_vertices_reshaped", 0)) > 16,
				chassis + " altered real primary loft vertices")
		check(not String(revision.get("neighbor", "")).is_empty(),
				chassis + " names its silhouette confusion")
		check_eq(revision, high.get("reference_identity_resculpt", {}),
				chassis + " matching source and detailed edit")
		for key: String in ["unit", "legs", "weapons", "muzzles", "jets"]:
			check_eq(low.get(key), high.get(key), chassis + " " + key + " parity")
		var parts_low: Array = low.get("parts", [])
		var parts_high: Array = high.get("parts", [])
		check_eq(parts_low.size(), parts_high.size(), chassis + " rig inventory")
		for index in mini(parts_low.size(), parts_high.size()):
			var a: Dictionary = parts_low[index]
			var b: Dictionary = parts_high[index]
			for key: String in ["name", "loc", "parent", "pivot", "joint", "mirror"]:
				check_eq(a.get(key), b.get(key), chassis + " " + key)
			var a_loft := _first_y_loft(a)
			var b_loft := _first_y_loft(b)
			check_eq(a_loft, b_loft, chassis + " " + str(a["name"]) + " main contour")


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
