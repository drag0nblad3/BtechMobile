extends TestCase
## Cheap deterministic checks; full twenty-model integration is in the CI smoke.


func test_highest_voxel_chassis_uses_count_not_hardcoded_name() -> void:
	var profiles: Array[Dictionary] = [
		{"id": "light", "name": "Light", "voxel_detail": 1},
		{"id": "large", "name": "Large", "voxel_detail": 2},
		{"id": "medium", "name": "Medium", "voxel_detail": 1}
	]
	var counts := {"light": 7000, "large": 52830, "medium": 9000}
	var selected := VoxelStressTest.highest_voxel_profile(profiles, counts)
	check_eq(selected.get("id"), "large", "must choose the real highest voxel count")
	counts["medium"] = 67000
	selected = VoxelStressTest.highest_voxel_profile(profiles, counts)
	check_eq(selected.get("id"), "medium", "future model refinements must win automatically")


func test_20_targets_have_distinct_grid_slots() -> void:
	var slots: Dictionary = {}
	for i in VoxelStressTest.TARGET_COUNT:
		var pos := VoxelStressTest.grid_position(i)
		check(not slots.has(pos), "stress models must not overlap")
		slots[pos] = true
		check(absf(pos.x) <= 2.0 * VoxelStressTest.GRID_SPACING + 0.01,
				"model outside floor width")
		check(absf(pos.z) <= 1.5 * VoxelStressTest.GRID_SPACING + 0.01,
				"model outside floor depth")
	check_eq(slots.size(), 20, "grid must reserve exactly twenty distinct positions")


func test_surface_sampler_returns_an_actual_exposed_voxel() -> void:
	var part := VoxelPart.new()
	part.mesh_enabled = false
	part.fill_box(Vector3i.ZERO, Vector3i(7, 7, 7), 1)
	part.seal()
	var rng := RandomNumberGenerator.new()
	rng.seed = 97
	for i in 12:
		var cell := VoxelStressTest.random_surface_cell(part, rng)
		check(part.cells.has(cell), "sample must be an occupied cell")
		var exposed := false
		for direction: Vector3i in VoxelPart.DIRECTIONS:
			if not part.cells.has(cell + direction):
				exposed = true
				break
		check(exposed, "random shot must preferentially target visible armor")
	part.free()


func test_spacious_grid_stays_inside_expanded_floor() -> void:
	check(VoxelStressTest.GRID_SPACING >= 3.5,
			"twenty targets should have more breathing room")
	for i in VoxelStressTest.TARGET_COUNT:
		var pos := VoxelStressTest.grid_position(i)
		check(absf(pos.x) + 2.0 < 13.5,
				"mech and armor should stay inside the enlarged floor")
		check(absf(pos.z) + 2.0 < 13.5,
				"last row must fit the enlarged floor")


func test_zoom_controls_have_normal_and_stress_limits() -> void:
	var lab := VoxelMechLab.new()
	check(lab.zoom_limits().is_equal_approx(Vector2(3.5, 18.0)),
			"solo zoom should permit close and medium views")
	lab.zoom_by(100.0)
	check(is_equal_approx(lab._distance, 18.0),
			"normal zoom-out should stop at 18m")
	lab.zoom_by(0.0001)
	check(is_equal_approx(lab._distance, 3.5),
			"normal zoom-in should stop at 3.5m")
	lab._stress = VoxelStressTest.new()
	lab.reset_zoom()
	check(is_equal_approx(lab._distance, 31.5),
			"stress fit view should show full enlarged formation")
	lab.zoom_by(100.0)
	check(is_equal_approx(lab._distance, 58.0),
			"stress view should zoom out far enough for overview")
	lab.zoom_by(0.0001)
	check(is_equal_approx(lab._distance, 7.0),
			"stress view should zoom in to inspect armor")
	lab._stress.free()
	lab._stress = null
	lab.reset_zoom()
	check(is_equal_approx(lab._distance, 5.8),
			"solo fit view should restore original camera")
	lab.free()
