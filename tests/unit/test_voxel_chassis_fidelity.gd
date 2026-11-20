extends TestCase
## Geometry-level tests for non-Jenner fine detail and full-part impact spread.


func test_atlas_v4_small_death_head_and_torso_ac20() -> void:
	var m := VoxelMech.new()
	m.profile_id = "atlas_as7d"
	m.render_surfaces = false
	m.build()
	var torso: VoxelPart = m.parts["torso"]
	check_eq(torso.detail_scale, 3,
			"V4 skull and pectoral panel outlines are actual 25mm geometry")
	check_eq(torso.sculpt_material(Vector3i(-2, 10, -6)), 7,
			"left Atlas eye must be recessed and not a flat face stripe")
	check_eq(torso.sculpt_material(Vector3i(1, 10, -6)), 7,
			"right Atlas eye should be separately visible")
	check(not torso.has_sculpt_cell(Vector3i(7, -1, -12)),
			"torso AC20 needs a physical empty bore")
	check(torso.has_sculpt_cell(Vector3i(9, -1, -12)),
			"AC20 shroud must have thickness around the empty barrel")
	m.free()


func test_catapult_v4_fifteen_muzzle_racks_per_side() -> void:
	var m := VoxelMech.new()
	m.profile_id = "catapult_cplt_c1"
	m.render_surfaces = false
	m.build()
	for key in ["left_arm", "right_arm"]:
		var pod: VoxelPart = m.parts[key]
		check_eq(pod.detail_scale, 3, "LRM boxes are truly 25mm detailed")
		var openings := 0
		for x in [-4, -2, 0, 2, 4]:
			for y in [0, 3, 6]:
				check(not pod.has_sculpt_cell(Vector3i(x, y, -7)),
						"fifteen physically open missile bores per side")
				check_eq(pod.sculpt_material(Vector3i(x, y, -4)), 3,
						"deep setback missile well must survive as visual chamber")
				openings += 1
		check_eq(openings, 15, "two racks are 15 each, not 6 flat squares")
	m.free()


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
				3,
				id + " torso must use its planned 25mm cockpit detail")
		if id == "catapult_cplt_c1":
			check_eq((model.parts["left_arm"] as VoxelPart).detail_scale, 3,
					"missile pods should keep 25mm apertures")
		check((model.parts["torso"] as VoxelPart).mesh_enabled == false,
				"count probe should never build surfaces")
		model.free()
