extends SceneTree
## CPU-only 8/16-Mech battle geometry benchmark. Render FPS needs device QA.
## godot --headless -s tools/voxel_battle_bench.gd

const MODEL := "res://data/voxels/hunchback.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 16, 26)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var models: Array[VxMech] = []
	for count in [8, 16]:
		var start := Time.get_ticks_usec()
		while models.size() < count:
			var m := VxMech.from_file(MODEL)
			var i := models.size()
			scene.add_child(m)
			m.position = Vector3((i % 4 - 1.5) * 2.6, 0, (i / 4 - 1.5) * 3.1)
			models.append(m)
		var build_ms := (Time.get_ticks_usec() - start) / 1000.0
		var tris := 0
		for m in models:
			tris += m.triangle_count()
		for frame in 12:
			await process_frame
		var stamp := Time.get_ticks_usec()
		for frame in 90:
			await process_frame
		var avg_ms := (Time.get_ticks_usec() - stamp) / 90000.0
		print("VOXEL_BATTLE_BENCH|count=%d|triangles=%d|build_ms=%.2f|headless_frame_ms=%.3f" %
				[count, tris, build_ms, avg_ms])
	scene.queue_free()
	quit(0)
