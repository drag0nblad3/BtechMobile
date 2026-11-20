extends TestCase
## Chassis-specific Jenner JR7-D visual signatures, without touching rules.


func test_jenner_forward_cockpit_and_center_srm() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	var torso: VoxelPart = mech.parts["torso"]
	check_eq(torso.sculpt_material(Vector3i(0, 2, -15)), 2,
			"forward canopy should have cyan glazing")
	check(torso.has_sculpt_cell(Vector3i(0, -1, -17)),
			"forward nose should extend beyond body")
	for x in [-2, 1]:
		for y in [3, 5]:
			check_eq(torso.sculpt_material(Vector3i(x, y, -7)), 3,
					"SRM4 must have four distinct launch openings")
	check(torso.has_sculpt_cell(Vector3i(-5, 0, 8)),
			"rear deck should have external exhaust housings")
	mech.free()


func test_jenner_has_four_distinct_laser_apertures() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	for key in ["left_arm", "right_arm"]:
		var pod: VoxelPart = mech.parts[key]
		check_eq(pod.sculpt_material(Vector3i(0, -2, -11)), 2,
				key + " should have lower laser aperture")
		check_eq(pod.sculpt_material(Vector3i(0, 1, -11)), 2,
				key + " should have upper laser aperture")
	mech.free()


func test_jenner_has_three_independent_toe_tips() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	for key in ["left_leg_foot", "right_leg_foot"]:
		var foot: VoxelPart = mech.parts[key]
		for x in [-3, 0, 3]:
			check(foot.has_sculpt_cell(Vector3i(x, -2, -9)), "missing " + key + " toe")
		check(not foot.has_sculpt_cell(Vector3i(-1, -2, -9)),
				"first toe gap must remain open")
		check(not foot.has_sculpt_cell(Vector3i(2, -2, -9)),
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
	check(torso.has_sculpt_cell(Vector3i(0, 0, -21)), "nose must project ahead")
	check(not torso.has_sculpt_cell(Vector3i(-3, 0, -21)), "nose tip must taper")
	check_eq(torso.sculpt_material(Vector3i(0, 0, -21)), 2, "front glass must wrap around")
	var thigh: VoxelPart = mech.parts["left_leg"]
	var shin: VoxelPart = mech.parts["left_leg_shin"]
	check(thigh.has_sculpt_cell(Vector3i(0, -11, 0)), "Jenner femur must reach knee")
	check(shin.has_sculpt_cell(Vector3i(0, -11, 0)), "Jenner shin must reach hock")
	check(not shin.has_sculpt_cell(Vector3i(5, -6, 0)), "open side channel needed")
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


func test_jenner_neutral_stance_uses_two_planted_staggered_feet() -> void:
	var model := VoxelMech.new()
	model.profile_id = "jenner_jr7d"
	model.build()
	model.stand()
	var l := VoxelJennerGait.foot_target(0.20)
	var r := VoxelJennerGait.foot_target(0.41)
	check(is_equal_approx(l.y, VoxelJennerGait.TOE_HEIGHT),
			"left neutral toe must remain planted")
	check(is_equal_approx(r.y, VoxelJennerGait.TOE_HEIGHT),
			"right neutral toe must remain planted")
	check(l.x - r.x > 0.30, "feet must be offset front-to-back in the neutral pose")
	check(absf(model.hips[0].rotation.x - model.hips[1].rotation.x) > 0.20,
			"leg pivots must not be identical in a standing pose")
	check(is_equal_approx(model.hips[0].position.x, -0.40),
			"Jenner should use widened hip sockets")
	model.free()


func test_jenner_cockpit_roof_is_chamfered() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	var hull: VoxelPart = mech.parts["torso"]
	check(hull.has_sculpt_cell(Vector3i(0, 2, -16)), "canopy center roof must be solid")
	check(not hull.has_sculpt_cell(Vector3i(-3, 2, -16)),
			"left canopy corner needs a chamfer")
	check(not hull.has_sculpt_cell(Vector3i(2, 2, -16)),
			"right canopy corner needs a chamfer")
	check(hull.has_sculpt_cell(Vector3i(0, 3, 0)),
			"engine deck must have an intact center roof")
	check(not hull.has_sculpt_cell(Vector3i(-5, 3, 0)),
			"engine corner should slope away from center roof")
	check_eq(hull.sculpt_material(Vector3i(-5, 1, 6)), 1,
			"recessed roof cooling well should expose the dark underlying core")
	mech.free()


func test_jenner_exposes_actual_hock_linkage_with_open_channels() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	var shin: VoxelPart = mech.parts["left_leg_shin"]
	var hock: VoxelPart = mech.parts["left_leg_metatarsal"]
	check(not shin.has_sculpt_cell(Vector3i(-2, -7, 0)),
			"shin outer channel must remain empty")
	check(not shin.has_sculpt_cell(Vector3i(2, -7, 0)),
			"opposite shin outer channel must remain empty")
	check(shin.has_sculpt_cell(Vector3i(0, -7, 0)),
			"core strut must bridge both joints")
	check_eq(shin.sculpt_material(Vector3i(0, -7, 3)), 1,
			"rear-facing piston should stay exposed")
	check(not hock.has_sculpt_cell(Vector3i(-2, -3, 0)),
			"hock fork needs real negative space")
	check(hock.has_sculpt_cell(Vector3i(0, -3, 0)),
			"hock center linkage must stay connected")
	mech.free()


func test_jenner_tapered_toes_have_separate_endpoints() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	for key in ["left_leg_foot", "right_leg_foot"]:
		var foot: VoxelPart = mech.parts[key]
		for x in [-3, 0, 3]:
			check(foot.has_sculpt_cell(Vector3i(x, -2, -11)),
					"toe is missing its narrowed end: " + key)
		for x in [-2, -1, 1, 2, 4]:
			check(not foot.has_sculpt_cell(Vector3i(x, -2, -11)),
					"toe tips must not fuse to adjacent prongs")
	mech.free()


func test_voxel_authoring_carve_preserves_final_armor_count() -> void:
	var part := VoxelPart.new()
	part.fill_box(Vector3i.ZERO, Vector3i(3, 3, 3), 0)
	var cut := part.carve_box(Vector3i(1, 1, 1), Vector3i(2, 2, 2))
	check_eq(cut, 8, "interior cut should remove eight voxels")
	check_eq(part.cells.size(), 56, "carve must preserve surrounding shell")
	part.seal()
	check_eq(part._original_count, 56, "seal must use sculpted volume as damage baseline")
	check_eq(part.carve_box(Vector3i(1, 1, 1), Vector3i(2, 2, 2)), 0,
			"repeating a carve should not remove more cells")
	part.free()
