extends TestCase
## Strict actual geometry landmarks from the two references per chassis.
## V4 is a clean rebuild; the old v2/v3 surface coordinates were discarded.

func _make(id: String) -> VoxelMech:
	var m := VoxelMech.new()
	m.profile_id = id
	m.detail_level = int(VoxelChassis.find(id).get("voxel_detail", 2))
	m.render_surfaces = false
	m.build()
	return m


func test_atlas_shoulders_skull_and_torso_weapons_are_separate() -> void:
	var m := _make("atlas_as7d")
	var h: VoxelPart = m.parts["torso"]
	check(h.has_sculpt_cell(Vector3i(-12, 2, 0)) and
			h.has_sculpt_cell(Vector3i(12, 2, 0)),
			"Atlas requires wide independent armored shoulders")
	check(not h.has_sculpt_cell(Vector3i(-8, 12, -4)),
			"small skull must not grow into wide shoulder-shaped helmet")
	check_eq(h.sculpt_material(Vector3i(-2, 8, -6)), 7,
			"left skull eye must have inset red glazing")
	check_eq(h.sculpt_material(Vector3i(1, 8, -6)), 7,
			"right skull eye must remain separate")
	check(not h.has_sculpt_cell(Vector3i(7, -1, -12)),
			"torso AC20 must have a real empty bore")
	check(h.has_sculpt_cell(Vector3i(9, -1, -12)),
			"AC20 must have a separate annular shroud")
	check(not h.has_sculpt_cell(Vector3i(-9, -1, -10)),
			"left LRM exit must not be a painted flat panel")
	m.free()


func test_hunchback_cannon_tower_dominates_and_arms_are_small() -> void:
	var m := _make("hunchback_hbk4g")
	var h: VoxelPart = m.parts["torso"]
	check(h.has_sculpt_cell(Vector3i(10, 11, 0)),
			"high square right shoulder AC20 tower must dominate silhouette")
	check(not h.has_sculpt_cell(Vector3i(-10, 11, 0)),
			"cannon tower may not be mirrored onto left shoulder")
	check_eq(h.sculpt_material(Vector3i(-4, 8, -6)), 2,
			"compact offset cockpit must survive, left of the huge cannon")
	check(not h.has_sculpt_cell(Vector3i(8, 9, -17)),
			"right torso AC20 has a deep drilled barrel")
	check(h.has_sculpt_cell(Vector3i(10, 9, -17)),
			"large muzzle armor wraps the central bore")
	check(m.parts["left_arm"].cells.size() < h.cells.size() / 12,
			"Hunchback arms should be small beside the large cannon carriage")
	m.free()


func test_wolverine_upright_helmet_srm6_and_right_arm_cannon() -> void:
	var m := _make("wolverine_wvr6r")
	var h: VoxelPart = m.parts["torso"]
	check_eq(h.sculpt_material(Vector3i(0, 9, -6)), 2,
			"tall angular cockpit must have visible window")
	check(h.has_sculpt_cell(Vector3i(2, 15, 1)),
			"upright Wolverine should have prominent sensor antennas")
	for x in [-11, -9, -7]:
		for y in [7, 10]:
			check(not h.has_sculpt_cell(Vector3i(x, y, -10)),
					"six SRM tubes must have genuine empty mouths")
			check_eq(h.sculpt_material(Vector3i(x, y, -5)), 3,
					"missile rack needs setback rear chambers")
	var gun: VoxelPart = m.parts["right_arm"]
	check(not gun.has_sculpt_cell(Vector3i(0, -8, -17)),
			"right arm AC5 must be genuinely bored")
	check(gun.has_sculpt_cell(Vector3i(2, -8, -17)),
			"AC5 sleeve must remain substantial")
	m.free()


func test_jenner_is_long_nosed_not_a_robot_with_hand_arms() -> void:
	var m := _make("jenner_jr7d")
	var h: VoxelPart = m.parts["torso"]
	check(h.has_sculpt_cell(Vector3i(0, 0, -25)),
			"Jenner nose must reach well ahead of its leg root")
	check(not h.has_sculpt_cell(Vector3i(4, 0, -25)),
			"front nose must taper to a point")
	check_eq(h.sculpt_material(Vector3i(0, 1, -18)), 2,
			"low forward cockpit glazing must wrap the wedge")
	for key in ["left_arm", "right_arm"]:
		var laser: VoxelPart = m.parts[key]
		for y in [-2, 2]:
			check(not laser.has_sculpt_cell(Vector3i(0, y, -12)),
					"each side needs two DISTINCT hollow laser emitters")
			check_eq(laser.sculpt_material(Vector3i(0, y, -2)), 2,
					"separate cyan laser chambers should sit behind openings")
	check_eq(m.hocks.size(), 2, "Jenner needs its actual third leg pivot")
	m.free()


func test_catapult_has_small_beak_and_thirty_real_missile_openings() -> void:
	var m := _make("catapult_cplt_c1")
	var h: VoxelPart = m.parts["torso"]
	check(h.has_sculpt_cell(Vector3i(0, 0, -19)),
			"aircraft beak must reach ahead of the racks")
	check(not h.has_sculpt_cell(Vector3i(4, 0, -19)),
			"beak must be slender, not a square humanoid head")
	for key in ["left_arm", "right_arm"]:
		var pod: VoxelPart = m.parts[key]
		check(pod.has_sculpt_cell(Vector3i(0, 13, 0)),
				"missile rack must stand high above the tiny fuselage")
		for x in [-4, -2, 0, 2, 4]:
			for y in [0, 3, 6]:
				check(not pod.has_sculpt_cell(Vector3i(x, y, -7)),
						"all fifteen tubes must be open, not flat painted spots")
				check_eq(pod.sculpt_material(Vector3i(x, y, -4)), 3,
						"fifteen chambers require visible dark recesses")
	check_eq(m.hocks.size(), 2, "Catapult must have distinct avian hocks")
	m.free()


func test_noncanon_prototype_is_asymmetric_survey_walker() -> void:
	var m := _make("prototype")
	var body: VoxelPart = m.parts["torso"]
	check(body.has_sculpt_cell(Vector3i(5, 19, 2)),
			"survey antenna must project much higher than the helmet")
	var left: VoxelPart = m.parts["left_arm"]
	var right: VoxelPart = m.parts["right_arm"]
	check(not left.has_sculpt_cell(Vector3i(0, -8, -15)),
			"test cannon is a bored tool, not a solid cube")
	check(right.has_sculpt_cell(Vector3i(4, -15, -6)),
			"opposite arm must have a distinct visible claw prong")
	check(left.cells.size() != right.cells.size(),
			"different arm silhouettes cannot be identical casts")
	m.free()
