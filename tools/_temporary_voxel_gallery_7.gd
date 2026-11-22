extends SceneTree
## Shape review: render only the unsmoothed VxModel sculpted components.
## xvfb-run -a godot --rendering-method gl_compatibility --resolution 1500x900 \
##   -s tools/capture_component_shapes.gd -- /tmp/component-shape-renders

const IDS := ["hornet_shape","hussar_shape","hermit_crab_shape"]
const LABELS := ["HORNET","HUSSAR","HERMIT CRAB"]
const SPACING := 3.2
var output_dir := "/tmp/component-shape-renders"
var scene: Node3D
var camera: Camera3D
var models: Array[VxMech] = []
var labels: Array[Label3D] = []
var views: Array[Dictionary] = []
var capture_images: Array[Image] = []
var step := 0
var review_view_label: Label
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
	# One tiny caption per row; camera geometry remains unchanged.
	var overlay := CanvasLayer.new()
	scene.add_child(overlay)
	review_view_label = Label.new()
	review_view_label.position = Vector2(24, 18)
	review_view_label.add_theme_font_size_override("font_size", 28)
	review_view_label.add_theme_color_override("font_color", Color("eaf3ff"))
	overlay.add_child(review_view_label)
	for i in IDS.size():
		var model := VxModel.load_file("res://data/voxels/%s.json" % IDS[i])
		if not model.errors.is_empty() or model.detail != 1:
			printerr("SHAPE_ERROR|invalid model %s errors %s" % [IDS[i], model.errors])
			quit(1)
			return
		var mech := VxMech.from_file("res://data/voxels/%s.json" % IDS[i])
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
	# Five geometry-audit viewpoints in ONE combined image: no per-view
	# render spam. Top down and head-on are vital for detecting duplicated
	# limbs, over-wide shoulders and missing equipment.
	views.append({"name": "gallery_three_quarter", "who": -1, "view": "three_quarter"})
	views.append({"name": "gallery_front", "who": -1, "view": "front"})
	views.append({"name": "gallery_side", "who": -1, "view": "side"})
	views.append({"name": "gallery_rear_three_quarter", "who": -1, "view": "rear_three_quarter"})
	views.append({"name": "gallery_top_down", "who": -1, "view": "top"})
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
	var review_names := [
		"FRONT THREE-QUARTER", "HEAD-ON FRONT", "LEFT/RIGHT SIDE",
		"REAR THREE-QUARTER", "TOP-DOWN · FORWARD = -Z"]
	review_view_label.text = "COMPONENT SHAPE REVIEW · " + review_names[index]
	var look_x := 0.0 if who == -1 else (float(who) - 1.0) * SPACING

	for i in models.size():
		# Turn each model about its own origin instead of orbiting the camera
		# down the gallery's X-spacing axis (which stacks all three mechs).
		models[i].rotation.y = PI / 2.0 if view == "side" else (PI if view.begins_with("rear") else 0.0)
		models[i].visible = who == -1 or i == who
		labels[i].visible = (who == -1 and view != "top")
		var selected: Array[String] = []
		if i == who and target.has("parts"):
			for name: String in target["parts"]:
				selected.append(name)
		# The actual voxel renderer draws exactly the occupied source cells; all parts visible.
	var distance: float = float(target.get("distance", 8.6 if who == -1 else 4.7))
	var center := Vector3(look_x, float(target.get("height", 1.08)), 0)
	match view:
		"front":
			camera.look_at_from_position(center + Vector3(0, 0.28, -distance), center)
		"three_quarter":
			camera.look_at_from_position(center + Vector3(distance * 0.63, 1.1, -distance * 0.79), center)
		"side":
			camera.look_at_from_position(center + Vector3(0, 0.28, -distance), center)
		"rear":
			camera.look_at_from_position(center + Vector3(0, 0.28, -distance), center)
		"rear_three_quarter":
			camera.look_at_from_position(center + Vector3(distance * 0.63, 1.1, -distance * 0.79), center)
		"top":
			# Explicit +Z up avoids degenerate look_at() with straight-down
			# camera; all three chassis stay spaced along world X.
			camera.look_at_from_position(
					center + Vector3(0, distance, 0),
					center, Vector3(0, 0, 1))


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
	var image := root.get_texture().get_image()
	if image == null or image.get_width() < 500:
		printerr("SHAPE_ERROR|viewport empty: %s" % views[step]["name"])
		quit(1)
		return true
	capture_images.append(image)
	step += 1
	if step >= views.size():
		# Five views, one combined PNG. Downscale only in this diagnostic,
		# never the sculpt or mesh, to keep uploads small.
		var tile_w := 1200
		var tile_h := 600
		var contact := Image.create(tile_w, tile_h * capture_images.size(),
				false, Image.FORMAT_RGBA8)
		for i in capture_images.size():
			var tile: Image = capture_images[i]
			tile.convert(Image.FORMAT_RGBA8)
			tile.resize(tile_w, tile_h, Image.INTERPOLATE_LANCZOS)
			contact.blit_rect(tile, Rect2i(0, 0, tile_w, tile_h),
					Vector2i(0, i * tile_h))
		var path := output_dir.path_join("gallery_three_quarter.png")
		if contact.save_png(path) != OK:
			printerr("SHAPE_ERROR|png write failed: %s" % path)
			quit(1)
			return true
		print("SHAPE_RENDER|gallery_three_quarter.png")
		quit(0)
		return true
	frame = 0
	_setup_view(step)
	return false
