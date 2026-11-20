extends TestCase
## Geometry-level tests for non-Jenner fine detail and full-part impact spread.


func test_atlas_skull_eyes_and_torso_autocannon_are_real_geometry() -> void:
	var m := VoxelMech.new()
	m.profile_id = "atlas_as7d"
	m.render_surfaces = false
	m.build()
	var torso: VoxelPart = m.parts["torso"]
	check_eq(torso.detail_scale, 2, "sculpted Atlas torso uses 37.5 mm cells")
	for x in [-3, 2]:
		check_eq(torso.sculpt_material(Vector3i(x, 9, -8)), 7,
				"skull face needs inset red eye lights")
	check(not torso.has_sculpt_cell(Vector3i(0, 6, -10)),
			"Atlas skull should have a real recessed nose cavity")
	check(torso.has_sculpt_cell(Vector3i(-5, 6, -7)),
			"skull cheekbone needs volume, not a painted visor")
	check(not torso.has_sculpt_cell(Vector3i(9, -1, -12)),
			"torso AC/20 barrel should have an actual hollow bore")
	check(torso.has_sculpt_cell(Vector3i(12, -1, -12)),
			"armored AC/20 ring should surround the muzzle")
	check(not torso.has_sculpt_cell(Vector3i(-13, 1, -9)),
			"Atlas LRM launcher must have real openings")
	m.free()


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


func test_atlas_catapult_voxel_budget_and_damageable_real_geometry() -> void:
	for id in ["atlas_as7d", "catapult_cplt_c1"]:
		var profile := VoxelChassis.find(id)
		var model := VoxelMech.new()
		model.profile_id = id
		model.detail_level = int(profile["voxel_detail"])
		model.render_surfaces = false
		model.build()
		var total := model.initial_voxels()
		# Approximate art budget, not a magic exact cell target.
		check(total >= 100000 and total <= 150000,
				id + " should fit the sculpted 100–150k model budget")
		check_eq(total, model.remaining_voxels(),
				id + " should count real intact geometry")
		check_eq((model.parts["torso"] as VoxelPart).detail_scale,
				2,
				id + " torso must use its planned microvoxel resolution")
		if id == "catapult_cplt_c1":
			check_eq((model.parts["left_arm"] as VoxelPart).detail_scale, 3,
					"missile pods should keep 25mm apertures")
		check((model.parts["torso"] as VoxelPart).mesh_enabled == false,
				"count probe should never build surfaces")
		model.free()
