extends SceneTree
## Render two frames separated by approximately half of the gait cycle.
## xvfb-run -a godot --rendering-method gl_compatibility --resolution 1280x720 \
##     -s tools/capture_voxel_lab.gd -- /tmp/voxel-frames

var frames := 0
var output_dir := "/tmp/voxel-frames"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output_dir = args[0]
	DirAccess.make_dir_recursive_absolute(output_dir)
	var scene: Node = load("res://scenes/voxel_mech_lab.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 30:
		return capture("gait_a.png", false)
	if frames == 69:
		return capture("gait_b.png", true)
	return false


func capture(file_name: String, finish: bool) -> bool:
	var path := output_dir.path_join(file_name)
	var error := root.get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		printerr("Failed to save ", path, ": ", error)
		quit(1)
		return true
	print("Saved ", path)
	return finish
