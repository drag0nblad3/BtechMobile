extends TestCase
## Chassis-specific Jenner JR7-D visual signatures, without touching rules.


func test_jenner_forward_cockpit_and_center_srm() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	var torso: VoxelPart = mech.parts["torso"]
	check_eq(torso.cells.get(Vector3i(0, 2, -15)), 2,
			"forward canopy should have cyan glazing")
	check(torso.cells.has(Vector3i(0, -1, -17)),
			"forward nose should extend beyond body")
	for x in [-2, 1]:
		for y in [3, 5]:
			check_eq(torso.cells.get(Vector3i(x, y, -7)), 3,
					"SRM4 must have four distinct launch openings")
	check(torso.cells.has(Vector3i(-5, 0, 8)),
			"rear deck should have external exhaust housings")
	mech.free()


func test_jenner_has_four_distinct_laser_apertures() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	for key in ["left_arm", "right_arm"]:
		var pod: VoxelPart = mech.parts[key]
		check_eq(pod.cells.get(Vector3i(0, -2, -11)), 2,
				key + " should have lower laser aperture")
		check_eq(pod.cells.get(Vector3i(0, 1, -11)), 2,
				key + " should have upper laser aperture")
	mech.free()


func test_jenner_has_three_independent_toe_tips() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	for key in ["left_leg_foot", "right_leg_foot"]:
		var foot: VoxelPart = mech.parts[key]
		for x in [-3, 0, 3]:
			check(foot.cells.has(Vector3i(x, -2, -9)), "missing " + key + " toe")
		check(not foot.cells.has(Vector3i(-1, -2, -9)),
				"first toe gap must remain open")
		check(not foot.cells.has(Vector3i(2, -2, -9)),
				"second toe gap must remain open")
	mech.free()


func test_jenner_components_still_take_local_damage() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	var visor: VoxelPart = mech.parts["torso"]
	var arm: VoxelPart = mech.parts["left_arm"]
	var before := visor.cells.size()
	var other := arm.cells.size()
	visor.erase_local_ball(Vector3(0, 0, -1.12), 0.20)
	check(visor.cells.size() < before, "canopy must be erodible")
	check_eq(arm.cells.size(), other, "torso hit must not damage adjacent laser pod")
	mech.free()


func test_jenner_has_protruding_beveled_canopy_and_open_joint_details() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	var torso: VoxelPart = mech.parts["torso"]
	check(torso.cells.has(Vector3i(0, 0, -21)), "nose must project ahead")
	check(not torso.cells.has(Vector3i(-3, 0, -21)), "nose tip must taper")
	check_eq(torso.cells.get(Vector3i(0, 0, -21)), 2, "front glass must wrap around")
	var thigh: VoxelPart = mech.parts["left_leg"]
	var shin: VoxelPart = mech.parts["left_leg_shin"]
	check(thigh.cells.has(Vector3i(0, -11, 0)), "Jenner femur must reach knee")
	check(shin.cells.has(Vector3i(0, -11, 0)), "Jenner shin must reach hock")
	check(not shin.cells.has(Vector3i(5, -6, 0)), "open side channel needed")
	mech.free()


func test_jenner_pivots_match_custom_leg_length() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	check(is_equal_approx(mech.hips[0].position.y, VoxelJennerGait.HIP_HEIGHT),
			"Jenner hip should be taller than standard digitigrade")
	check(is_equal_approx(mech.knees[0].position.y, -VoxelJennerGait.THIGH),
			"Jenner knee pivot must match thigh length")
	check(is_equal_approx(mech.hocks[0].position.y, -VoxelJennerGait.SHIN),
			"Jenner hock pivot must match shin length")
	check(is_equal_approx(mech.ankles[0].position.y, -VoxelJennerGait.METATARSAL),
			"Jenner toe pivot must match metatarsal length")
	check(is_equal_approx(mech.get_node("Frame/UpperBody").position.y, mech.upper_height()),
			"upper body should be raised with longer legs")
	mech.free()


func test_jenner_gait_three_link_ik_reaches_toe_every_phase() -> void:
	for i in 40:
		var p := float(i) / 40.0
		var a := VoxelJennerGait.sample(p)
		var x := VoxelJennerGait.THIGH * sin(a.x)
		x += VoxelJennerGait.SHIN * sin(a.x + a.y)
		x += VoxelJennerGait.METATARSAL * sin(a.x + a.y + a.z)
		var down := VoxelJennerGait.THIGH * cos(a.x)
		down += VoxelJennerGait.SHIN * cos(a.x + a.y)
		down += VoxelJennerGait.METATARSAL * cos(a.x + a.y + a.z)
		var target := VoxelJennerGait.foot_target(p)
		check(absf(x - target.x) < 0.005, "toe forward miss phase %.2f" % p)
		check(absf(down - (VoxelJennerGait.HIP_HEIGHT - target.y)) < 0.005,
				"toe height miss phase %.2f" % p)
		check(absf(a.x + a.y + a.z + a.w) < 0.0001,
				"toe must stay level phase %.2f" % p)
	check(VoxelJennerGait.foot_target(0.0).x > 0.45, "forward stride shortened")
	check(VoxelJennerGait.foot_target(0.5).x < -0.35, "rear stride shortened")
	check(VoxelJennerGait.foot_target(0.82).y >
			VoxelJennerGait.TOE_HEIGHT + 0.20, "swing clearance too low")
