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


## Coarse verification keeps this catalog check fast enough for mobile CI.
const ADDED_CHASSIS := [
	"solitaire", "vulture_mk_iv", "hellhound_conjurer",
	"koshi_standard", "hawkwolf_hwk4f", "black_hawk_standard",
	"dominator"
]


func test_all_seven_new_chassis_are_independent_and_connected() -> void:
	var distinct := {}
	for chassis: String in ADDED_CHASSIS:
		var d: Dictionary = JsonFile.read("res://data/voxels/" + chassis + ".json")
		check(not d.is_empty(), chassis + " source shape exists")
		check_eq(d.get("id", ""), chassis)
		check(not distinct.has(chassis), "no reused chassis identifiers")
		distinct[chassis] = true
		check((d.get("parts", []) as Array).size() >= 10,
				chassis + " needs independently articulated body masses")
		d["subdivide"] = 1
		var m := VxModel.from_dict(d)
		check(m.errors.is_empty(), chassis + " geometry: " + ", ".join(m.errors))
		for loc in Location.COUNT:
			check(not m.parts_at(loc).is_empty(),
					chassis + " missing " + Location.code(loc))
		check_eq(int(m.quality_report.get("floating_islands", -1)), 0,
				chassis + " must have physically connected geometry")
		check_eq(int(m.quality_report.get("weak_joint_contacts", -1)), 0,
				chassis + " joints must have structural contact")


func test_variant_ports_follow_real_record_sheet_rack_size() -> void:
	var checks := [
		["hellhound_conjurer", "LT", 4],
		["hellhound_conjurer_7", "LT", 10],
		["koshi_standard", "LA", 8],
		["koshi_standard_2", "LA", 6],
		["koshi_standard_3", "LA", 3],
		["hawkwolf_hwk4f", "LA", 15],
		["hawkwolf_hwk4f", "LT", 5],
		["black_hawk_standard", "LA", 8],
		["black_hawk_standard_2", "LA", 6],
		["black_hawk_standard_3", "LA", 2],
		["dominator", "LT", 6],
		["dominator_2", "LT", 20]
	]
	for item: Array in checks:
		var path := "res://data/voxels/" + str(item[0]) + ".json"
		var d: Dictionary = JsonFile.read(path)
		var muzzles: Dictionary = d.get("muzzles", {})
		var ports: Array = muzzles.get(str(item[1]), [])
		check_eq(ports.size(), int(item[2]),
				str(item[0]) + " " + str(item[1]) + " sourced opening count")


func test_all_twenty_source_designs_have_renderable_base_or_variant() -> void:
	var ids := ["solitaire_3", "mauler_mal4r", "hatamoto_chi_htm30t",
			"vulture_mk_iv_prime", "vulture_mk_iv_a", "vulture_mk_iv_b",
			"vulture_mk_iv_c", "vulture_mk_iv_d", "vulture_mk_iv_e",
			"hellhound_conjurer", "hellhound_conjurer_7",
			"black_hawk_standard", "black_hawk_standard_2",
			"black_hawk_standard_3", "dominator", "dominator_2",
			"hawkwolf_hwk4f", "koshi_standard", "koshi_standard_2",
			"koshi_standard_3"]
	var db := designs()
	for id: String in ids:
		var d: UnitDef = db.get_def(id)
		check(d != null, id + " is in roster")
		if d == null:
			continue
		check(not d.sprite.is_empty(), id + " has an art identifier")
		if d.sprite in ["mauler", "hatamoto_chi"]:
			continue  # Mature pre-existing art from the same chassis.
		check(FileAccess.file_exists(UnitVoxels.model_path(d)),
				id + " has its own source-aligned voxel model or overlay")
