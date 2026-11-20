extends TestCase
## Verify the second high-resolution art pass is genuine cell geometry.

func test_atlas_and_catapult_use_100k_to_120k_actual_voxels() -> void:
	for id in ["atlas_as7d", "catapult_cplt_c1"]:
		var profile := VoxelChassis.find(id)
		check_eq(int(profile["voxel_detail"]), 2, id + " must request fine voxels")
		var mech := VoxelMech.new()
		mech.profile_id = id
		mech.detail_level = int(profile["voxel_detail"])
		mech.render_surfaces = false
		mech.build()
		var count := mech.initial_voxels()
		check(count >= 100000 and count <= 120000,
				"%s must be 100-120k real cells; got %d" % [id, count])
		check_eq(count, mech.remaining_voxels(),
				id + " original and remaining count should match before damage")
		check(is_equal_approx((mech.parts["torso"] as VoxelPart).voxel_size,
				0.0375), id + " physical pitch must be 37.5 mm")
		check(not (mech.parts["torso"] as VoxelPart).has_node("Surface"),
				"count-only check should avoid extra GPU meshes")
		mech.free()


func test_atlas_skull_visor_and_chest_plate_are_voxels() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "atlas_as7d"
	mech.detail_level = 2
	mech.render_surfaces = false
	mech.build()
	var hull: VoxelPart = mech.parts["torso"]
	check_eq(hull.cells.get(Vector3i(-6, 18, -12)), 2,
			"Atlas must have colored eye slits below the helmet brow")
	check(hull.cells.has(Vector3i(-16, -4, -18)),
			"Atlas must carry a projecting left chest plate")
	check(hull.cells.has(Vector3i(16, -4, -18)),
			"Atlas must carry a projecting right chest plate")
	check(hull.cells.has(Vector3i(-30, 0, 0)),
			"Atlas must have enlarged shoulder armor")
	mech.free()


func test_catapult_has_two_fifteen_tube_pods_with_recessed_muzzles() -> void:
	var mech := VoxelMech.new()
	mech.profile_id = "catapult_cplt_c1"
	mech.detail_level = 2
	mech.render_surfaces = false
	mech.build()
	for key in ["left_arm", "right_arm"]:
		var pod: VoxelPart = mech.parts[key]
		for x in [-4, 0, 4]:
			for y in [-2, 0, 2, 4, 6]:
				var hole := Vector3i(x * 2, y * 2, -18)
				check(not pod.cells.has(hole),
						"LRM launcher mouth must have an actual cutout at %s" % str(hole))
				check_eq(pod.cells.get(Vector3i(x * 2, y * 2, -14)), 3,
						"each recessed LRM tube must expose its orange interior")
	var torso: VoxelPart = mech.parts["torso"]
	check_eq(torso.cells.get(Vector3i(0, 2, -30)), 2,
			"Catapult should have a pointed forward glass canopy")
	mech.free()


func test_broader_crater_covers_real_spatial_area_and_stays_local() -> void:
	var a := VoxelPart.new()
	var b := VoxelPart.new()
	for part in [a, b]:
		part.detail_scale = 2
		part.mesh_enabled = false
		part.fill_box(Vector3i(-7, -7, -7), Vector3i(7, 7, 7), 0)
		part.seal()
	var before: Dictionary = a.cells.duplicate()
	var removed := a.erase_irregular_local_ball(Vector3.ZERO, 0.39, 707)
	b.erase_irregular_local_ball(Vector3.ZERO, 0.39, 707)
	check(removed > 50, "broad crater must remove substantial real microvoxels")
	check_eq(a.cells, b.cells, "broad impact remains reproducible from its seed")
	var lo := Vector3i(999, 999, 999)
	var hi := Vector3i(-999, -999, -999)
	for cell: Vector3i in before:
		if a.cells.has(cell):
			continue
		lo = Vector3i(mini(lo.x, cell.x), mini(lo.y, cell.y), mini(lo.z, cell.z))
		hi = Vector3i(maxi(hi.x, cell.x), maxi(hi.y, cell.y), maxi(hi.z, cell.z))
	var width := (hi - lo + Vector3i.ONE) * a.voxel_size
	check(width.x >= 0.45 and width.y >= 0.45,
			"impact must spread beyond a tiny single-voxel puncture: " + str(width))
	a.free()
	b.free()
