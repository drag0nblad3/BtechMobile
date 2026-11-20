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
	check(VoxelStressTest.GRID_SPACING >= 5.0,
			"high-detail Atlas shoulders should not overlap neighboring mechs")
	check(absf(VoxelStressTest.grid_position(0).x) <= 11.0,
			"leftmost Atlas should remain inside expanded hangar")
	check(absf(VoxelStressTest.grid_position(19).z) <= 8.0,
			"rearmost Atlas should remain inside expanded hangar")


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
