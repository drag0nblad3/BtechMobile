extends TestCase
## Guard architecture and important component junctions after polygon-only cycles 256-275.

const ATLAS := "res://data/voxels/atlas_shape.json"
const WOLVERINE := "res://data/voxels/wolverine_shape.json"
const JENNER := "res://data/voxels/jenner_shape.json"


func _common(a: Dictionary, b: Dictionary) -> int:
	var n := 0
	for cell: Vector3i in a:
		if b.has(cell):
			n += 1
	return n


func test_pass_256_to_275_models_remain_source_shape_stage() -> void:
	for path: String in [ATLAS, WOLVERINE, JENNER]:
		var source: Dictionary = JsonFile.read(path)
		check_eq(int(source.get("subdivide", -1)), 1,
				"Shape approval gate forbids early voxel subdivision: " + path)
		var m := VxModel.from_dict(source)
		check(m.errors.is_empty(),
				"All authored polygon contours must be well formed: " + path)


func test_pass_256_to_275_atlas_head_shoulders_and_one_hand_each_side() -> void:
	var m := VxModel.load_file(ATLAS)
	var source: Dictionary = JsonFile.read(ATLAS)
	var left_arm: Dictionary = {}
	var right_arm: Dictionary = {}
	for p: Dictionary in source["parts"]:
		if p["name"] == "la":
			left_arm = p
		elif p["name"] == "ra":
			right_arm = p
	check_eq(left_arm["shapes"].size(), 4,
			"Atlas must keep one arm + elbow + gauntlet + fist, not extra hands")
	check_eq(right_arm["mirror"], "la",
			"Atlas right-side arm must mirror the rebuilt left arm")
	var arm: Dictionary = m.part("la")["cells"]
	var cuff: Dictionary = m.part("la_knuckle_cuff")["cells"]
	var finger: Dictionary = m.part("la_finger_knuckles")["cells"]
	var thumb: Dictionary = m.part("la_outer_thumb_pad")["cells"]
	check(_common(arm, cuff) > 12 and
			_common(arm, finger) > 8 and
			_common(arm, thumb) > 10,
			"Atlas hand, wrist cuff, and thumb must meet the same forearm")
	check(_common(m.part("ct")["cells"], m.part("hd")["cells"]) > 40,
			"Atlas head must remain recessed into and attached to chest")
	check(m.part("rt_ac20_shroud")["cells"].has(Vector3i(9, 42, -19)),
			"Atlas torso autocannon position changed unexpectedly")


func test_pass_256_to_275_wolverine_right_gun_arm_and_launcher() -> void:
	var source: Dictionary = JsonFile.read(WOLVERINE)
	for p: Dictionary in source["parts"]:
		if p["name"] == "ra":
			check_eq(p["shapes"].size(), 2,
					"Wolverine needs ONE bent cannon-bearing right forearm")
	var w := VxModel.from_dict(source)
	var upper: Dictionary = w.part("ra")["cells"]
	var mount: Dictionary = w.part("ra_cannon_mount")["cells"]
	var hand: Dictionary = w.part("ra_integrated_hand")["cells"]
	var gun: Dictionary = w.part("ra_ac5_shroud")["cells"]
	check(_common(upper, mount) > 25,
			"Wolverine raised elbow no longer meets gun mount")
	check(_common(mount, hand) > 20 and _common(hand, gun) > 20,
			"Wolverine integrated hand no longer holds its single AC/5")
	check(_common(w.part("lt")["cells"],
			w.part("lt_srm6_inner_mount")["cells"]) > 5,
			"Offset shoulder launcher must stay attached")


func test_pass_256_to_275_jenner_flat_disc_and_digitigrade_leg() -> void:
	var j := VxModel.load_file(JENNER)
	var disc: Dictionary = j.part("hd")["cells"]
	check(disc.has(Vector3i(0, 26, -36)),
			"Jenner forward nose disappeared")
	var low_x := 999
	var high_x := -999
	for cell: Vector3i in disc:
		low_x = mini(low_x, cell.x)
		high_x = maxi(high_x, cell.x)
	check_eq(high_x - low_x + 1, 20,
			"Jenner flat disc width accidentally changed")
	check(_common(disc, j.part("hd_disc_rim")["cells"]) > 12,
			"Jenner saucer rim detached")
	check(_common(j.part("ll_shin")["cells"],
			j.part("ll_hock_joint")["cells"]) > 8,
			"Jenner reverse-bend shin/hock articulation detached")
	check(j.part("ll_rear_hock_brace")["cells"].has(Vector3i(-7, 8, 10)),
			"Jenner rear hock brace landmark regressed")
