extends TestCase
## Geometry-level tests for non-Jenner fine detail and full-part impact spread.


func test_atlas_25mm_visor_and_armor_recess() -> void:
	var torso := VoxelPart.new()
	torso.name = "Torso"
	torso.detail_scale = 3
	torso.detail_style = "atlas"
	torso.mesh_enabled = false
	VoxelMechArt.torso(torso, "atlas")
	check(is_equal_approx(torso.voxel_size, 0.025), "Atlas hull pitch must be 25 mm")
	check_eq(torso.cells.get(Vector3i(0, 16, -12)), 1,
			"Atlas cockpit must have a real inset center window strut")
	check(not torso.cells.has(Vector3i(0, -14, -15)),
			"Atlas chest plate needs recessed transverse seams")
	check_eq(torso.cells.get(Vector3i(0, -13, -14)), 1,
			"Atlas chest recess should show frame material")
	torso.free()


func test_catapult_15_separate_recessed_missile_ports_on_each_pod() -> void:
	for side in 2:
		var pod := VoxelPart.new()
		pod.name = "left_arm" if side == 0 else "right_arm"
		pod.detail_scale = 3
		pod.detail_style = "catapult"
		pod.mesh_enabled = false
		VoxelMechArt.arm(pod, "missile_pods", side)
		check(is_equal_approx(pod.voxel_size, 0.025), "LRM pod must use 25 mm cells")
		var ports := 0
		for col in 5:
			for row in 3:
				var x := -10 + col * 5
				var y := -5 + row * 7
				check(not pod.cells.has(Vector3i(x, y, -29)),
						"launcher opening must be physically recessed")
				check_eq(pod.cells.get(Vector3i(x, y, -26)), 3,
						"missile tube must have a deeper contrasting interior")
				check(pod.cells.has(Vector3i(x - 1, y - 1, -29)),
						"every missile tube must have a raised rim")
				ports += 1
		check_eq(ports, 15, "CPLT-C1 needs fifteen apertures per pod")
		pod.free()


func test_random_damage_targets_full_part_surface() -> void:
	var part := VoxelPart.new()
	part.mesh_enabled = false
	part.armor_box(Vector3i(-11, -8, -8), Vector3i(11, 8, 8), 0, 1)
	part.seal()
	var rng := RandomNumberGenerator.new()
	rng.seed = 8675309
	var min_x := INF
	var min_y := INF
	var min_z := INF
	var max_x := -INF
	var max_y := -INF
	var max_z := -INF
	var successful := 0
	for n in 120:
		var hit := VoxelStressTest.random_surface_hit(part, rng)
		if hit.is_empty():
			continue
		var point: Vector3 = hit["point"]
		successful += 1
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
		min_z = minf(min_z, point.z)
		max_z = maxf(max_z, point.z)
	check(successful > 115, "surface sampling should hit dense armor almost every time")
	check(max_x - min_x > part._local_bounds.size.x * 0.70,
			"hit spread must cover the length of the target part")
	check(max_y - min_y > part._local_bounds.size.y * 0.70,
			"hit spread must cover its vertical surface")
	check(max_z - min_z > part._local_bounds.size.z * 0.70,
			"hit spread must cover its depth")
	part.free()


func test_wide_impact_removes_larger_patch() -> void:
	var small := VoxelPart.new()
	var large := VoxelPart.new()
	for part in [small, large]:
		part.mesh_enabled = false
		part.detail_scale = 2
		part.fill_box(Vector3i(-9, -9, -9), Vector3i(9, 9, 9), 0)
		part.seal()
	var tiny := small.erase_irregular_local_ball(Vector3.ZERO, 0.13, 1701)
	var broad := large.erase_irregular_local_ball(Vector3.ZERO, 0.34, 1701)
	check(tiny > 0, "reference impact must remove geometry")
	check(broad > tiny * 4, "new broader impact must affect much more armor")
	small.free()
	large.free()
