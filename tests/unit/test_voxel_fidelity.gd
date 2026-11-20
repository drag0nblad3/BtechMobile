extends TestCase
## Higher resolution and deterministic crater damage; deliberately no rendering.


func test_subdivision_preserves_world_size_and_materials() -> void:
	var base := VoxelPart.new()
	base.fill_box(Vector3i.ZERO, Vector3i(1, 1, 1), 1)
	base.seal()
	var detail := VoxelPart.new()
	detail.detail_scale = 2
	detail.fill_box(Vector3i.ZERO, Vector3i(1, 1, 1), 1)
	detail.seal()
	check_eq(base.cells.size(), 8, "baseline cube count")
	check_eq(detail.cells.size(), 64, "interior detail should be 8x as many cubes")
	check(is_equal_approx(detail.voxel_size, VoxelPart.VOXEL_SIZE * 0.5),
			"high-res voxel should be half width")
	check(detail._bounds.size.is_equal_approx(base._bounds.size),
			"subdivision must not resize the original part")
	check_eq(detail.sculpt_material(Vector3i(1, 1, 1)), 1,
			"material must survive subdivision")
	base.free()
	detail.free()


func test_high_res_armor_has_beveled_corners() -> void:
	var part := VoxelPart.new()
	part.detail_scale = 2
	part.armor_box(Vector3i.ZERO, Vector3i(3, 3, 3), 4, 1)
	part.seal()
	check(part.cells.size() < 64 * 8,
			"outer corners should be trimmed from higher-res armor")
	check(part.cells.size() > 64 * 7,
			"beveling must keep nearly all material")
	check(part.has_sculpt_cell(Vector3i.ZERO), "bevel must not erase outer armor cube")
	check_eq(part.sculpt_material(Vector3i(1, 1, 1)), 1,
			"interior should still expose dark framework on damage")
	part.free()


func test_crater_seed_replays_same_irregular_shape() -> void:
	var a := VoxelPart.new()
	var b := VoxelPart.new()
	var c := VoxelPart.new()
	for part in [a, b, c]:
		part.detail_scale = 2
		part.generate_mesh = false
		part.fill_box(Vector3i(-5, -5, -5), Vector3i(5, 5, 5), 0)
		part.seal()
	var pa := a.erase_local_crater(Vector3.ZERO, 0.21, 3151)
	var pb := b.erase_local_crater(Vector3.ZERO, 0.21, 3151)
	var pc := c.erase_local_crater(Vector3.ZERO, 0.21, 99331)
	check(pa > 0 and pa < a._original_count, "crater should remove a local region")
	check_eq(pa, pb, "same seed must remove same number of voxels")
	check(a.cells == b.cells, "same seed must produce identical crater shape")
	check(a.cells != c.cells, "different seeds should vary the crater shape")
	check_eq(a.cells.size(), a._original_count - pa, "removed voxel count should match")
	check(pc > 0, "second crater must remove material")
	a.free()
	b.free()
	c.free()


func test_high_res_ray_picks_occupied_microvoxel() -> void:
	var p := VoxelPart.new()
	p.detail_scale = 2
	p.fill_box(Vector3i.ZERO, Vector3i(1, 1, 1), 1)
	p.seal()
	var hit := p.pick_ray(Vector3(-1.0, 0.06, 0.06), Vector3.RIGHT)
	check(not hit.is_empty(), "ray must hit high-res volume")
	if not hit.is_empty():
		check_eq(hit["cell"], Vector3i(0, 1, 1), "ray should pick the first microvoxel")
		check((hit["point"] as Vector3).distance_to(Vector3(0.0, 0.06, 0.06)) < 0.003,
				"hit should lie on the physical volume surface")
	# This ray passes through actual empty space between the cubes.
	p.free()
	var gap := VoxelPart.new()
	gap.detail_scale = 2
	gap.fill_box(Vector3i(0, 0, 0), Vector3i(0, 0, 0), 1)
	gap.fill_box(Vector3i(0, 0, 3), Vector3i(0, 0, 3), 1)
	gap.seal()
	check(gap.pick_ray(Vector3(-1.0, 0.02, 0.15), Vector3.RIGHT).is_empty(),
			"ray must not strike an empty gap in the occupied bounds")
	gap.free()


func test_count_only_chassis_matches_full_detail_cell_total() -> void:
	var preview := VoxelMech.new()
	preview.profile_id = "jenner_jr7d"
	preview.generate_mesh = false
	preview.build()
	check(preview.initial_voxels > 10000, "Jenner high resolution should have many cells")
	check_eq(preview.initial_voxels, preview.remaining_voxels(),
			"intact Jenner counts must match")
	var part: VoxelPart = preview.parts["torso"]
	check_eq(part.detail_scale, 2, "Jenner must use double linear resolution")
	check(part.get_node_or_null("Surface") == null,
			"count-only version must not create GPU meshes")
	var old := VoxelPart.new()
	VoxelJennerArt.torso(old)
	old.seal()
	check(part.cells.size() > old.cells.size() * 6,
			"Jenner torso must have far more than baseline cell count")
	old.free()
	preview.free()


func test_other_chassis_retain_phone_friendly_resolution() -> void:
	for id in ["prototype", "atlas_as7d", "hunchback_hbk4g",
			"wolverine_wvr6r", "catapult_cplt_c1"]:
		var mech := VoxelMech.new()
		mech.profile_id = id
		mech.generate_mesh = false
		mech.build()
		check_eq((mech.parts["torso"] as VoxelPart).detail_scale, 1,
				id + " must stay at established resolution until refined")
		check(mech.initial_voxels > 0, id + " must have countable voxels")
		mech.free()
