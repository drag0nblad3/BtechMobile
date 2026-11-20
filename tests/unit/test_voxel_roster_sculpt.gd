extends TestCase
## Physical model metrics after deleting all legacy shared-silhouette builders.


func _make(id: String) -> VoxelMech:
	var m := VoxelMech.new()
	m.profile_id = id
	m.detail_level = int(VoxelChassis.find(id).get("voxel_detail", 2))
	m.render_surfaces = false
	m.build()
	return m


func test_all_six_models_use_real_100k_150k_cells_not_fat_limb_fillers() -> void:
	var count := 0
	for profile in VoxelChassis.all():
		var m := _make(str(profile["id"]))
		var n := m.initial_voxels()
		check(n > 100000 and n <= 150000,
				"%s: %d cells must fit 100k–150k actual physical budget" % [profile["id"], n])
		check_eq(n, m.remaining_voxels(),
				"voxel counts must equal real surviving damageable geometry")
		check(not (m.parts["torso"] as VoxelPart).mesh_enabled,
				"meshless budget check should never allocate GPU surfaces")
		for part: VoxelPart in m.parts.values():
			var roles := part.role_counts()
			check_eq(roles["armor"] + roles["structure"], part.cells.size(),
					"no reference-v4 cell may lack a visual armor/structure role")
		count += 1
		m.free()
	check_eq(count, 6, "must cover the complete lab roster")


func test_profiles_are_tall_enough_to_avoid_original_squat_proportions() -> void:
	for profile in VoxelChassis.all():
		var m := _make(str(profile["id"]))
		var frame: Node3D = m.get_node("Frame")
		check(frame.scale.y >= 1.25,
				"%s needs visibly taller proportions than original shared biped" % profile["id"])
		var torso: VoxelPart = m.parts["torso"]
		var bounds := torso._local_bounds
		check(bounds.size.y > 0.5,
				"torso must have multiple individually shaped vertical sections")
		check(m.hips[0].position.x < 0.0 and m.hips[1].position.x > 0.0,
				"left/right hip sockets must remain physically separated")
		m.free()


func test_conventional_calves_are_long_slender_parts_not_tree_trunks() -> void:
	for id in ["atlas_as7d", "hunchback_hbk4g",
			"wolverine_wvr6r", "prototype"]:
		var m := _make(id)
		var shin: VoxelPart = m.parts["left_leg_shin"]
		var b := shin._local_bounds
		check(b.size.y > b.size.x * 1.18,
				"%s lower leg should be substantially longer than thick" % id)
		check(not shin.has_sculpt_cell(Vector3i(8, -5, 0)),
				"thin calf cannot extend to enormous solid tree-trunk radius")
		check(shin.has_sculpt_cell(Vector3i(0, -9, 0)),
				"calf actuator should genuinely reach its ankle")
		m.free()


func test_bird_legs_expose_three_distinct_load_bearing_links() -> void:
	for id in ["jenner_jr7d", "catapult_cplt_c1"]:
		var m := _make(id)
		for part_key in ["left_leg", "left_leg_shin", "left_leg_metatarsal"]:
			var part: VoxelPart = m.parts[part_key]
			check(part.cells.size() > 0,
					"%s should have a true independently damageable hock link" % id)
			check(part._local_bounds.size.x < 0.90,
					"avian joint must be narrow, not a solid humanoid boot shaft")
		check_eq(m.hocks.size(), 2,
				"both legs require actual visible reverse-jointed pivots")
		m.free()


func test_new_reference_parts_still_take_local_damage_and_survive_report() -> void:
	var m := _make("atlas_as7d")
	var h: VoxelPart = m.parts["torso"]
	var shin: VoxelPart = m.parts["right_leg_shin"]
	var a := h.cells.size()
	var b := shin.cells.size()
	var n := h.erase_irregular_local_ball(Vector3(0.0, 0.0, -0.18),
			0.24, 241)
	check(n > 0, "new physical chest must be destructible")
	check_eq(h.cells.size(), a - n,
			"deleted voxel count must agree with actual geometry")
	check_eq(shin.cells.size(), b,
			"torso crater must not damage another physical part")
	m.free()
