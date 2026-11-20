extends TestCase
## Chassis-specific Jenner JR7-D visual signatures, without touching rules.


func test_jenner_forward_cockpit_and_center_srm() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "jenner_jr7d"
	mech.build()
	var torso: VoxelPart = mech.parts["torso"]
	check_eq(torso.cells.get(Vector3i(0, 1, -15)), 2,
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
			check(foot.cells.has(Vector3i(x, -2, -11)), "missing " + key + " toe")
		check(not foot.cells.has(Vector3i(-1, -2, -11)),
				"first toe gap must remain open")
		check(not foot.cells.has(Vector3i(2, -2, -11)),
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
	visor.erase_ball(visor.to_global(Vector3(0, 0, -1.12)), 0.20)
	check(visor.cells.size() < before, "canopy must be erodible")
	check_eq(arm.cells.size(), other, "torso hit must not damage adjacent laser pod")
	mech.free()
