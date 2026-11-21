extends SceneTree
## Actual greedy-meshed VOXELS, not the geometry-only triangle proxy.
## One 4-view contact sheet covers all three approved chassis sculptures.
## xvfb-run -a godot --rendering-method gl_compatibility --resolution 1400x800 \
##   -s tools/capture_full_voxels.gd -- /tmp/voxelized

const IDS := ["atlas", "wolverine", "jenner"]
const SPACING := 2.85
var output_dir := "/tmp/full-voxel-renders"
var stage: Node3D
var camera: Camera3D
var mechs: Array[VxMech] = []
var views := ["three_quarter", "front", "side", "top"]
var captures: Array[Image] = []
var step := 0
var frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output_dir = args[0]
	DirAccess.make_dir_recursive_absolute(output_dir)
	stage = Node3D.new()
	root.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("232a32")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e6e9ee")
	env.ambient_light_energy = 0.55
	var world := WorldEnvironment.new()
	world.environment = env
	stage.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -40, 0)
	sun.light_energy = 1.2
	stage.add_child(sun)
	var ground := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(11.5, 0.08, 7.0)
	ground.mesh = floor_mesh
	ground.position.y = -0.09
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("414952")
	ground.material_override = floor_mat
	stage.add_child(ground)
	for i in IDS.size():
		var file := "res://data/voxels/%s_voxel.json" % IDS[i]
		var mech := VxMech.from_file(file)
		if not mech.model.errors.is_empty() or mech.model.detail != 2:
			printerr("VOXELIZE_ERROR|invalid model %s" % IDS[i])
			quit(1)
			return
		mech.position.x = (float(i) - 1.0) * SPACING
		stage.add_child(mech)
		mechs.append(mech)
		print("VOXELIZED|%s|%d|%d" % [IDS[i], mech.voxel_count(), mech.triangle_count()])
	camera = Camera3D.new()
	camera.fov = 43
	camera.current = true
	stage.add_child(camera)
	_set_view()


func _set_view() -> void:
	var view: String = views[step]
	for mech: VxMech in mechs:
		mech.rotation.y = PI / 2.0 if view == "side" else 0.0
	var center := Vector3(0, 1.2, 0)
	match view:
		"three_quarter":
			camera.look_at_from_position(center + Vector3(5.9, 1.2, -8.8), center)
		"front":
			camera.look_at_from_position(center + Vector3(0, 0.55, -10.7), center)
		"side":
			camera.look_at_from_position(center + Vector3(0, 0.50, -10.7), center)
		"top":
			camera.look_at_from_position(center + Vector3(0, 10.7, -0.01),
					center, Vector3(0, 0, 1))


func _process(_delta: float) -> bool:
	frame += 1
	if frame < 10:
		return false
	if root.get_camera_3d() != camera:
		printerr("VOXELIZE_ERROR|camera not current")
		quit(1)
		return true
	var shot := root.get_texture().get_image()
	if shot == null or shot.get_width() < 500:
		printerr("VOXELIZE_ERROR|viewport empty")
		quit(1)
		return true
	captures.append(shot)
	step += 1
	if step >= views.size():
		var tile_w := 1200
		var tile_h := 620
		var sheet := Image.create(tile_w, tile_h * captures.size(),
				false, Image.FORMAT_RGBA8)
		for i in captures.size():
			var tile: Image = captures[i]
			tile.convert(Image.FORMAT_RGBA8)
			tile.resize(tile_w, tile_h, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(tile, Rect2i(0, 0, tile_w, tile_h),
					Vector2i(0, i * tile_h))
		var path := output_dir.path_join("atlas_wolverine_jenner_full_voxels.png")
		if sheet.save_png(path) != OK:
			printerr("VOXELIZE_ERROR|image write failed: " + path)
			quit(1)
			return true
		print("VOXEL_RENDER|" + path)
		quit(0)
		return true
	frame = 0
	_set_view()
	return false
