extends SceneTree
## QA capture from the actual procedural voxel surfaces, not concept art.
var lab: VoxelMechLab
var stage := 0
var ticks := 0
var output := "/tmp/atlas-mesh-hybrid"
const VIEWS := [
	{"profile": 1, "id": "atlas-mesh-3quarter", "angle": 2.58, "height": 0.20, "distance": 5.1},
	{"profile": 1, "id": "atlas-mesh-front", "angle": PI, "height": 0.13, "distance": 5.1},
	{"profile": 1, "id": "atlas-mesh-side", "angle": PI * 0.5, "height": 0.14, "distance": 5.3},
	{"profile": 1, "id": "atlas-after-damage", "angle": 2.58, "height": 0.20, "distance": 5.1}
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
	if str(v["id"]) == "atlas-after-damage":
		var body: VoxelPart = lab.mech.parts["torso"]
		var removed := body.erase_irregular_local_ball(
				Vector3(0.0, -0.05, -0.34), 0.25, 90621)
		print("ATLAS_MESH_DAMAGE|", removed,
				"|", body.remaining_voxels() if body.has_method("remaining_voxels")
				else body.cells.size())
	lab._orbit = float(v["angle"])
	lab._elevation = float(v["height"])
	lab._distance = float(v["distance"])
	# Taller reference designs: the original lab camera aimed at 1.25m,
	# clipping heads and making legs look abnormally squat in captures.
	var target := Vector3(0, 1.90, 0)
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
	print("ATLAS_MESH_RENDER|", v["id"], "|", lab.mech.initial_voxels(), "|", path)
	stage += 1
	if stage >= VIEWS.size():
		quit(0)
	else:
		_set_view()
	return false
