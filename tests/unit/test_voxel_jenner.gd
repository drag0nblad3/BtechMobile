extends TestCase
## The Jenner's canonical 35-ton body is a long aircraft nose plus two
## engine-mounted twin lasers on slender, three-link avian legs.


func _jenner() -> VoxelMech:
	var m := VoxelMech.new()
	m.profile_id = "jenner_jr7d"
	m.render_surfaces = false
	m.build()
	return m


func test_long_wedge_canopy_and_four_real_dorsal_srm4_ports() -> void:
	var m := _jenner()
	var p: VoxelPart = m.parts["torso"]
	check(p.has_sculpt_cell(Vector3i(0, 0, -25)),
			"forward beak must extend well ahead of engine assembly")
	check(not p.has_sculpt_cell(Vector3i(4, 0, -25)),
			"nose tip cannot be blunt and nearly as wide as the body")
	check_eq(p.sculpt_material(Vector3i(0, 1, -18)), 2,
			"cockpit glazing must be on the forward low swept canopy")
	for x in [-2, 1]:
		for y in [5, 7]:
			check(not p.has_sculpt_cell(Vector3i(x, y, -6)),
					"each SRM4 rocket tube is a real negative-space opening")
			check_eq(p.sculpt_material(Vector3i(x, y, -1)), 3,
					"each rocket needs its own deep rear chamber")
	m.free()


func test_side_laser_pods_are_two_tubes_not_four_human_arms() -> void:
	var m := _jenner()
	for key in ["left_arm", "right_arm"]:
		var pod: VoxelPart = m.parts[key]
		check_eq(pod.detail_scale, 3,
				"each laser pod has independently sculpted 25mm armor")
		for y in [-2, 2]:
			check(not pod.has_sculpt_cell(Vector3i(0, y, -12)),
					"forward opening must remain hollow")
			check_eq(pod.sculpt_material(Vector3i(0, y, -2)), 2,
					"glowing laser chamber is separate behind mouth")
		check(not pod.has_sculpt_cell(Vector3i(0, 0, -12)),
				"two barrels must have an actual air gap between them")
	m.free()


func test_jenner_slender_leg_hocks_and_three_open_talon_ends() -> void:
	var m := _jenner()
	var thigh: VoxelPart = m.parts["left_leg"]
	var shin: VoxelPart = m.parts["left_leg_shin"]
	var hock: VoxelPart = m.parts["left_leg_metatarsal"]
	check(thigh.has_sculpt_cell(Vector3i(0, -10, -1)),
			"narrow thigh rod must reach knee")
	check(shin.has_sculpt_cell(Vector3i(0, -10, 1)),
			"reverse knee/long shin rod must reach hock")
	check(hock.has_sculpt_cell(Vector3i(0, -4, 0)),
			"real third hinge must attach to the foot")
	check(not shin.has_sculpt_cell(Vector3i(7, -6, 0)),
			"calf must not be the original wide solid tree trunk")
	for key in ["left_leg_foot", "right_leg_foot"]:
		var foot: VoxelPart = m.parts[key]
		for x in [-3, 0, 3]:
			check(foot.has_sculpt_cell(Vector3i(x, -2, -14)),
					"each of three toe tips is its own solid prong")
		for x in [-2, 2]:
			check(not foot.has_sculpt_cell(Vector3i(x, -2, -14)),
					"foot prongs must not fuse into one snowshoe")
	m.free()


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
