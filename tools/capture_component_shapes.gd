extends SceneTree
## Shape review: render only the unsmoothed VxModel sculpted components.
## xvfb-run -a godot --rendering-method gl_compatibility --resolution 1500x900 \
##   -s tools/capture_component_shapes.gd -- /tmp/component-shape-renders

const IDS := ["atlas_shape", "wolverine_shape", "jenner_shape"]
const LABELS := ["ATLAS", "WOLVERINE", "JENNER"]
const SPACING := 2.8
var output_dir := "/tmp/component-shape-renders"
var scene: Node3D
var camera: Camera3D
var models: Array[VxShapePreview] = []
var labels: Array[Label3D] = []
var views: Array[Dictionary] = []
var step := 0
var frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output_dir = args[0]
	DirAccess.make_dir_recursive_absolute(output_dir)
	scene = Node3D.new()
	scene.name = "UnrefinedComponentShapeStudies"
	root.add_child(scene)
	_lighting()
	for i in IDS.size():
		var model := VxModel.load_file("res://data/voxels/%s.json" % IDS[i])
		if not model.errors.is_empty() or model.detail != 1:
			printerr("SHAPE_ERROR|invalid model %s errors %s" % [IDS[i], model.errors])
			quit(1)
			return
		var mech := VxShapePreview.from_file("res://data/voxels/%s.json" % IDS[i])
		mech.position = Vector3((i - 1) * SPACING, 0, 0)
		scene.add_child(mech)
		models.append(mech)
		print("SHAPE_COUNT|%s|%d|%d" % [IDS[i], model.cell_count(), model.parts.size()])
		var label := Label3D.new()
		label.text = LABELS[i]
		label.font_size = 40
		label.pixel_size = 0.0015
		label.outline_size = 6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		# Head and launcher heights differ between 35t, 55t and 100t chassis.
		# Label each actual bounding volume instead of pinning to 2.55 meters.
		var highest_cell := 0
		for component: Dictionary in model.parts:
			for voxel: Vector3i in component["cells"]:
				highest_cell = maxi(highest_cell, voxel.y)
		label.position = Vector3((i - 1) * SPACING,
				(float(highest_cell) + 5.0) * model.voxel_size, 0)
		scene.add_child(label)
		labels.append(label)
	camera = Camera3D.new()
	camera.fov = 40
	camera.current = true
	scene.add_child(camera)
	# One combined picture per iteration. Extra angles or isolated components
	# are captured only during a deliberate targeted diagnostic run.
	views.append({"name": "gallery_three_quarter", "who": -1, "view": "three_quarter"})
	_setup_view(step)


func _lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("232a32")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e8ebf1")
	env.ambient_light_energy = 0.48
	var world := WorldEnvironment.new()
	world.environment = env
	scene.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.10
	sun.shadow_enabled = false
	scene.add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-28, 145, 0)
	rim.light_energy = 0.38
	scene.add_child(rim)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(13, 0.1, 9)
	var ground := MeshInstance3D.new()
	ground.mesh = floor_mesh
	ground.position.y = -0.09
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("39424b")
	ground.material_override = floor_mat
	scene.add_child(ground)


func _setup_view(index: int) -> void:
	var target: Dictionary = views[index]
	var who: int = target["who"]
	var view: String = target["view"]
	var look_x := 0.0 if who == -1 else (float(who) - 1.0) * SPACING

	for i in models.size():
		models[i].visible = who == -1 or i == who
		labels[i].visible = who == -1
		var selected: Array[String] = []
		if i == who and target.has("parts"):
			for name: String in target["parts"]:
				selected.append(name)
		models[i].isolate_parts(selected)
	var distance: float = float(target.get("distance", 8.6 if who == -1 else 4.7))
	var center := Vector3(look_x, float(target.get("height", 1.08)), 0)
	match view:
		"front":
			camera.look_at_from_position(center + Vector3(0, 0.28, -distance), center)
		"three_quarter":
			camera.look_at_from_position(center + Vector3(distance * 0.53, 1.1, -distance * 0.85), center)
		"side":
			camera.look_at_from_position(center + Vector3(distance, 0.37, 0), center)
		"rear":
			camera.look_at_from_position(center + Vector3(0, 0.30, distance), center)


func _process(_delta: float) -> bool:
	# SceneTree._process has a bool return signature (unlike Node._process).
	if camera == null:
		return false
	frame += 1
	if frame < 8:
		return false
	if root.get_camera_3d() != camera:
		printerr("SHAPE_ERROR|camera not current")
		quit(1)
		return true
	var path := output_dir.path_join("%s.png" % views[step]["name"])
	var image := root.get_texture().get_image()
	if image == null or image.get_width() < 500:
		printerr("SHAPE_ERROR|viewport empty: %s" % path)
		quit(1)
		return true
	if image.save_png(path) != OK:
		printerr("SHAPE_ERROR|png write failed: %s" % path)
		quit(1)
		return true
	print("SHAPE_RENDER|%s.png" % views[step]["name"])
	step += 1
	if step >= views.size():
		# Returning true alone does not shut down SceneTree.
		# This explicit quit ends xvfb-run / GitHub Actions after saving.
		quit(0)
		return true
	frame = 0
	_setup_view(step)
	return false
