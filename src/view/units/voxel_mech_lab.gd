class_name VoxelMechLab
extends Node3D
## Isolated runtime test: walk, rotate camera, fire voxel blasts, sever limbs.

var mech: VoxelMech
var camera: Camera3D
var info: Label
var _orbit := 2.58
var _elevation := 0.33
var _distance := 5.8
var _right_drag := false
var _touch_dragged := false
var _last_hit := "No impacts yet"


func _ready() -> void:
	make_arena()
	mech = VoxelMech.new()
	mech.name = "VoxelMech"
	add_child(mech)
	mech.struck.connect(_on_struck)
	make_camera()
	make_hud()
	mech.start_walk()


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
	panel.position = Vector2(16, 16)
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
	var help := Label.new()
	help.text = "Tap mech to shoot · right-drag / swipe to orbit · scroll to zoom"
	help.add_theme_font_size_override("font_size", 12)
	column.add_child(help)


func add_button(parent: HBoxContainer, title: String, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(118, 52)
	button.pressed.connect(action)
	parent.add_child(button)


func blast(key: String) -> void:
	var part: VoxelPart = mech.parts[key]
	var world_hit := part.to_global(Vector3(0, -0.15, -0.22))
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
	mech = VoxelMech.new()
	add_child(mech)
	mech.struck.connect(_on_struck)
	_last_hit = "Reset: all armor restored"
	mech.start_walk()


func _on_struck(part_name: String, removed: int, detached: bool) -> void:
	_last_hit = "%s: %d voxels removed%s" % [part_name, removed,
		" — LIMB DETACHED" if detached else ""]


func _process(_delta: float) -> void:
	var l := VoxelGait.foot_target(mech.gait_phase).x
	var r := VoxelGait.foot_target(mech.gait_phase + 0.5).x
	info.text = "FPS %d  |  Voxels %d  |  Left %.2f  Right %.2f\n%s" % [
		Engine.get_frames_per_second(), mech.remaining_voxels(), l, r, _last_hit]


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
