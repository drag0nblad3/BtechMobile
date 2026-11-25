extends SceneTree
## Headless exact model-by-model occupied voxel count report. No rendering.

func _initialize() -> void:
	call_deferred("_report")


func _report() -> void:
	var profiles := VoxelChassis.all()
	if profiles.is_empty():
		push_error("VOXEL_COUNT_FAILED: empty catalog")
		quit(1)
		return
	var seen := {}
	for profile in profiles:
		var id := String(profile["id"])
		if seen.has(id):
			push_error("VOXEL_COUNT_FAILED: duplicate profile " + id)
			quit(1)
			return
		seen[id] = true
		var mech := VoxelMech.new()
		mech.profile_id = str(profile["id"])
		mech.detail_level = int(profile.get("voxel_detail", 1))
		mech.render_surfaces = false
		mech.build()
		if mech.initial_voxels() <= 0 or not mech.parts.has("torso"):
			push_error("VOXEL_COUNT_FAILED: empty model " + id)
			mech.free()
			quit(1)
			return
		print("VOXEL_COUNT|%s|%s|%d|%d|%.4f" % [
			profile["id"], profile["name"], mech.initial_voxels(),
			mech.detail_level, mech.parts["torso"].voxel_size])
		if profile["id"] == "atlas_as7d" or profile["id"] == "catapult_cplt_c1":
			for key: String in mech.parts:
				var part: VoxelPart = mech.parts[key]
				print("VOXEL_PART|%s|%s|%d|%d" % [
						profile["id"], key, part._original_count, part.detail_scale])
		mech.free()
	print("VOXEL_COUNT_COMPLETE|", seen.size())
	quit(0)
