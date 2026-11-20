extends TestCase
## Regression coverage for phase opposition, feet and voxel erosion.


func test_opposite_stance_positions() -> void:
	var left := VoxelGait.foot_target(0.0)
	var right := VoxelGait.foot_target(0.5)
	check(left.x > 0.35, "left foot should be in front")
	check(right.x < -0.20, "right foot should be behind")
	left = VoxelGait.foot_target(0.5)
	right = VoxelGait.foot_target(1.0)
	check(left.x < -0.20, "left foot should move behind")
	check(right.x > 0.35, "right foot should move in front")


func test_swing_foot_clears_ground() -> void:
	for p in [0.0, 0.2, 0.5]:
		check(is_equal_approx(VoxelGait.foot_target(p).y, VoxelGait.ANKLE_HEIGHT),
			"stance foot must not lift")
	check(VoxelGait.foot_target(0.80).y > VoxelGait.ANKLE_HEIGHT + 0.20,
		"swing foot needs clearance")


func test_ik_reaches_target() -> void:
	for i in 20:
		var phase := float(i) / 20.0
		var target := VoxelGait.foot_target(phase)
		var angles := VoxelGait.sample(phase, 1.36)
		var forward := VoxelGait.THIGH * sin(angles.x) \
			+ VoxelGait.SHIN * sin(angles.x + angles.y)
		var down := VoxelGait.THIGH * cos(angles.x) \
			+ VoxelGait.SHIN * cos(angles.x + angles.y)
		check(absf(forward - target.x) < 0.005, "IK forward miss at phase %.2f" % phase)
		check(absf(down - (1.36 - target.y)) < 0.005, "IK vertical miss at phase %.2f" % phase)


func test_voxel_erase_is_local() -> void:
	var part := VoxelPart.new()
	part.fill_box(Vector3i.ZERO, Vector3i(5, 5, 5), 0)
	var initial := part.cells.size()
	var removed := part.erase_ball(Vector3(0.10, 0.10, 0.10), 0.12)
	check(removed > 0 and removed < initial, "blast must not erase all voxels")
	check_eq(part.cells.size(), initial - removed, "erased cells remain gone")
	part.free()


func test_mesh_hides_internal_faces() -> void:
	var part := VoxelPart.new()
	part.fill_box(Vector3i.ZERO, Vector3i(1, 0, 0), 0)
	part.rebuild()
	var mesh := (part.get_node("Surface") as MeshInstance3D).mesh as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	check_eq((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), 60,
		"two adjacent cubes should render ten faces")
	part.free()
