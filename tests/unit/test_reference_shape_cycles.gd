extends TestCase
## Shape-only regression guards for reference-led passes 206-225.
## No subdivision, cosmetic detail, or core game-rule changes.

const MODELS := [
	"res://data/voxels/atlas_shape.json",
	"res://data/voxels/wolverine_shape.json",
	"res://data/voxels/jenner_shape.json",
]


func _shared(a: Dictionary, b: Dictionary) -> int:
	var result := 0
	for cell: Vector3i in a:
		if b.has(cell):
			result += 1
	return result


func test_reference_shape_gate_still_coarse_and_complete() -> void:
	for path: String in MODELS:
		var source: Dictionary = JsonFile.read(path)
		check_eq(int(source.get("subdivide", -1)), 1,
				"Do not voxel-subdivide before silhouette approval: " + path)
		var model := VxModel.from_dict(source)
		check(model.errors.is_empty(), "Reference form has invalid lofts: " + path)
		for loc in Location.COUNT:
			check(not model.parts_at(loc).is_empty(),
					"Location omitted from reference form: " + path)
		check(model.cell_count() > 1200 and model.cell_count() < 32000,
				"Shape-stage density escaped coarse budget: " + path)


func test_atlas_low_profile_skull_and_outer_shoulder_apron() -> void:
	var atlas := VxModel.load_file(MODELS[0])
	var shoulder: Dictionary = atlas.part("lt")["cells"]
	var apron: Dictionary = atlas.part("lt_round_shoulder_underplate")["cells"]
	check(_shared(shoulder, apron) > 10,
			"Atlas underplate is not anchored to main shoulder")
	check(_shared(shoulder, apron) < 315,
			"Atlas underplate has expanded back into overlapping shell")
	check(_shared(atlas.part("ct")["cells"], atlas.part("hd")["cells"]) > 50,
			"Recessed Atlas head is detached from chest")
	check(atlas.part("pelvis_front_codpiece")["cells"].has(Vector3i(0, 26, -6)),
			"Shallow Atlas chest-to-hip landmark lost")
	check(atlas.part("rt_ac20_shroud")["cells"].has(Vector3i(9, 42, -19)),
			"Atlas forward torso cannon shroud lost")


func test_wolverine_has_one_bent_right_gun_arm_with_attached_hand() -> void:
	var source: Dictionary = JsonFile.read(MODELS[1])
	for part: Dictionary in source["parts"]:
		if part["name"] == "ra":
			check_eq(part["shapes"].size(), 2,
					"Never add a second dangling Wolverine right forearm")
			for shape: Dictionary in part["shapes"]:
				check(shape.has("loft") and shape["loft"]["axis"] == "z",
						"Right arm must connect along the same bent forearm path")
	var w := VxModel.from_dict(source)
	var arm: Dictionary = w.part("ra")["cells"]
	var bridge: Dictionary = w.part("ra_cannon_mount")["cells"]
	var hand: Dictionary = w.part("ra_integrated_hand")["cells"]
	var ac5: Dictionary = w.part("ra_ac5_shroud")["cells"]
	check(_shared(arm, bridge) > 50 and _shared(arm, bridge) < 340,
			"Right cannon mount is detached or a duplicate full-volume forearm")
	check(_shared(hand, bridge) > 20 and _shared(hand, ac5) > 20,
			"Right hand must wrap the actual cannon-bearing arm")
	check(bridge.has(Vector3i(18, 29, -19)) and
			bridge.has(Vector3i(18, 38, -5)),
			"Bent elbow-to-breech connecting spar lost")


func test_jenner_is_flat_forward_disc_with_linked_reverse_joint() -> void:
	var j := VxModel.load_file(MODELS[2])
	var disc: Dictionary = j.part("hd")["cells"]
	var rim: Dictionary = j.part("hd_disc_rim")["cells"]
	check(disc.has(Vector3i(0, 26, -36)),
			"Forward Jenner disc nose is missing")
	var min_x := 999
	var max_x := -999
	for v: Vector3i in disc:
		min_x = mini(min_x, v.x)
		max_x = maxi(max_x, v.x)
	check_eq(max_x - min_x + 1, 20,
			"Jenner forward saucer diameter changed unintentionally")
	check(_shared(disc, rim) < 200 and _shared(disc, rim) > 20,
			"Jenner has a duplicate filled saucer or a detached rim")
	check(not j.part("ll_hock_joint")["cells"].is_empty() and
			not j.part("ll_rear_hock_brace")["cells"].is_empty(),
			"Jenner needs true reverse-knee/hock links")
