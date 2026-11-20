extends TestCase
## Physical geometry, not just denser voxel tessellation. Measured in meshless
## model data so these checks are cheap and do not generate screenshot renders.


func _model(id: String) -> VoxelMech:
	var profile := VoxelChassis.find(id)
	var mech := VoxelMech.new()
	mech.profile_id = id
	mech.detail_level = int(profile.get("voxel_detail", 1))
	mech.render_surfaces = false
	mech.build()
	return mech


func test_training_prototype_has_real_visor_vents_and_bored_cannon() -> void:
	var m := _model("prototype")
	var hull: VoxelPart = m.parts["torso"]
	var cannon: VoxelPart = m.parts["left_arm"]
	check(hull.detail_scale >= 2, "prototype needs micro-sculpted cockpit armor")
	check_eq(hull.sculpt_material(Vector3i(1, 2, -9)), 2,
			"the test chassis must have a visible split sensor canopy")
	check(not hull.has_sculpt_cell(Vector3i(-5, 3, 2)),
			"cooling deck must have a truly recessed ventilation well")
	check(hull.has_sculpt_cell(Vector3i(0, 8, 2)),
			"dorsal sensor antenna must project above the chassis")
	check(not cannon.has_sculpt_cell(Vector3i(-1, -7, -12)),
			"left test cannon must have a hollow muzzle, not a painted dot")
	check(cannon.has_sculpt_cell(Vector3i(-4, -8, -12)),
			"cannon muzzle needs a separate armor shroud")
	m.free()


func test_hunchback_has_offset_cockpit_and_hollow_autocannon() -> void:
	var m := _model("hunchback_hbk4g")
	var hull: VoxelPart = m.parts["torso"]
	check(hull.detail_scale == 3, "heavy offset cannon should keep 25 mm detail")
	check_eq(hull.sculpt_material(Vector3i(-2, 5, -7)), 2,
			"cockpit glazing must sit beside the gun, not inside it")
	check(not hull.has_sculpt_cell(Vector3i(7, 6, -14)),
			"AC/20 bore must be physically hollow")
	check(hull.has_sculpt_cell(Vector3i(4, 9, -12)),
			"armored barrel jacket must surround the muzzle")
	check(hull.has_sculpt_cell(Vector3i(12, 10, 4)),
			"distinct asymmetric shoulder housing must be present")
	var left: VoxelPart = m.parts["left_arm"]
	var right: VoxelPart = m.parts["right_arm"]
	check(left.cells.size() != right.cells.size(),
			"weapon-side arm should not simply copy the left manipulator")
	m.free()


func test_wolverine_has_six_open_srm_ports_and_armed_right_forearm() -> void:
	var m := _model("wolverine_wvr6r")
	var hull: VoxelPart = m.parts["torso"]
	var barrel: VoxelPart = m.parts["right_arm"]
	var hand: VoxelPart = m.parts["left_arm"]
	for x in [-11, -9, -7]:
		for y in [2, 5]:
			check(not hull.has_sculpt_cell(Vector3i(x, y, -8)),
					"all six SRM ports must be carved, not painted")
			check_eq(hull.sculpt_material(Vector3i(x, y, -5)), 3,
					"each SRM chamber needs a visibly recessed interior")
	check(not barrel.has_sculpt_cell(Vector3i(0, -6, -16)),
			"right arm autocannon must have an empty bore")
	check(barrel.has_sculpt_cell(Vector3i(-4, -8, -16)),
			"right autocannon must have an armored muzzle")
	check(hand.has_sculpt_cell(Vector3i(4, -11, -3)),
			"left hand must have distinct manipulators")
	m.free()


func test_jenner_cockpit_has_25mm_detail_without_replacing_four_srm_ports() -> void:
	var m := _model("jenner_jr7d")
	var hull: VoxelPart = m.parts["torso"]
	check_eq(hull.detail_scale, 3,
			"Jenner nose, windshield, SRM rack and engine need 25 mm detail")
	check_eq(hull.sculpt_material(Vector3i(0, 0, -21)), 2,
			"forward windshield must stay visibly glazed")
	for x in [-2, 1]:
		for y in [3, 5]:
			check_eq(hull.sculpt_material(Vector3i(x, y, -7)), 3,
					"all four original SRM outlets must survive refinement")
	check(hull.cells.size() > 0, "cockpit must remain genuine damageable cells")
	m.free()


func test_five_actual_game_chassis_have_separate_visual_signatures() -> void:
	var ids := ["atlas_as7d", "hunchback_hbk4g", "wolverine_wvr6r",
			"jenner_jr7d", "catapult_cplt_c1"]
	var totals: Dictionary = {}
	for id in ids:
		var m := _model(id)
		var p: VoxelPart = m.parts["torso"]
		var roles := p.role_counts()
		check_eq(roles["armor"] + roles["structure"], p.cells.size(),
				"fine details still must carry armor/structure visual roles")
		check(p.cells.size() > 0 and m.initial_voxels() > 0,
				"chassis must contain destructible 3D geometry")
		totals[id] = m.initial_voxels()
		m.free()
	check_eq(totals.size(), 5, "all five production chassis need distinct sculpts")
