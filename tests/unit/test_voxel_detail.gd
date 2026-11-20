extends TestCase
## High-resolution voxel geometry, per-model counts, fast picking, random damage.


func test_refinement_uses_eight_real_smaller_cells() -> void:
	var part := VoxelPart.new()
	part.detail_scale = 2
	part.fill_box(Vector3i.ZERO, Vector3i.ZERO, 0)
	part.seal()
	check_eq(part.cells.size(), 8, "2x linear resolution should create 8 voxels")
	check_eq(part._original_count, 8, "counter must include all refined voxels")
	check(is_equal_approx(part.voxel_size, 0.0375), "voxel pitch should be 37.5mm")
	var mesh := (part.get_node("Surface") as MeshInstance3D).mesh as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	check_eq((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), 144,
			"subdivided cube should expose 24 small outside faces")
	part.free()


func test_high_detail_jenner_counts_real_meshless_geometry() -> void:
	var standard := VoxelMech.new()
	standard.profile_id = "jenner_jr7d"
	standard.render_surfaces = false
	standard.build()
	var n := standard.initial_voxels()
	check(n > 0, "standard model needs voxels")
	check_eq(standard.remaining_voxels(), n, "initial count must match")
	var detail := VoxelMech.new()
	detail.profile_id = "jenner_jr7d"
	detail.detail_level = 2
	detail.render_surfaces = false
	detail.build()
	var high := detail.initial_voxels()
	check(high > n * 7, "Jenner must have materially more cells, not just a label")
	check(high <= n * 8 + 100, "high detail must remain within bounded 2x resolution")
	check(is_equal_approx(detail.parts["torso"].voxel_size, 0.0375),
			"Jenner high detail pitch must be halved")
	check_eq(detail.remaining_voxels(), high, "catalog must count actual occupied voxels")
	check(not detail.parts["torso"].has_node("Surface"),
			"catalog counting should never build GPU meshes")
	standard.free()
	detail.free()


func test_fine_jenner_has_real_micro_cuts_and_paint() -> void:
	var part := VoxelPart.new()
	part.name = "Torso"
	part.detail_scale = 2
	part.detail_style = "jenner"
	part.mesh_enabled = false
	VoxelJennerArt.torso(part)
	part.seal()
	check_eq(part.cells.get(Vector3i(0, 4, -30)), 1,
			"fine cockpit center seam should be a single dark voxel")
	check(not part.cells.has(Vector3i(-2, 1, -42)),
			"canopy tip must include real micro-bevel negative space")
	check(is_equal_approx(part.voxel_size, 0.0375), "art must use finer geometry")
	part.free()


func test_raycast_traverses_holes_and_finds_occupied_cell() -> void:
	var part := VoxelPart.new()
	part.fill_box(Vector3i.ZERO, Vector3i(2, 0, 0), 0)
	part.carve_box(Vector3i(1, 0, 0), Vector3i(1, 0, 0))
	part.mesh_enabled = false
	part.seal()
	var hit := part.pick_ray(Vector3(0.11, 0.0375, 0.0375), Vector3.RIGHT)
	check_eq(hit.get("cell"), Vector3i(2, 0, 0),
			"ray should travel through empty lattice and hit next real voxel")
	var miss := part.pick_ray(Vector3(-0.2, 0.2, 0.2), Vector3.RIGHT)
	check(miss.is_empty(), "ray outside occupied bounds must not hit")
	var reverse := part.pick_ray(Vector3(0.30, 0.0375, 0.0375), Vector3.LEFT)
	check_eq(reverse.get("cell"), Vector3i(2, 0, 0),
			"ray from right should hit front cell")
	part.free()


func _dense_target() -> VoxelPart:
	var part := VoxelPart.new()
	part.mesh_enabled = false
	part.detail_scale = 2
	part.fill_box(Vector3i.ZERO, Vector3i(7, 7, 7), 0)
	part.seal()
	return part


func test_random_impact_is_local_and_reproducible_by_seed() -> void:
	var a := _dense_target()
	var b := _dense_target()
	var c := _dense_target()
	var count := a.cells.size()
	var center := Vector3(0.28, 0.28, 0.28)
	var hit_a := a.erase_irregular_local_ball(center, 0.13, 1701)
	var hit_b := b.erase_irregular_local_ball(center, 0.13, 1701)
	var hit_c := c.erase_irregular_local_ball(center, 0.13, 1702)
	check(hit_a > 0 and hit_a < count, "crater must remove some but not all voxels")
	check_eq(hit_a, hit_b, "same seed should remove the same count")
	check(a.cells == b.cells, "same seed should make identical crater topology")
	check(a.cells != c.cells, "different seed must vary the shape")
	check(c.cells.has(Vector3i.ZERO), "remote armor should be untouched")
	check_eq(a.cells.size(), count - hit_a, "voxel count must track random erosion")
	a.free()
	b.free()
	c.free()


func test_profile_catalog_reports_each_model_original_cells() -> void:
	var seen: Dictionary = {}
	for profile in VoxelChassis.all():
		var id := str(profile["id"])
		var model := VoxelMech.new()
		model.profile_id = id
		model.detail_level = int(profile.get("voxel_detail", 1))
		model.render_surfaces = false
		model.build()
		var count := model.initial_voxels()
		check(count > 0, "every catalog profile must contain real voxels: " + id)
		check_eq(count, model.remaining_voxels(), "catalog count mismatch: " + id)
		seen[id] = count
		model.free()
	check(seen["jenner_jr7d"] > seen["prototype"],
			"fine Jenner should have more voxels than the starter model")
