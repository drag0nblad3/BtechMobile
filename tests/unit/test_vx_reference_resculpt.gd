extends TestCase
## Reference-led shape regression: proportions may evolve, but rigs and bores
## must remain functional and new assemblies cannot be disconnected chunks.

const IDS := [
	"firestarter", "sagittaire", "battleaxe", "warhammer", "archer",
	"timber_wolf", "marauder", "shadow_hawk", "phoenix_hawk", "thunderbolt"
]
const ADDED := {
	"firestarter": ["hd_antenna"],
	"sagittaire": ["lt_ppc", "rt_pulse"],
	"battleaxe": ["lt_lrm5", "rt_srm6"],
	"warhammer": ["la_ppc", "ra_ppc"],
	"archer": ["la_fist", "ra_fist"],
	"timber_wolf": ["hd_glazing"],
	"marauder": ["hd_chin", "la_ppc", "ra_ppc"],
	"shadow_hawk": ["lt_cannon_shroud"],
	"phoenix_hawk": ["ra_large_laser", "ra_small_emitter"]
}


func test_new_assemblies_have_valid_parents_and_one_connected_mass() -> void:
	for id: String in ADDED:
		var raw: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		raw["subdivide"] = 1
		var m := VxModel.from_dict(raw)
		check(m.errors.is_empty(), "%s: loader errors %s" % [id, m.errors])
		for name: String in ADDED[id]:
			var p: Dictionary = m.part(name)
			check(not p.is_empty(), "%s: missing %s" % [id, name])
			if p.is_empty():
				continue
			check(not String(p.get("parent", "")).is_empty(),
					"%s: %s must follow its parent rig" % [id, name])
			check(not m.part(p.get("parent", "")).is_empty(),
					"%s: %s parent not found" % [id, name])
			check_eq(VxIntegrity.components(p["cells"]).size(), 1,
					"%s: %s has disconnected geometry" % [id, name])


func test_sculpts_keep_all_damage_locations_and_legal_parent_order() -> void:
	for id: String in IDS:
		var raw: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var seen := {}
		var locs := {}
		for p: Dictionary in raw.get("parts", []):
			var parent: String = p.get("parent", "")
			if not parent.is_empty():
				check(seen.has(parent), "%s: %s parent missing" % [id, p["name"]])
			if p.has("mirror"):
				check(seen.has(p["mirror"]), "%s: mirror of later part" % id)
			else:
				locs[p.get("loc", "")] = true
			seen[p["name"]] = true
		for code: String in ["CT", "HD", "LT", "LA", "LL"]:
			check(locs.has(code), "%s: missing damageable %s source" % [id, code])
		check(raw.has("unit"), "%s: model must identify a real record sheet" % id)


func test_sagittaire_has_asymmetric_shoulders_with_real_emitter_bores() -> void:
	var raw: Dictionary = JsonFile.read("res://data/voxels/sagittaire_shape.json")
	raw["subdivide"] = 1
	var m := VxModel.from_dict(raw)
	check_eq(m.part("lt_ppc")["loc"], Location.LT)
	check_eq(m.part("rt_pulse")["loc"], Location.RT)
	for item: Dictionary in [
			{"part": "lt_ppc", "loc": Location.LT},
			{"part": "rt_pulse", "loc": Location.RT}]:
		var muzzle: Vector3 = m.muzzles[item["loc"]][0]
		var opening := Vector3i(floori(muzzle.x), floori(muzzle.y), ceili(muzzle.z))
		check(not m.part(item["part"])["cells"].has(opening),
				"Shoulder weapon should fire through a real front-facing void")


func test_launchers_have_individual_open_ports_not_painted_dots() -> void:
	for spec: Dictionary in [
			{"id": "battleaxe", "part": "lt_lrm5", "count": 5},
			{"id": "battleaxe", "part": "rt_srm6", "count": 6},
			{"id": "thunderbolt", "part": "rt_rack", "count": 15}]:
		var raw: Dictionary = JsonFile.read(
				"res://data/voxels/%s_shape.json" % spec["id"])
		raw["subdivide"] = 1
		var authored: Dictionary = {}
		for p: Dictionary in raw["parts"]:
			if p["name"] == spec["part"]:
				authored = p
				break
		var face_limit := -20 if spec["id"] == "thunderbolt" else -10
		var ports := 0
		for shape: Dictionary in authored.get("shapes", []):
			if shape.has("erase") and int(shape["erase"][0][2]) <= face_limit:
				ports += 1
		check_eq(ports, spec["count"],
				"%s: launcher count from record sheet" % spec["id"])
		var m := VxModel.from_dict(raw)
		check(m.errors.is_empty(), "%s: launcher must load" % spec["id"])
		var cells: Dictionary = m.part(spec["part"])["cells"]
		for shape: Dictionary in authored.get("shapes", []):
			if not shape.has("erase") or int(shape["erase"][0][2]) > face_limit:
				continue
			var lo: Array = shape["erase"][0]
			var mouth := Vector3i(int(lo[0]), int(lo[1]), int(lo[2]))
			check(not cells.has(mouth),
					"%s: each tube must be physically open" % spec["id"])


func test_cannon_barrels_mirror_into_the_correct_arm_rig() -> void:
	for id: String in ["warhammer", "marauder"]:
		var raw: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		raw["subdivide"] = 1
		var m := VxModel.from_dict(raw)
		var l: Dictionary = m.part("la_ppc")
		var r: Dictionary = m.part("ra_ppc")
		check_eq(l["parent"], "la")
		check_eq(r["parent"], "ra")
		check_eq(l["loc"], Location.LA)
		check_eq(r["loc"], Location.RA)
		check_eq(l["cells"].size(), r["cells"].size(),
				"Both barrel assemblies must mirror rather than use a generic arm")
