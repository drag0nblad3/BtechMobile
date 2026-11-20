extends TestCase
## Rendering fidelity must use the same occupied cells that damage removes.


func _surf(part: VoxelPart) -> Array:
	var instance := part.get_node("Surface") as MeshInstance3D
	var mesh := instance.mesh as ArrayMesh
	return mesh.surface_get_arrays(0)


func test_surface_nets_produces_non_axial_armor_normals() -> void:
	var part := VoxelPart.new()
	part.surface_mode = "nets"
	part.fill_box(Vector3i.ZERO, Vector3i(2, 2, 2), 0)
	part.seal()
	var arrays := _surf(part)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	check(points.size() > 0 and points.size() == normals.size(),
			"smooth voxel mesher must generate a complete render surface")
	var diagonal := false
	for normal in normals:
		if absf(normal.x) > 0.01 and absf(normal.y) > 0.01:
			diagonal = true
			break
	check(diagonal, "corners must shade diagonally, not as axis-aligned cubes")
	check_eq(part.cells.size(), 27, "smoothing must not add or erase damage cells")
	part.free()


func test_surface_nets_holes_stay_empty_after_mesh_rebuild() -> void:
	var part := VoxelPart.new()
	part.surface_mode = "nets"
	part.detail_scale = 2
	part.fill_box(Vector3i(-3, -3, -6), Vector3i(3, 3, 3), 4)
	part.carve_box(Vector3i(-1, -1, -6), Vector3i(1, 1, -1))
	part.seal()
	var before := part.cells.size()
	check(not part.cells.has(Vector3i(0, 0, -12)),
			"real muzzle channel should remain empty after refinement")
	var arrays := _surf(part)
	check((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() > 0,
			"the tube must retain a rendered outer shell and an inner cavity")
	var destroyed := part.erase_irregular_local_ball(
			Vector3(0, 0, -0.25), 0.12, 1901)
	check(destroyed > 0, "smoothing must not disable voxel damage")
	check_eq(part.cells.size(), before - destroyed,
			"damage counts are unchanged by smooth mesh extraction")
	part.free()


func test_real_mech_parts_use_smooth_geometry_not_chunky_cube_faces() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "atlas_as7d"
	mech.render_surfaces = false
	mech.build()
	for key: String in mech.parts:
		check_eq((mech.parts[key] as VoxelPart).surface_mode, "cube",
				"meshless count probes need no surface-net allocations")
	mech.free()
	var visible := VoxelPart.new()
	visible.surface_mode = "nets"
	visible.armor_box(Vector3i.ZERO, Vector3i(1, 1, 1), 0, 1)
	visible.seal()
	check(visible.has_node("Surface"),
			"mesh-visible parts must support actual faceted surface geometry")
	visible.free()


func test_surface_nets_keeps_separate_color_bands() -> void:
	var part := VoxelPart.new()
	part.surface_mode = "nets"
	part.fill_box(Vector3i(-2, 0, -2), Vector3i(-1, 3, 2), 4)
	part.fill_box(Vector3i(0, 0, -2), Vector3i(1, 3, 2), 8)
	part.seal()
	var arrays := _surf(part)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var blue := false
	var metal := false
	for color in colors:
		if color.is_equal_approx(VoxelPart.PALETTE[4]):
			blue = true
		elif color.is_equal_approx(VoxelPart.PALETTE[8]):
			metal = true
	check(blue and metal,
			"smoothing must preserve distinct armor and exposed-frame colors")
	part.free()
