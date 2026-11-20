extends Node3D
## Orbit camera built for touch screens.
## Touch: one finger drags to orbit, two fingers pinch to zoom.
## Desktop: left or right mouse drag orbits, the wheel zooms.

@export var distance := 9.0
@export var min_distance := 3.0
@export var max_distance := 25.0
@export var yaw_degrees := 20.0
@export var pitch_degrees := 15.0
@export var min_pitch := 0.0
@export var max_pitch := 89.0
@export var orbit_speed := 0.3

var camera: Camera3D

var _touches := {}
var _pinch_start_distance := 0.0
var _pinch_start_zoom := 0.0


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	camera.make_current()
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = touch.position
		else:
			_touches.erase(touch.index)
		_pinch_start_distance = 0.0
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_touches[drag.index] = drag.position
		if _touches.size() == 1:
			_orbit(drag.relative)
		elif _touches.size() == 2:
			_pinch()
	elif event.device == InputEvent.DEVICE_ID_EMULATION:
		# Mouse events synthesized from touch are already handled above.
		return
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT)) != 0:
			_orbit(motion.relative)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_to(distance * 0.9)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_to(distance * 1.1)


func _orbit(relative: Vector2) -> void:
	yaw_degrees = fposmod(yaw_degrees - relative.x * orbit_speed, 360.0)
	pitch_degrees = clampf(pitch_degrees + relative.y * orbit_speed, min_pitch, max_pitch)
	_apply()


func _pinch() -> void:
	var points := _touches.values()
	var span := (points[0] as Vector2).distance_to(points[1] as Vector2)
	if span < 1.0:
		return
	if _pinch_start_distance <= 0.0:
		_pinch_start_distance = span
		_pinch_start_zoom = distance
		return
	_zoom_to(_pinch_start_zoom * _pinch_start_distance / span)


func _zoom_to(value: float) -> void:
	distance = clampf(value, min_distance, max_distance)
	_apply()


func _apply() -> void:
	rotation_degrees = Vector3(-pitch_degrees, yaw_degrees, 0.0)
	if camera:
		camera.position = Vector3(0.0, 0.0, distance)
