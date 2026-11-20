extends SceneTree
## Captures actual rendered gait opposition plus an unchanged-pose damage pair.
## xvfb-run -a godot --rendering-method gl_compatibility --resolution 1280x720 \
##     -s tools/capture_voxel_lab.gd -- /tmp/voxel-frames

var output_dir := "/tmp/voxel-frames"
var stage := 0
var scene: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output_dir = args[0]
	DirAccess.make_dir_recursive_absolute(output_dir)
	scene = load("res://scenes/voxel_mech_lab.tscn").instantiate()
	root.add_child(scene)
	scene._orbit = 1.85
	scene.update_camera()
	scene.mech.start_walk(100.0)  # do not stop due to low offscreen FPS


func _process(_delta: float) -> bool:
	var mech: VoxelMech = scene.mech
	if stage == 0 and mech.gait_phase >= 0.08:
		capture("gait_a.png")
		stage = 1
	elif stage == 1 and mech.gait_phase >= 0.58:
		capture("gait_b.png")
		mech.walking = false
		mech.position.z = 0.0
		mech.stand()
		scene._orbit = 2.58
		scene.update_camera()
		stage = 2
	elif stage == 2:
		capture("armor_before.png")
		stage = 3
	elif stage == 3:
		var torso: VoxelPart = mech.parts["torso"]
		var impact := torso.to_global(Vector3(0.0, -0.16, -0.40))
		if mech.hit_part("torso", impact, 0.34) <= 0:
			printerr("Damage capture did not remove any voxels")
			quit(1)
			return true
		stage = 4
	elif stage == 4:
		capture("armor_after.png")
		scene._select_chassis(4)  # Jenner, using the digitigrade chassis profile.
		scene._orbit = 1.85
		scene.update_camera()
		scene.mech.start_walk(100.0)
		stage = 5
	elif stage == 5 and scene.mech.gait_phase >= 0.08:
		capture("digitigrade_a.png")
		stage = 6
	elif stage == 6 and scene.mech.gait_phase >= 0.58:
		capture("digitigrade_b.png")
		scene._select_chassis(5)  # Catapult
		scene._orbit = 2.58
		scene.update_camera()
		scene.mech.walking = false
		scene.mech.position = Vector3.ZERO
		scene.mech.stand()
		stage = 7
	elif stage >= 7 and stage <= 11:
		var indexes := [5, 1, 2, 3, 4]
		var names := ["catapult.png", "atlas.png", "hunchback.png",
				"wolverine.png", "jenner_stand.png"]
		var idx := stage - 7
		capture(names[idx])
		if idx == indexes.size() - 1:
			return true
		scene._select_chassis(indexes[idx + 1])
		scene.mech.walking = false
		scene.mech.position = Vector3.ZERO
		scene.mech.stand()
		stage += 1
	return false


func capture(file_name: String) -> void:
	var path := output_dir.path_join(file_name)
	var error := root.get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		printerr("Failed to save ", path, ": ", error)
		quit(1)
	print("Saved ", path)
