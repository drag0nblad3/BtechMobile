extends TestCase
## Former V2 anatomy tests: now guard the V4 clean-rebuild contracts.


func _make(id: String) -> VoxelMech:
	var m := VoxelMech.new()
	m.profile_id = id
	m.render_surfaces = false
	m.build()
	return m


func test_v4_really_excludes_old_v2_v3_geometry_pipeline() -> void:
	for id in ["atlas_as7d", "hunchback_hbk4g",
			"wolverine_wvr6r", "jenner_jr7d", "catapult_cplt_c1"]:
		var m := _make(id)
		var body: VoxelPart = m.parts["torso"]
		check(body.detail_style.begins_with("v4_"),
				"%s must use solely new source geometry" % id)
		check_eq(body.detail_style, "v4_" + str(VoxelChassis.find(id)["shape"]),
				"old procedural material decorators must not run")
		m.free()


func test_atlas_has_real_slim_waist_and_separate_pectoral_panels() -> void:
	var m := _make("atlas_as7d")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(-4, -10, 0)),
			"lower torso must keep structural waist assembly")
	check(body.has_sculpt_cell(Vector3i(-10, 3, 0)),
			"shoulder should be wider than waist")
	check(not body.has_sculpt_cell(Vector3i(-10, -10, 0)),
			"waist may not fill an entire chest-width rectangular column")
	check(body.has_sculpt_cell(Vector3i(-5, -3, -7)),
			"left breastplate has its own front armor face")
	check(body.has_sculpt_cell(Vector3i(4, -3, -7)),
			"right breastplate has an independently shaped counterpart")
	m.free()


func test_hunchback_hull_is_asymmetric_and_weapon_faces_forward() -> void:
	var m := _make("hunchback_hbk4g")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(10, 11, 0)),
			"right AC20 tower must be taller than the left cockpit")
	check(not body.has_sculpt_cell(Vector3i(-10, 11, 0)),
			"cannon tower must not be duplicated on left")
	check(not body.has_sculpt_cell(Vector3i(8, 9, -17)),
			"AC20 physical bore points forward, not up")
	check(body.has_sculpt_cell(Vector3i(10, 9, -17)),
			"cannon muzzle should retain its structural outer wall")
	m.free()


func test_wolverine_right_arm_is_armed_not_mirrored() -> void:
	var m := _make("wolverine_wvr6r")
	var right: VoxelPart = m.parts["right_arm"]
	var left: VoxelPart = m.parts["left_arm"]
	check(right.cells.size() > left.cells.size(),
			"large arm-mounted cannon must differ from small left manipulator")
	check(not right.has_sculpt_cell(Vector3i(0, -8, -17)),
			"arm weapon must have clear actual hollow bore")
	check(left.has_sculpt_cell(Vector3i(0, -14, -1)),
			"opposite hand must contain separately sculpted fingers")
	m.free()


func test_palette_and_damage_roles_are_invariant_under_resculpt() -> void:
	check_eq(VoxelPart.PALETTE.size(), VoxelPart.MATERIAL_ROLES.size(),
			"new reference armor materials must retain cosmetic armor roles")
	check_eq(VoxelPart.MATERIAL_ROLES[6], "armor",
			"Atlas bone-colored helmet is decorative armor")
	check_eq(VoxelPart.MATERIAL_ROLES[8], "structure",
			"gunmetal actuators expose internal structure")
	check_eq(VoxelPart.MATERIAL_ROLES[7], "armor",
			"red eyes are just visual armor, never a gameplay hit location")
