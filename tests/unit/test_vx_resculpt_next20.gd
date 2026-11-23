extends TestCase
## Geometry-only regression for twenty referenced source sculpts and their
## game-ready twins. No combat rules or fixed body dimensions are involved.

const CHASSIS := [
	"locust", "raven", "crab", "king_crab", "centurion", "griffin",
	"rifleman", "black_knight", "stalker", "trebuchet", "panther",
	"commando", "urbanmech", "bushwacker", "kodiak", "longbow",
	"hatchetman", "javelin", "spider", "wolfhound"
]
const PRIMARY := ["ct", "hd", "lt", "la", "ll"]
const ASSEMBLIES := {
	"locust": ["la_mg", "ra_mg"],
	"raven": ["lt_ecm_spine", "rt_srm6"],
	"crab": ["la_pincer", "ra_pincer"],
	"king_crab": ["la_ac20_claw", "ra_ac20_claw"],
	"centurion": ["ra_ac10"],
	"griffin": ["ra_ppc_barrel"],
	"rifleman": ["la_ac5", "ra_ac5", "la_large_laser", "ra_large_laser"],
	"black_knight": ["ra_ppc", "lt_torso_laser", "rt_torso_laser"],
	"stalker": ["la_lrm10", "ra_lrm10"],
	"trebuchet": ["la_lrm15", "rt_lrm15"],
	"panther": ["ra_ppc", "ct_srm4"],
	"commando": ["ra_srm4", "ct_srm6"],
	"urbanmech": ["ra_ac10", "ct_top_exhaust"],
	"bushwacker": ["ct_er_laser", "la_lrm5", "lt_lrm5", "ra_ac10"],
	"kodiak": ["rt_uac20", "lt_streak_pair"],
	"longbow": ["lt_lrm5", "rt_lrm5"],
	"hatchetman": ["ra_hatchet", "rt_ac10"],
	"javelin": ["lt_srm6", "rt_srm6"],
	"spider": ["ct_left_laser", "ct_right_laser"],
	"wolfhound": ["lt_laser", "rt_laser", "ra_large_laser"]
}
const MISSILES := [
	{"chassis": "raven", "loc": "RT", "amount": 6},
	{"chassis": "centurion", "loc": "LT", "amount": 10},
	{"chassis": "griffin", "loc": "RT", "amount": 10},
	{"chassis": "stalker", "loc": "LA", "amount": 10},
	{"chassis": "stalker", "loc": "RA", "amount": 10},
	{"chassis": "trebuchet", "loc": "LA", "amount": 15},
	{"chassis": "trebuchet", "loc": "RT", "amount": 15},
	{"chassis": "panther", "loc": "CT", "amount": 4},
	{"chassis": "commando", "loc": "CT", "amount": 6},
	{"chassis": "commando", "loc": "RA", "amount": 4},
	{"chassis": "bushwacker", "loc": "LA", "amount": 5},
	{"chassis": "bushwacker", "loc": "LT", "amount": 5},
	{"chassis": "kodiak", "loc": "LT", "amount": 12},
	{"chassis": "longbow", "loc": "LA", "amount": 20},
	{"chassis": "longbow", "loc": "RA", "amount": 20},
	{"chassis": "longbow", "loc": "LT", "amount": 5},
	{"chassis": "longbow", "loc": "RT", "amount": 5},
	{"chassis": "javelin", "loc": "LT", "amount": 6},
	{"chassis": "javelin", "loc": "RT", "amount": 6}
]


func _data(chassis: String, detail: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, detail])


func _part(raw: Dictionary, name: String) -> Dictionary:
	for part: Dictionary in raw.get("parts", []):
		if part.get("name", "") == name:
			return part
	return {}


func _first_loft(raw: Dictionary, name: String) -> Dictionary:
	for shape: Dictionary in _part(raw, name).get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func test_twenty_low_and_detailed_anatomy_outlines_match() -> void:
	for chassis: String in CHASSIS:
		var low := _data(chassis, "_shape")
		var detailed := _data(chassis, "")
		for key: String in PRIMARY:
			var a := _first_loft(low, key)
			var b := _first_loft(detailed, key)
			check(not a.is_empty(), "%s missing %s source contour" % [chassis, key])
			check(a == b, "%s/%s: low and detailed anatomy diverge" % [chassis, key])


func test_twenty_part_rigs_are_ordered_and_hit_locations_preserved() -> void:
	for chassis: String in CHASSIS:
		for suffix: String in ["_shape", ""]:
			var raw := _data(chassis, suffix)
			var seen := {}
			var locations := {}
			for item: Dictionary in raw.get("parts", []):
				var part_name: String = item.get("name", "")
				check(not seen.has(part_name),
						"%s%s duplicates %s" % [chassis, suffix, part_name])
				var parent: String = item.get("parent", "")
				if not parent.is_empty():
					check(seen.has(parent),
							"%s%s %s has a later/missing parent" % [
								chassis, suffix, part_name])
				if item.has("mirror"):
					check(seen.has(String(item["mirror"])),
							"%s%s %s mirrors a later/missing part" % [
								chassis, suffix, part_name])
				else:
					locations[item.get("loc", "")] = true
				seen[part_name] = true
			for key: String in ["CT", "HD", "LT", "LA", "LL"]:
				check(locations.has(key),
						"%s%s missing core damage location %s" % [chassis, suffix, key])
			for component: String in ASSEMBLIES[chassis]:
				var part := _part(raw, component)
				check(not part.is_empty(), "%s%s missing %s" % [
					chassis, suffix, component])
				if not part.is_empty():
					check(not String(part.get("parent", "")).is_empty(),
							"%s/%s is not attached to a real assembly" % [
								chassis, component])


func test_missile_bores_and_muzzles_follow_actual_record_sheets() -> void:
	for spec: Dictionary in MISSILES:
		var chassis: String = spec["chassis"]
		for suffix: String in ["_shape", ""]:
			var raw := _data(chassis, suffix)
			var mounts: Variant = raw.get("muzzles", {}).get(spec["loc"], [])
			var count := mounts.size() if mounts is Array and 					not mounts.is_empty() and mounts[0] is Array else 1
			check_eq(count, int(spec["amount"]),
					"%s%s/%s visible tubes must match record sheet" % [
						chassis, suffix, spec["loc"]])


func test_selected_launchers_have_physical_voids_and_connected_housings() -> void:
	for sample: Dictionary in [
			{"chassis": "trebuchet", "part": "la_lrm15", "loc": "LA"},
			{"chassis": "javelin", "part": "lt_srm6", "loc": "LT"},
			{"chassis": "raven", "part": "rt_srm6", "loc": "RT"}]:
		var d := _data(sample["chassis"], "_shape")
		d["subdivide"] = 1
		var m := VxModel.from_dict(d)
		check(m.errors.is_empty(),
				"%s should remain a loadable sculpt" % sample["chassis"])
		var assembly := m.part(sample["part"])
		check(not assembly.is_empty(),
				"%s: expected actual weapon assembly" % sample["part"])
		if assembly.is_empty():
			continue
		check_eq(VxIntegrity.components(assembly["cells"]).size(), 1,
				"%s may not contain a floating missile slab" % sample["part"])
		var loc: int = Location.from_code(sample["loc"])
		for muzzle: Vector3 in m.muzzles.get(loc, []):
			var mouth := Vector3i(floori(muzzle.x), floori(muzzle.y),
					ceili(muzzle.z))
			check(not assembly["cells"].has(mouth),
					"%s has a blocked firing port: %s" % [
						sample["part"], mouth])
