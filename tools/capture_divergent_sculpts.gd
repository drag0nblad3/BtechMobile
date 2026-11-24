extends SceneTree
## Actual Godot VxPart renders; matched orthographic camera and world scale.
const IDS := ["hel", "katana", "kodiak", "legionnaire", "malice", "nightsky",
	"penetrator", "rook", "scarabus", "spartan", "spector", "starslayer",
	"thunder_stallion", "ymir", "battleaxe", "ostwar", "pillager", "sagittaire", "shogun", "thunder_hawk"]
const VIEWS := ["front", "three-quarter", "side", "rear", "top"]
var output := "/tmp/compare"
var scene: Node3D
var camera: Camera3D
var caption: Label
var models: Array[Node3D] = []
var model_counts: Array[int] = []
var images: Array[Image] = []
var index := 0
var view := 0
var version := 0
var frames := 0
var last := 0
var center := Vector3.ZERO
var extent := 1.0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	index = int(args[1]) if args.size() > 1 else 0
	last = mini(IDS.size(), int(args[2])) if args.size() > 2 else IDS.size()
	DirAccess.make_dir_recursive_absolute(output)
	scene = Node3D.new()
	root.add_child(scene)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("29313b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dce6f4")
	env.ambient_light_energy = 0.65
	var world := WorldEnvironment.new()
	world.environment = env
	scene.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.25
	scene.add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-25, 140, 0)
	rim.light_energy = 0.45
	scene.add_child(rim)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	scene.add_child(camera)
	var overlay := CanvasLayer.new()
	scene.add_child(overlay)
	caption = Label.new()
	caption.position = Vector2(12, 8)
	caption.add_theme_font_size_override("font_size", 21)
	overlay.add_child(caption)
	_load_pair()

func _load_pair() -> void:
	for node: Node3D in models:
		node.free()
	models.clear()
	model_counts.clear()
	images.clear()
	var id: String = IDS[index]
	var high := VxFineCatalog.recipe("res://data/voxels/" + id + ".json")
	var candidate_path := "res://experiments/divergent_mech_review_20261124/" + id + "_shape.json"
	if not FileAccess.file_exists(candidate_path):
		candidate_path = "res://data/voxels/" + id + "_shape.json"
	var source := VxFineCatalog.recipe(candidate_path)
	source["subdivide"] = high.get("subdivide", 2)
	source["voxelize_lofts"] = high.get("voxelize_lofts", false)
	var low := Vector3(INF, INF, INF)
	var upper := -low
	for raw: Dictionary in [high, source]:
		var m := VxModel.from_dict(raw)
		if not m.errors.is_empty():
			printerr("COMPARE_ERROR|%s|%s" % [id, m.errors])
			quit(1)
			return
		var holder := Node3D.new()
		scene.add_child(holder)
		models.append(holder)
		model_counts.append(m.cell_count())
		var owner := {}
		for spec: Dictionary in m.parts:
			for c: Vector3i in spec["cells"]:
				owner[c] = spec["name"]
				var p := Vector3(c) * m.voxel_size
				low = low.min(p)
				upper = upper.max(p + Vector3.ONE * m.voxel_size)
		for spec: Dictionary in m.parts:
			var part := VxPart.new()
			part.setup(spec, m)
			part.position = spec["pivot"] * m.voxel_size
			for c: Vector3i in spec["cells"]:
				for d: Vector3i in VxPart.DIRS:
					if owner.has(c + d) and owner[c + d] != spec["name"]:
						part.touching[c + d] = true
			part.rebuild()
			holder.add_child(part)
		holder.visible = false
	center = (low + upper) * 0.5
	extent = (upper - low).length() * 1.12
	view = 0
	version = 0
	_setup_view()

func _setup_view() -> void:
	for i in models.size():
		models[i].visible = i == version
	var directions := [Vector3(0, 0, -1), Vector3(0.68, 0.25, -1),
		Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)]
	var direction: Vector3 = directions[view]
	camera.size = extent
	camera.look_at_from_position(center + direction.normalized() * 10.0, center,
		Vector3.BACK if view == 4 else Vector3.UP)
	caption.text = "%s  |  %s  |  %s  |  %d voxels" % [IDS[index].to_upper(),
		"A: existing detailed" if version == 0 else "B: promoted source",
		VIEWS[view], model_counts[version]]
	frames = 0

func _process(_delta: float) -> bool:
	if models.size() != 2:
		return false
	frames += 1
	if frames < 5:
		return false
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	images.append(img)
	version += 1
	if version == 2:
		version = 0
		view += 1
	if view < VIEWS.size():
		_setup_view()
		return false
	var w := images[0].get_width()
	var h := images[0].get_height()
	var sheet := Image.create(w * 2, h * VIEWS.size(), false, Image.FORMAT_RGBA8)
	for i in images.size():
		sheet.blit_rect(images[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, floori(float(i) / 2.0) * h))
	var path := output.path_join(IDS[index] + ".png")
	if sheet.save_png(path) != OK:
		printerr("COMPARE_ERROR|cannot save " + path)
		quit(1)
		return true
	print("COMPARE_RENDER|%s|%d|%d" % [IDS[index], model_counts[0], model_counts[1]])
	index += 1
	if index >= last:
		quit(0)
		return true
	_load_pair()
	return false
