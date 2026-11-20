extends SceneTree
## Counts all six chassis without making meshes and performs one real high-res
## Jenner impact. Emits machine-readable lines for CI and model-count auditing.


func _initialize() -> void:
	call_deferred("_benchmark")


func _benchmark() -> void:
	var totals: Dictionary = {}
	for profile in VoxelChassis.all():
		var started := Time.get_ticks_msec()
		var model := VoxelMech.new()
		model.profile_id = str(profile["id"])
		model.generate_mesh = false
		model.build()
		var count := model.initial_voxels
		totals[model.profile_id] = count
		print("VOXEL_COUNT|%s|%d|detail=%d|count_ms=%d" % [
				model.profile_id, count, int(profile.get("voxel_detail", 1)),
				Time.get_ticks_msec() - started])
		if count <= 0 or model.remaining_voxels() != count:
			printerr("Invalid intact voxel count for ", model.profile_id)
			quit(1)
			return
		model.free()
	var started := Time.get_ticks_msec()
	var jenner := VoxelMech.new()
	jenner.profile_id = "jenner_jr7d"
	root.add_child(jenner)  # _ready builds it; world-space impacts need a live transform.
	var build_ms := Time.get_ticks_msec() - started
	var torso: VoxelPart = jenner.parts["torso"]
	var before := torso.cells.size()
	var impact := torso.to_global(Vector3(0.0, 0.0, -1.12))
	started = Time.get_ticks_msec()
	var removed := jenner.hit_part("torso", impact, 0.26, 20261120)
	var damage_ms := Time.get_ticks_msec() - started
	print("JENNER_HIRES|voxels=%d|build_ms=%d|damage_ms=%d|removed=%d|remaining=%d" % [
			jenner.initial_voxels, build_ms, damage_ms, removed, jenner.remaining_voxels()])
	if removed <= 0 or torso.cells.size() >= before:
		printerr("High-resolution Jenner crater did not remove geometry")
		jenner.free()
		quit(1)
		return
	if build_ms > 90000 or damage_ms > 90000:
		printerr("High-resolution voxel mesh operations exceeded 90 second CI ceiling")
		jenner.free()
		quit(1)
		return
	if jenner.initial_voxels != totals["jenner_jr7d"]:
		printerr("Mesh-free voxel count differs from full rendered model")
		jenner.free()
		quit(1)
		return
	jenner.free()
	print("VOXEL_COUNT_BENCHMARK_OK")
	quit(0)
