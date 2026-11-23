extends TestCase
## New source-silhouette sculpt fixtures: topology, moving parts and real ports.

const VULTURE := "res://data/voxels/vulture_mk_iv.json"
const SOLITAIRE := "res://data/voxels/solitaire.json"


func test_independent_source_geometry_has_all_hit_locations() -> void:
	for path in [SOLITAIRE, VULTURE]:
		var m := VxModel.load_file(path)
		check(m.errors.is_empty(), path + ": " + ", ".join(m.errors))
		for loc in Location.COUNT:
			check(not m.parts_at(loc).is_empty(),
					path + " lacks " + Location.code(loc))
		check(m.cell_count() > 16000, path + " insufficient modeled volume")
		check_eq(int(m.quality_report.get("floating_islands", -1)), 0,
				path + " assembled geometry must have no floating islands")
		check_eq(int(m.quality_report.get("empty_parts", -1)), 0,
				path + " every modeled part must have mass")
		check_eq(int(m.quality_report.get("weak_joint_contacts", -1)), 0,
				path + " moving joints must have backed contact")


func test_solitaire_has_sunk_front_cockpit_and_both_hands() -> void:
	var m := VxModel.load_file(SOLITAIRE)
	check(m.part("hd")["pivot"].z < m.part("ct")["pivot"].z)
	check(m.part("la")["cells"].size() > 0)
	check(m.part("ra")["cells"].size() > 0)
	check(not m.part("ll_foot").is_empty())
	check(not m.part("rl_foot").is_empty())
	check_eq(m.weapons.size(), 2)


func test_vulture_is_digitigrade_with_24_open_torso_ports() -> void:
	var d: Dictionary = JsonFile.read(VULTURE)
	d["subdivide"] = 1
	var m := VxModel.from_dict(d)
	check(m.errors.is_empty(), "Vulture: " + ", ".join(m.errors))
	check_eq(m.legs, "digitigrade")
	check(not m.part("ll_tarsus").is_empty())
	check(not m.part("rl_tarsus").is_empty())
	for loc in [Location.LT, Location.RT]:
		var ports: Array = m.muzzles[loc]
		check_eq(ports.size(), 12, Location.code(loc) + " distinct launcher openings")
		var cells: Dictionary = m.parts_at(loc)[0]["cells"]
		for v: Vector3 in ports:
			var core := Vector3i(floori(v.x), floori(v.y), floori(v.z))
			check(not cells.has(core), "launcher hole sealed at " + str(core))


func test_each_omni_configuration_has_correct_muzzle_counts() -> void:
	var counts := {"a": 10, "b": 15, "c": 0, "d": 12, "e": 12}
	for config: String in counts:
		var path := "res://data/voxels/vulture_mk_iv_" + config + ".json"
		var v: Dictionary = JsonFile.read(path)
		check_eq(v.get("source", ""), VULTURE, config + " overlays source chassis")
		check_eq(v.get("unit", ""), "vulture_mk_iv_" + config)
		check(not v.get("part_overlays", []).is_empty(),
				config + " must actually change the art")
		var ports: Dictionary = v.get("muzzles", {})
		var expected: int = counts[config]
		var found: int = 12 if ports.is_empty() else (ports.get("LT", []) as Array).size()
		check_eq(found, expected, config + " visible launcher tubes per shoulder")
