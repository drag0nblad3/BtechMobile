extends TestCase
## Mesh-first QA: imported author surfaces are independent of voxels.
## The actual sparse 25/37.5mm damage model is rasterized from triangles.


func _atlas() -> VoxelMech:
	var m := VoxelMech.new()
	m.profile_id = "atlas_as7d"
	m.detail_level = int(VoxelChassis.find("atlas_as7d").get("voxel_detail", 2))
	m.render_surfaces = false
	m.build()
	return m


func test_source_artists_mesh_is_real_triangles_not_legacy_cube_sculpt() -> void:
	for key in ["torso", "left_arm", "right_arm", "left_leg", "right_leg",
			"left_leg_shin", "right_leg_shin", "left_leg_foot",
			"right_leg_foot"]:
		var meshes := AtlasSourceMesh.part_meshes(key)
		check(meshes.size() >= 3, "source part %s needs several authored meshes" % key)
		var faces := 0
		for component: Dictionary in meshes:
			var tris: PackedVector3Array = component["tris"]
			check(tris.size() % 3 == 0, "triangular source faces must be complete")
			faces += tris.size() / 3
		check(faces > 50, "%s needs a real editable 3D mesh" % key)
		var exported: ArrayMesh = AtlasSourceMesh.source_mesh(key)
		check(exported.get_surface_count() > 0,
				"artist source should be inspectable/exportable before voxelization")


func test_atlas_prototype_is_baked_directly_from_mesh_not_old_boxes() -> void:
	var m := _atlas()
	var body: VoxelPart = m.parts["torso"]
	check_eq(body.detail_style, "mesh_atlas",
			"Atlas should bypass all old V2 V3 V4 box/sphere sculptors")
	check_eq(body.detail_scale, 3,
			"high detail source-mesh Atlas torso uses real 25mm cells")
	check(is_equal_approx(body.voxel_size, 0.025),
			"mesh voxels are generated at final density, not re-split cubes")
	check(body.cells.size() > 50000, "sculpted source torso must contain volume")
	check(m.initial_voxels() >= 100000 and m.initial_voxels() <= 150000,
			"Atlas must remain in original 100k–150k count budget")
	m.free()


func _eye_red_count(part: VoxelPart, center_x: float) -> int:
	var count := 0
	var scale: int = part.detail_scale
	for ix in range(floori((center_x - 0.8) * scale),
			ceili((center_x + 0.8) * scale) + 1):
		for iy in range(floori(8.3 * scale), ceili(10.1 * scale) + 1):
			for iz in range(floori(-8.2 * scale), ceili(-6.0 * scale) + 1):
				if int(part.cells.get(Vector3i(ix, iy, iz), -1)) == 7:
					count += 1
	return count


func test_source_skull_eye_cavities_are_bored_and_colored_inset() -> void:
	var m := _atlas()
	var head: VoxelPart = m.parts["torso"]
	check(_eye_red_count(head, -1.65) > 3,
			"left eye contains actual red inset voxels set back from front brow")
	check(_eye_red_count(head, 1.55) > 3,
			"right eye uses a separately authored red inset")
	check(not head.has_sculpt_cell(Vector3i(-8, 12, -3)),
			"Atlas skull cannot be giant broad rectangle")
	m.free()


func test_torso_ac20_is_truly_hollow_and_left_lrm_ports_open() -> void:
	var m := _atlas()
	var p: VoxelPart = m.parts["torso"]
	var s: int = p.detail_scale
	var empty_bore := true
	var outer_wall := false
	for iz in range(-31, -27):
		for ix in range(24, 27):
			for iy in range(-7, -4):
				if p.cells.has(Vector3i(ix, iy, iz)):
					empty_bore = false
	# Slightly to the right of the centre of AC/20 annulus.
	for iz in range(-31, -27):
		for ix in range(29, 33):
			for iy in range(-7, -4):
				if p.cells.has(Vector3i(ix, iy, iz)):
					outer_wall = true
	check(empty_bore, "AC20 must be drilled, not capped with a painted circle")
	check(outer_wall, "AC20 requires real armor around the void")
	# The left chest five-port launcher has a separate physical recess.
	var open_port := true
	for ix in range(-30, -27):
		for iz in range(-27, -24):
			if p.cells.has(Vector3i(ix, -4, iz)):
				open_port = false
	check(open_port, "missile mouth must have genuine negative-space geometry")
	m.free()


func test_cached_source_mesh_is_reused_but_damage_is_per_clone() -> void:
	var a := _atlas()
	var bake_passes := AtlasMeshVoxelizer.bake_count
	var b := _atlas()
	check_eq(AtlasMeshVoxelizer.bake_count, bake_passes,
			"20/60 stress cloning must reuse mesh voxelization cache")
	var torso_a: VoxelPart = a.parts["torso"]
	var torso_b: VoxelPart = b.parts["torso"]
	var count_a := torso_a.cells.size()
	var count_b := torso_b.cells.size()
	check_eq(count_a, count_b, "fresh mech clones should start identical")
	var damage := torso_a.erase_irregular_local_ball(Vector3(0, -0.1, -0.15),
			0.22, 91824)
	check(damage > 0, "source-voxelized armor must accept real random damage")
	check_eq(torso_a.cells.size(), count_a - damage,
			"removed voxels must be counted directly")
	check_eq(torso_b.cells.size(), count_b,
			"impact on one Atlas cannot erase cached geometry in another")
	a.free()
	b.free()


func test_leg_geometry_is_longer_than_thick_and_jointed() -> void:
	var m := _atlas()
	for key in ["left_leg", "right_leg", "left_leg_shin", "right_leg_shin"]:
		var p: VoxelPart = m.parts[key]
		check(p._local_bounds.size.y > p._local_bounds.size.x * 1.25,
				"%s must be long articulated leg, not a trunk" % key)
		check(p.cells.size() > 900,
				"actual humanlike armor and hinge volume must exist")
	m.free()
