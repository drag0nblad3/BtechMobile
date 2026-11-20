extends SceneTree
## Headless exact model-by-model occupied voxel count report. No rendering.

func _initialize() -> void:
	call_deferred("_report")


func _report() -> void:
	for profile in VoxelChassis.all():
		var mech := VoxelMech.new()
		mech.profile_id = str(profile["id"])
		mech.detail_level = int(profile.get("voxel_detail", 1))
		mech.render_surfaces = false
		mech.build()
		print("VOXEL_COUNT|%s|%s|%d|%d|%.4f" % [
			profile["id"], profile["name"], mech.initial_voxels(),
			mech.detail_level, mech.parts["torso"].voxel_size])
		for key: String in mech.parts:
			var part: VoxelPart = mech.parts[key]
			print("VOXEL_PART|%s|%s|%d|%d" % [
					profile["id"], key, part._original_count, part.detail_scale])
		mech.free()
	quit()
