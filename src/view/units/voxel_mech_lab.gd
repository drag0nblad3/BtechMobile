class_name VoxelMechLab
extends Node3D
## Isolated runtime test: walk, rotate camera, fire voxel blasts, sever limbs.

var mech: VoxelMech
var profiles: Array[Dictionary] = []
var profile_index := 0
var stability_slider: HSlider
var chassis_selector: OptionButton
var stability_label: Label
var camera: Camera3D
var info: Label
var catalog_label: Label
var _catalog_counts: Dictionary = {}
var _catalog_cursor := 0
var _orbit := 2.58
var _elevation := 0.33
var _distance := 5.8
var _right_drag := false
var _touch_dragged := false
var _last_hit := "No impacts yet"


func _ready() -> void:
	profiles = VoxelChassis.all()
	make_arena()
	_spawn_mech()
	make_camera()
	make_hud()
	mech.start_walk()


func _spawn_mech() -> void:
	mech = VoxelMech.new()
	mech.name = "VoxelMech"
	mech.profile_id = str(profiles[profile_index]["id"])
	mech.detail_level = int(profiles[profile_index].get("voxel_detail", 1))
	mech.upper_stability = stability_slider.value if stability_slider else 0.90
	add_child(mech)
	mech.struck.connect(_on_struck)
	_catalog_counts[mech.profile_id] = mech.initial_voxels()
	_refresh_catalog()


func make_arena() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("152333")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b5cee8")
	env.ambient_light_energy = 0.70
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-56, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	var ground := StaticBody3D.new()
	ground.name = "HangarFloor"
	ground.position.y = -0.15
	add_child(ground)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(14, 0.26, 14)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("293949")
	material.roughness = 0.9
	floor_mesh.material = material
	var surface := MeshInstance3D.new()
	surface.mesh = floor_mesh
	ground.add_child(surface)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = floor_mesh.size
	collision.shape = shape
	ground.add_child(collision)
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color("3e6271")
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(-6, 7):
		make_line(Vector3(i, 0.008, 0), Vector3(0.012, 0.012, 12), grid_mat)
		make_line(Vector3(0, 0.008, i), Vector3(12, 0.012, 0.012), grid_mat)


func make_line(pos: Vector3, size: Vector3, material: Material) -> void:
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	cube.mesh = mesh
	cube.position = pos
	add_child(cube)


func make_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 48.0
	add_child(camera)
	update_camera()


func update_camera() -> void:
	var target := Vector3(0, 1.25, 0)
	camera.position = target + Vector3(sin(_orbit) * cos(_elevation),
		sin(_elevation), cos(_orbit) * cos(_elevation)) * _distance
	camera.look_at(target, Vector3.UP)


func make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -620.0
	panel.offset_right = -16.0
	panel.offset_top = 16.0
	layer.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.88)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = "VOXEL MECH — WALK + DESTRUCTION LAB"
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 14)
	column.add_child(info)
	catalog_label = Label.new()
	catalog_label.name = "VoxelCatalog"
	catalog_label.add_theme_font_size_override("font_size", 13)
	column.add_child(catalog_label)
	_refresh_catalog()
	var tuning := HBoxContainer.new()
	column.add_child(tuning)
	var selector := OptionButton.new()
	selector.name = "ChassisSelector"
	selector.custom_minimum_size = Vector2(230, 48)
	for profile in profiles:
		selector.add_item(str(profile["name"]))
	selector.selected = profile_index
	chassis_selector = selector
	selector.item_selected.connect(_select_chassis)
	tuning.add_child(selector)
	stability_label = Label.new()
	stability_label.text = "Upper stability 90%"
	stability_label.custom_minimum_size.x = 155
	tuning.add_child(stability_label)
	stability_slider = HSlider.new()
	stability_slider.name = "UpperStability"
	stability_slider.custom_minimum_size = Vector2(160, 44)
	stability_slider.min_value = 0.0
	stability_slider.max_value = 1.0
	stability_slider.step = 0.05
	stability_slider.value = 0.90
	stability_slider.value_changed.connect(_set_stability)
	tuning.add_child(stability_slider)
	var first := HBoxContainer.new()
	column.add_child(first)
	add_button(first, "WALK TEST", func(): mech.start_walk())
	add_button(first, "TORSO HIT", func(): blast("torso"))
	add_button(first, "LEFT LEG", func(): blast("left_leg"))
	var second := HBoxContainer.new()
	column.add_child(second)
	add_button(second, "RIGHT LEG", func(): blast("right_leg"))
	add_button(second, "SEVER RIGHT", sever_right)
	add_button(second, "RESET", reset_lab)
	var back := add_button(second, "MAIN MENU", _open_launcher)
	back.name = "BackToLauncher"
	var help := Label.new()
	help.text = "Shots now carve variable jagged craters · swipe to orbit · scroll to zoom"
	help.add_theme_font_size_override("font_size", 12)
	column.add_child(help)


func add_button(parent: HBoxContainer, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(118, 52)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _open_launcher() -> void:
	get_tree().change_scene_to_file("res://scenes/launcher.tscn")


func _select_chassis(index: int) -> void:
	profile_index = index
	if chassis_selector:
		chassis_selector.select(index)
	reset_lab()


func _set_stability(value: float) -> void:
	mech.upper_stability = value
	stability_label.text = "Upper stability %d%%" % roundi(value * 100.0)


func blast(key: String) -> void:
	var part: VoxelPart = mech.parts[key]
	# Each scripted shot picks a slightly different impact position, in addition
	# to the per-voxel irregularity applied by VoxelMech.hit_part.
	var offset := Vector3(randf_range(-0.13, 0.13),
			randf_range(-0.11, 0.11), randf_range(-0.10, 0.10))
	var world_hit := part.to_global(Vector3(0, -0.15, -0.22) + offset)
	mech.hit_part(key, world_hit, 0.30)
	flash(world_hit)


func flash(at: Vector3) -> void:
	var spark := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.07
	ball.height = 0.14
	spark.mesh = ball
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ffd480")
	spark.material_override = material
	add_child(spark)
	spark.global_position = at
	var tween := create_tween()
	tween.tween_property(spark, "scale", Vector3.ZERO, 0.25)
	tween.tween_callback(spark.queue_free)


func sever_right() -> void:
	mech.detach("right_leg")
	_last_hit = "Right leg detached for physics test"


func reset_lab() -> void:
	mech.queue_free()
	_spawn_mech()
	_last_hit = "Loaded %s: %s" % [profiles[profile_index]["name"], profiles[profile_index]["gait"]]
	mech.start_walk()


func _on_struck(part_name: String, removed: int, detached: bool) -> void:
	_last_hit = "%s: %d voxels removed%s" % [part_name, removed,
		" — LIMB DETACHED" if detached else ""]


func _process(_delta: float) -> void:
	# Count one mesh-free chassis per frame. This avoids a large up-front stall
	# and reports exact generated geometry, not estimated authoring volumes.
	if _catalog_cursor < profiles.size():
		_count_next_profile()
	var l := mech.gait_foot(mech.gait_phase).x
	var r := mech.gait_foot(mech.gait_phase + 0.5).x
	var initial := mech.initial_voxels()
	var remaining := mech.remaining_voxels()
	info.text = "FPS %d | %d / %d voxels (%d lost) | %.1f mm\nLeft %.2f Right %.2f | %s" % [
		Engine.get_frames_per_second(), remaining, initial, initial - remaining,
		mech.parts["torso"].voxel_size * 1000.0, l, r, _last_hit]


func _count_next_profile() -> void:
	var profile: Dictionary = profiles[_catalog_cursor]
	_catalog_cursor += 1
	var id := str(profile["id"])
	if not _catalog_counts.has(id):
		var sample := VoxelMech.new()
		sample.profile_id = id
		sample.detail_level = int(profile.get("voxel_detail", 1))
		sample.render_surfaces = false
		sample.build()
		_catalog_counts[id] = sample.initial_voxels()
		sample.free()
	_refresh_catalog()


func _refresh_catalog() -> void:
	if catalog_label == null:
		return
	var lines := PackedStringArray()
	lines.append("INITIAL VOXELS PER MODEL")
	for profile in profiles:
		var id := str(profile["id"])
		var count := str(_catalog_counts[id]) if _catalog_counts.has(id) else "calculating..."
		var detail := int(profile.get("voxel_detail", 1))
		lines.append("%s: %s  (%s)" % [str(profile["name"]), count,
				"high" if detail == 2 else "standard"])
	catalog_label.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_right_drag = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			fire_at_screen(event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(3.5, _distance - 0.5)
			update_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(12.0, _distance + 0.5)
			update_camera()
	elif event is InputEventMouseMotion and _right_drag:
		_orbit -= event.relative.x * 0.012
		_elevation = clampf(_elevation + event.relative.y * 0.008, 0.08, 1.10)
		update_camera()
	elif event is InputEventScreenDrag:
		_touch_dragged = true
		_orbit -= event.relative.x * 0.010
		_elevation = clampf(_elevation + event.relative.y * 0.007, 0.08, 1.10)
		update_camera()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_dragged = false
		elif not _touch_dragged:
			fire_at_screen(event.position)


func fire_at_screen(point: Vector2) -> void:
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var hit := mech.shoot(origin, direction)
	if not hit.is_empty():
		flash(hit["point"])
