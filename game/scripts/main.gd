extends Node3D
## Prototype scene: a hex board, a few placeholder mechs drawn as directional
## sprites, a touch orbit camera and a small HUD.

const HexGrid := preload("res://scripts/hex_grid.gd")
const CameraRig := preload("res://scripts/camera_rig.gd")
const DirectionalSprite := preload("res://scripts/directional_sprite.gd")

const HEX_RADIUS := 1.0
const GRID_RADIUS := 6
const MECHS := [
	{"hex": Vector2i(0, 0), "facing": 0},
	{"hex": Vector2i(2, -2), "facing": 2},
	{"hex": Vector2i(-3, 1), "facing": 4},
]

var _mechs: Array[DirectionalSprite] = []
var _rig: CameraRig
var _status: Label


func _ready() -> void:
	_build_environment()
	_build_board()
	for entry in MECHS:
		var mech := DirectionalSprite.new()
		mech.position = HexGrid.axial_to_world(entry["hex"], HEX_RADIUS)
		mech.facing = entry["facing"]
		add_child(mech)
		_mechs.append(mech)
	_rig = CameraRig.new()
	_rig.position = Vector3(0.0, 1.0, 0.0)
	add_child(_rig)
	_build_hud()


func _process(_delta: float) -> void:
	_status.text = "FPS %d   camera pitch %d°   center mech view: %s" % [
		Engine.get_frames_per_second(),
		roundi(_rig.pitch_degrees),
		_mechs[0].current_view_name(),
	]


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.53, 0.62, 0.70)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	add_child(sun)


func _build_board() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	ground.mesh = plane
	ground.position.y = -0.01
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.12, 0.13, 0.12)
	ground.material_override = ground_mat
	add_child(ground)

	var board := MeshInstance3D.new()
	board.mesh = HexGrid.build_mesh(GRID_RADIUS, HEX_RADIUS, 0.05)
	var board_mat := StandardMaterial3D.new()
	board_mat.vertex_color_use_as_albedo = true
	board_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	board.material_override = board_mat
	add_child(board)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box := VBoxContainer.new()
	box.position = Vector2(32.0, 24.0)
	box.add_theme_constant_override("separation", 12)
	layer.add_child(box)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 22)
	box.add_child(_status)

	var rotate_button := Button.new()
	rotate_button.text = "Rotate mechs"
	rotate_button.custom_minimum_size = Vector2(240.0, 72.0)
	rotate_button.add_theme_font_size_override("font_size", 24)
	rotate_button.pressed.connect(_on_rotate_pressed)
	box.add_child(rotate_button)

	var hint := Label.new()
	hint.text = "Drag to orbit, pinch to zoom"
	hint.add_theme_font_size_override("font_size", 18)
	box.add_child(hint)


func _on_rotate_pressed() -> void:
	for mech in _mechs:
		mech.facing += 1
