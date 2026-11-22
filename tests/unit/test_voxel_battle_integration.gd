extends TestCase
## Battle voxel selection, mesh reuse, and record-sheet-only damage.


func test_voxel_is_preferred_and_undamaged_meshes_are_shared() -> void:
	var old := GameSettings.voxel_mechs
	GameSettings.voxel_mechs = true
	var def := designs().get_def("hunchback_hbk4g")
	var a := UnitVoxels.choose(def, 0)
	var b := UnitVoxels.choose(def, 1)
	check(a != null and b != null, "expected Hunchback voxel recipe")
	if a != null and b != null:
		check(a.part_at(Location.CT).mesh == b.part_at(Location.CT).mesh,
				"baseline mesh must be cached across units")
		check(a.part_at(Location.CT).material_override != b.part_at(Location.CT).material_override,
				"each side has a distinct material wash")
		a.free()
		b.free()
	GameSettings.voxel_mechs = old


func test_voxel_damage_only_reads_record_sheet() -> void:
	var old := GameSettings.voxel_mechs
	GameSettings.voxel_mechs = true
	var def := designs().get_def("hunchback_hbk4g")
	var u := Unit.new(22, def, 0, Vector2i.ZERO, 0)
	var mech := UnitVoxels.choose(def, 0)
	check(mech != null, "need a voxel model")
	if mech == null:
		GameSettings.voxel_mechs = old
		return
	var original := mech.voxel_count()
	mech.show_unit(u)
	check_eq(mech.voxel_count(), original)
	Damage.apply(u, Location.CT, 13)
	var sheet_armor: int = u.armor[Location.CT]
	mech.show_unit(u)
	check(mech.voxel_count() < original, "sheet damage must scar the model")
	check_eq(u.armor[Location.CT], sheet_armor, "visual changes must not touch the sheet")
	mech.free()
	GameSettings.voxel_mechs = old


func test_off_switch_skips_voxel_and_prone_pose_follows_sheet() -> void:
	var old := GameSettings.voxel_mechs
	var def := designs().get_def("hunchback_hbk4g")
	GameSettings.voxel_mechs = false
	check(UnitVoxels.choose(def, 0) == null, "off switch should fall back to sprites")
	GameSettings.voxel_mechs = true
	var u := Unit.new(23, def, 0, Vector2i.ZERO, 0)
	var mech := UnitVoxels.choose(def, 0)
	if mech != null:
		u.prone = true
		check(UnitVoxels.sync(mech, u), "prone sync is handled by voxel rig")
		check(mech.anim.fallen and is_equal_approx(mech.body.rotation.x, VxAnim.FALLEN),
				"sheet prone pose")
		mech.free()
	GameSettings.voxel_mechs = old
