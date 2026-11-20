extends TestCase
## Regression tests for ACTUAL resculpted geometry (shape, openings, materials).
## These run on real Godot voxel cells, with GPU mesh generation disabled.


func _make(id: String) -> VoxelMech:
	var m := VoxelMech.new()
	m.profile_id = id
	m.render_surfaces = false
	m.build()
	return m


func _width_at_y(p: VoxelPart, coarse_y: int) -> int:
	var min_x := 999999
	var max_x := -999999
	for cell: Vector3i in p.cells:
		if floori(float(cell.y) / float(p.detail_scale)) != coarse_y:
			continue
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
	return max_x - min_x if max_x >= min_x else 0


func test_atlas_is_broad_shouldered_not_a_rectangular_torso() -> void:
	var m := _make("atlas_as7d")
	var body: VoxelPart = m.parts["torso"]
	check(_width_at_y(body, 2) > _width_at_y(body, -8) * 1.35,
			"Atlas shoulders need a genuine outward taper above its waist")
	check_eq(body.sculpt_material(Vector3i(-3, 9, -8)), 7,
			"Atlas's left red skull eye must be physically inset")
	check_eq(body.sculpt_material(Vector3i(2, 9, -8)), 7,
			"Atlas's right red skull eye must remain separate")
	check(body.has_sculpt_cell(Vector3i(-5, 6, -7)),
			"Atlas skull needs protruding cheekbone armor")
	check(not body.has_sculpt_cell(Vector3i(9, -1, -12)),
			"torso AC/20 should remain bored front to back")
	m.free()


func test_hunchback_hump_is_asymmetric_and_its_barrel_is_hollow() -> void:
	var m := _make("hunchback_hbk4g")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(12, 10, 4)),
			"Hunchback should have a proud right-shoulder housing")
	check(not body.has_sculpt_cell(Vector3i(-12, 10, 4)),
			"left side must not have a mirror-image cannon hump")
	check(not body.has_sculpt_cell(Vector3i(7, 6, -17)),
			"AC/20 must have a true open bore at its muzzle")
	check(body.has_sculpt_cell(Vector3i(10, 6, -17)),
			"cannon shroud must be physically modeled around the bore")
	var left: VoxelPart = m.parts["left_arm"]
	var right: VoxelPart = m.parts["right_arm"]
	check(left.cells.size() != right.cells.size(),
			"asymmetric manipulator and coaxial weapon must differ")
	m.free()


func test_wolverine_has_separate_recessed_srm_and_autocannon() -> void:
	var m := _make("wolverine_wvr6r")
	var body: VoxelPart = m.parts["torso"]
	for x in [-13, -11, -9]:
		for y in [2, 5]:
			check(not body.has_sculpt_cell(Vector3i(x, y, -8)),
					"SRM-6 launcher opening must be empty at the outer rim")
			check_eq(body.sculpt_material(Vector3i(x, y, -5)), 3,
					"SRM-6 must show a recessed inner chamber")
	var gun: VoxelPart = m.parts["right_arm"]
	check(not gun.has_sculpt_cell(Vector3i(0, -6, -17)),
			"right-arm autocannon bore must be hollow")
	check(gun.has_sculpt_cell(Vector3i(-4, -8, -17)),
			"right-arm barrel needs thick armored wall")
	m.free()


func test_new_leg_anatomy_has_joint_rings_and_separated_toes() -> void:
	var m := _make("atlas_as7d")
	var thigh: VoxelPart = m.parts["left_leg"]
	var shin: VoxelPart = m.parts["left_leg_shin"]
	var foot: VoxelPart = m.parts["left_leg_foot"]
	check(thigh.has_sculpt_cell(Vector3i(0, -4, -5)),
			"thigh should carry a protruding front armor plate")
	check(shin.has_sculpt_cell(Vector3i(0, -6, -5)),
			"tapered shin must have raised front armor")
	check(not foot.has_sculpt_cell(Vector3i(-2, -2, -14)),
			"toe gap should be truly open")
	check(foot.has_sculpt_cell(Vector3i(-4, -2, -12)),
			"the lateral toe should have its own solid cap")
	m.free()


func test_palette_covers_all_resculpted_armor_and_structure_roles() -> void:
	check_eq(VoxelPart.PALETTE.size(), VoxelPart.MATERIAL_ROLES.size(),
			"every new microvoxel material requires a visual damage role")
	check_eq(VoxelPart.MATERIAL_ROLES[6], "armor",
			"skull plating is cosmetic armor")
	check_eq(VoxelPart.MATERIAL_ROLES[8], "structure",
			"gunmetal frames expose cosmetic structure when damaged")
	check_eq(VoxelPart.MATERIAL_ROLES[7], "armor",
			"red eye emissive elements do not replace hit locations")
