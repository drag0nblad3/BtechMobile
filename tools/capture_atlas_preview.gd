extends SceneTree
## Actual source-geometry capture of the Atlas from the unmerged six-sculpt PR.
## Run via xvfb-run -a godot --rendering-method gl_compatibility
##   --resolution 1280x800 -s tools/capture_atlas_preview.gd -- /tmp/atlas-preview

var lab: VoxelMechLab
var frame := 0
var view_index := 0
var output_dir := "/tmp/atlas-preview"
const VIEWS := [
	{"name": "atlas-three-quarter.png", "orbit": 2.58, "elevation": 0.28, "distance": 5.9},
	{"name": "atlas-front.png", "orbit": PI, "elevation": 0.18, "distance": 5.9},
	{"name": "atlas-side.png", "orbit": PI * 0.5, "elevation": 0.27, "distance": 6.1},
	{"name": "atlas-rear.png", "orbit": 0.0, "elevation": 0.24, "distance": 6.1},
]


func _initialize() -> void:
	call_deferred("_setup")


func _setup() -> void:
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		output_dir = user_args[0]
	DirAccess.make_dir_recursive_absolute(output_dir)
	lab = load("res://scenes/voxel_mech_lab.tscn").instantiate()
	root.add_child(lab)
	lab._select_chassis(1)  # Atlas AS7-D, not the prototype
	lab.mech.walking = false
	lab.mech.position = Vector3.ZERO
	lab.mech.stand()
	lab.mech.set_process(false)
	# Hide the lab menus for an unobstructed view of the actual geometry.
	for child in lab.get_children():
		if child is CanvasLayer:
			child.visible = false
	_setup_view()


func _setup_view() -> void:
	if view_index >= VIEWS.size():
		quit(0)
		return
	var view: Dictionary = VIEWS[view_index]
	lab._orbit = float(view["orbit"])
	lab._elevation = float(view["elevation"])
	lab._distance = float(view["distance"])
	lab.update_camera()
	frame = 0


func _process(_delta: float) -> bool:
	if lab == null or lab.camera == null:
		return false
	frame += 1
	if frame < 12:
		return false
	var view: Dictionary = VIEWS[view_index]
	var path: String = output_dir.path_join(str(view["name"]))
	var img := root.get_viewport().get_texture().get_image()
	if img.is_empty():
		printerr("Atlas capture produced an empty viewport: ", path)
		quit(1)
		return true
	var error := img.save_png(path)
	if error != OK:
		printerr("Atlas capture failed: ", path, " error ", error)
		quit(1)
		return true
	print("ATLAS_PREVIEW|", path, "|", lab.mech.initial_voxels(), " real voxels")
	view_index += 1
	if view_index == VIEWS.size():
		quit(0)
		return true
	_setup_view()
	return false
