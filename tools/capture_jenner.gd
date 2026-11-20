extends SceneTree
## Capture the actual Jenner Godot model without the lab HUD.
## godot --rendering-method gl_compatibility --resolution 1280x720 \
##   -s tools/capture_jenner.gd -- /tmp/jenner-frames

var output_dir := "/tmp/jenner-frames"
var scene: VoxelMechLab
var stage := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output_dir = args[0]
	DirAccess.make_dir_recursive_absolute(output_dir)
	scene = load("res://scenes/voxel_mech_lab.tscn").instantiate()
	root.add_child(scene)
	for i in scene.profiles.size():
		if scene.profiles[i]["id"] == "jenner_jr7d":
			scene._select_chassis(i)
			break
	# Keep UI in the live lab, remove only for clean model inspection screenshots.
	for node in scene.get_children():
		if node is CanvasLayer:
			node.visible = false
	scene.mech.walking = false
	scene.mech.position = Vector3.ZERO
	scene.mech.stand()
	scene._distance = 4.7
	scene._elevation = 0.16
	scene._orbit = PI
	scene.update_camera()


func _process(_delta: float) -> bool:
	match stage:
		0:
			capture("jenner_front.png")
			scene._orbit = 2.46
			scene.update_camera()
		1:
			capture("jenner_three_quarter.png")
			scene._orbit = PI / 2.0
			scene.update_camera()
		2:
			capture("jenner_side.png")
			scene._orbit = 0.0
			scene.update_camera()
		3:
			capture("jenner_rear.png")
			scene._orbit = PI / 2.0
			scene.update_camera()
			scene.mech._pose(0.08)
		4:
			capture("jenner_stride_a.png")
			scene.mech._pose(0.58)
		5:
			capture("jenner_stride_b.png")
			scene.mech.stand()
			var torso: VoxelPart = scene.mech.parts["torso"]
			var impact := torso.to_global(Vector3(0.0, 0.04, -1.08))
			var removed := scene.mech.hit_part("torso", impact, 0.25)
			if removed <= 0:
				printerr("Jenner impact failed to remove voxels")
				quit(1)
				return true
			scene._orbit = 2.46
			scene.update_camera()
		6:
			capture("jenner_damage.png")
			return true
	stage += 1
	return false


func capture(file_name: String) -> void:
	var path := output_dir.path_join(file_name)
	var err := root.get_viewport().get_texture().get_image().save_png(path)
	if err != OK:
		printerr("Capture failed: ", path, ", error: ", err)
		quit(1)
	print("Saved ", path)
