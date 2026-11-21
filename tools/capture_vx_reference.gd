extends SceneTree
## Actual Godot images of the authored VxModel/VxMech parts in draft PR #80.
## xvfb-run -a godot --rendering-method gl_compatibility --resolution 1440x900 \
##     -s tools/capture_vx_reference.gd -- /tmp/vx-reference-renders

const MODELS := [
	"res://data/voxels/atlas.json",
	"res://data/voxels/wolverine.json",
	"res://data/voxels/jenner.json",
]
const IDS := ["atlas", "wolverine", "jenner"]
const SPACING := 2.55
var out_dir := "/tmp/vx-reference-renders"
var scene: Node3D
var camera: Camera3D
var mechs: Array[VxMech] = []
var plates: Array[Label3D] = []
var captures := [
	"gallery_front.png", "gallery_three_quarter.png",
	"atlas_front.png", "atlas_three_quarter.png",
	"wolverine_front.png", "wolverine_three_quarter.png",
	"jenner_front.png", "jenner_three_quarter.png",
]
var stage := 0
var settle_frames := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	scene = Node3D.new()
	scene.name = "ReferenceVoxelRender"
	root.add_child(scene)
	_setup_lighting()
	for i in MODELS.size():
		var mech := VxMech.from_file(MODELS[i])
		mech.position = Vector3((float(i) - 1.0) * SPACING, 0.0, 0.0)
		scene.add_child(mech)
		mechs.append(mech)
		var label := Label3D.new()
		label.text = IDS[i].to_upper()
		label.font_size = 50
		label.pixel_size = 0.002
		label.outline_size = 8
		label.position = Vector3((float(i) - 1.0) * SPACING, 2.95, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		scene.add_child(label)
		plates.append(label)
	camera = Camera3D.new()
	camera.fov = 43
	camera.current = true
	scene.add_child(camera)
	_setup_view(0)


func _setup_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("171e28")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d5e2f1")
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = env
	scene.add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -36, 0)
	key.light_energy = 1.8
	key.shadow_enabled = true
	key.shadow_normal_bias = 1.5
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 125, 0)
	fill.light_energy = 0.6
	scene.add_child(fill)
	var ground := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(18.0, 0.12, 14.0)
	ground.mesh = mesh
	ground.position.y = -0.14
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("313b42")
	material.roughness = 1.0
	ground.material_override = material
	scene.add_child(ground)


func _setup_view(index: int) -> void:
	var gallery := index < 2
	for i in mechs.size():
		mechs[i].visible = gallery or i == (index - 2) / 2
		plates[i].visible = gallery
	if gallery:
		if index == 0:
			camera.position = Vector3(0, 2.30, -8.1)
		else:
			camera.position = Vector3(4.1, 2.65, -8.9)
		camera.look_at(Vector3(0, 1.35, 0))
	else:
		var which := int((index - 2) / 2)
		var x := (float(which) - 1.0) * SPACING
		if index % 2 == 0:
			camera.position = Vector3(x, 1.55, -4.8)
		else:
			camera.position = Vector3(x + 3.1, 2.10, -4.45)
		camera.look_at(Vector3(x, 1.20, 0))


func _process(_delta: float) -> bool:
	settle_frames += 1
	if settle_frames < 7:
		return false
	var filename: String = captures[stage]
	var path := out_dir.path_join(filename)
	var result := root.get_viewport().get_texture().get_image().save_png(path)
	if result != OK:
		printerr("VX_RENDER_ERROR|%s|%s" % [filename, result])
		quit(1)
		return true
	print("VX_RENDER_OK|%s" % filename)
	stage += 1
	if stage == captures.size():
		return true
	_setup_view(stage)
	settle_frames = 0
	return false
