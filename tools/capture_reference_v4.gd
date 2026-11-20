extends SceneTree
## QA capture from the actual procedural voxel surfaces, not concept art.
var lab: VoxelMechLab
var stage := 0
var ticks := 0
var output := "/tmp/reference-v4"
const VIEWS := [
	{"profile": 1, "id": "atlas", "angle": 2.58, "height": 0.25, "distance": 6.0},
	{"profile": 1, "id": "atlas-front", "angle": PI, "height": 0.17, "distance": 6.0},
	{"profile": 1, "id": "atlas-side", "angle": PI * 0.5, "height": 0.19, "distance": 6.0},
	{"profile": 2, "id": "hunchback", "angle": 2.58, "height": 0.24, "distance": 5.8},
	{"profile": 2, "id": "hunchback-side", "angle": PI * 0.5, "height": 0.19, "distance": 5.8},
	{"profile": 3, "id": "wolverine", "angle": 2.58, "height": 0.22, "distance": 5.8},
	{"profile": 3, "id": "wolverine-side", "angle": PI * 0.5, "height": 0.19, "distance": 5.8},
	{"profile": 4, "id": "jenner", "angle": 2.58, "height": 0.21, "distance": 5.7},
	{"profile": 4, "id": "jenner-side", "angle": PI * 0.5, "height": 0.18, "distance": 5.8},
	{"profile": 5, "id": "catapult", "angle": 2.58, "height": 0.25, "distance": 6.0},
	{"profile": 5, "id": "catapult-side", "angle": PI * 0.5, "height": 0.18, "distance": 6.0},
	{"profile": 0, "id": "prototype", "angle": 2.58, "height": 0.23, "distance": 5.8},
	{"profile": 0, "id": "prototype-side", "angle": PI * 0.5, "height": 0.18, "distance": 5.8}
]


func _initialize() -> void:
	call_deferred("_setup")


func _setup() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	DirAccess.make_dir_recursive_absolute(output)
	lab = load("res://scenes/voxel_mech_lab.tscn").instantiate()
	root.add_child(lab)
	for child in lab.get_children():
		if child is CanvasLayer:
			child.visible = false
	_set_view()


func _set_view() -> void:
	if stage >= VIEWS.size():
		quit(0)
		return
	var v: Dictionary = VIEWS[stage]
	if lab.mech == null or lab.profile_index != int(v["profile"]):
		lab._select_chassis(int(v["profile"]))
	lab.mech.walking = false
	lab.mech.position = Vector3.ZERO
	lab.mech.stand()
	lab.mech.set_process(false)
	lab._orbit = float(v["angle"])
	lab._elevation = float(v["height"])
	lab._distance = float(v["distance"])
	# Taller reference designs: the original lab camera aimed at 1.25m,
	# clipping heads and making legs look abnormally squat in captures.
	var target := Vector3(0, 1.65, 0)
	lab.camera.position = target + Vector3(
			sin(lab._orbit) * cos(lab._elevation),
			sin(lab._elevation),
			cos(lab._orbit) * cos(lab._elevation)) * lab._distance
	lab.camera.look_at(target, Vector3.UP)
	ticks = 0


func _process(_delta: float) -> bool:
	if lab == null:
		return false
	ticks += 1
	if ticks < 10:
		return false
	var v: Dictionary = VIEWS[stage]
	var path := output.path_join("%s.png" % v["id"])
	var img := root.get_viewport().get_texture().get_image()
	if img.is_empty() or img.save_png(path) != OK:
		printerr("RENDER_FAILED|", path)
		quit(1)
		return true
	print("REFERENCE_V4_RENDER|", v["id"], "|", lab.mech.initial_voxels(), "|", path)
	stage += 1
	if stage >= VIEWS.size():
		quit(0)
	else:
		_set_view()
	return false
