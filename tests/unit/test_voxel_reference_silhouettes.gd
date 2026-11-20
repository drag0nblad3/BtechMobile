extends TestCase
## Art-reference silhouette gates: different chassis must NOT devolve into
## the same biped with a larger box or a different cockpit paint color.


func _mech(id: String) -> VoxelMech:
	var m := VoxelMech.new()
	m.profile_id = id
	m.render_surfaces = false
	m.build()
	return m


func test_atlas_has_small_skull_between_broad_armored_shoulders() -> void:
	var m := _mech("atlas_as7d")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(-3, 9, -8)),
			"Atlas must retain a recognizable small death's-head face")
	check(not body.has_sculpt_cell(Vector3i(-7, 13, -5)),
			"Atlas helmet must not be a giant isolated skull dome")
	check(body.has_sculpt_cell(Vector3i(10, 1, 0)),
			"broad independent shoulders are its main silhouette cue")
	check(body.has_sculpt_cell(Vector3i(-10, 1, 0)),
			"both shoulder pauldrons need real volume")
	check(not body.has_sculpt_cell(Vector3i(9, -1, -12)),
			"torso autocannon must remain hollow")
	m.free()


func test_hunchback_cannon_tower_is_sided_and_rectangular() -> void:
	var m := _mech("hunchback_hbk4g")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(12, 10, 4)),
			"the right torso must rise into the heavy weapon housing")
	check(not body.has_sculpt_cell(Vector3i(-12, 10, 4)),
			"the left torso must stay lower and visibly asymmetric")
	check(not body.has_sculpt_cell(Vector3i(7, 6, -17)),
			"AC/20 must emerge from a real bored cannon tube")
	check(body.has_sculpt_cell(Vector3i(10, 6, -17)),
			"bored cannon needs a visible exterior ring")
	m.free()


func test_wolverine_has_upright_glazed_cockpit_and_six_pack_launcher() -> void:
	var m := _mech("wolverine_wvr6r")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(2, 12, -3)),
			"upright sensor tower should project above the cockpit")
	check_eq(body.sculpt_material(Vector3i(0, 7, -9)), 1,
			"two windscreen halves should be separated by a dark mullion")
	for x in [-13, -11, -9]:
		for y in [2, 5]:
			check(not body.has_sculpt_cell(Vector3i(x, y, -8)),
					"each of six shoulder missile mouths must be physically open")
	var cannon: VoxelPart = m.parts["right_arm"]
	check(not cannon.has_sculpt_cell(Vector3i(0, -6, -17)),
			"arm-mounted autocannon must be hollow and not mirrored")
	m.free()


func test_catapult_is_narrow_beaked_without_big_cyan_head() -> void:
	var m := _mech("catapult_cplt_c1")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(0, 0, -17)),
			"Catapult has a low pointed aircraft nose")
	check(not body.has_sculpt_cell(Vector3i(4, 0, -17)),
			"nose must taper rather than fill a square cockpit")
	check(body.has_sculpt_cell(Vector3i(0, 2, -12)),
			"front glazing should be a small inset between the pods")
	var l: VoxelPart = m.parts["left_arm"]
	var r: VoxelPart = m.parts["right_arm"]
	check_eq(l.detail_scale, 3, "fifteen LRM tube rims use 25mm detail")
	check_eq(l.cells.size(), r.cells.size(),
			"pod armor should remain paired and recognizably symmetric")
	m.free()


func test_jenner_is_long_nosed_with_two_laser_nacelles_and_hocks() -> void:
	var m := _mech("jenner_jr7d")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(0, 0, -23)),
			"Jenner needs its famous long projecting aerospace nose")
	check(not body.has_sculpt_cell(Vector3i(4, 0, -23)),
			"nose tip cannot look like a blunt box")
	for key in ["left_arm", "right_arm"]:
		var nacelle: VoxelPart = m.parts[key]
		for y in [-2, 1]:
			check_eq(nacelle.sculpt_material(Vector3i(0, y, -11)), 2,
					"both separate laser emitters must remain visible")
	check_eq(m.hocks.size(), 2,
			"the Jenner must keep its reverse-jointed three-link legs")
	m.free()


func test_prototype_is_identifiable_by_sensor_mast_and_test_weapon() -> void:
	var m := _mech("prototype")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(3, 14, 1)),
			"noncanonical test chassis needs its taller asymmetrical antenna")
	var cannon: VoxelPart = m.parts["left_arm"]
	check(not cannon.has_sculpt_cell(Vector3i(-1, -7, -12)),
			"test left arm should be a bored instrument cannon")
	var claw: VoxelPart = m.parts["right_arm"]
	check(claw.cells.size() != cannon.cells.size(),
			"the other arm must be a true manipulator, not a clone")
	m.free()
