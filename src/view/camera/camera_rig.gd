class_name CameraRig
extends Node3D
## Orbit camera: looks at `target` from `distance`, rotated by yaw/pitch.
## Inputs set goal values; the camera eases toward them every frame.

const MIN_DIST := 4.0
const MAX_DIST := 40.0
const MIN_PITCH := deg_to_rad(15.0)
const MAX_PITCH := deg_to_rad(88.0)
const EASE := 12.0

var camera: Camera3D
var bounds := AABB(Vector3(-50, 0, -50), Vector3(100, 0, 100))

var _target := Vector3.ZERO
var _yaw := 0.0
var _pitch := deg_to_rad(55.0)
var _dist := 20.0
var _goal_target := Vector3.ZERO
var _goal_yaw := 0.0
var _goal_pitch := deg_to_rad(55.0)
var _goal_dist := 20.0


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.far = 400.0
	add_child(camera)
	_apply()


func _process(delta: float) -> void:
	var t := 1.0 - exp(-EASE * delta)
	_target = _target.lerp(_goal_target, t)
	_yaw = lerp_angle(_yaw, _goal_yaw, t)
	_pitch = lerpf(_pitch, _goal_pitch, t)
	_dist = lerpf(_dist, _goal_dist, t)
	_apply()


## Drag the map: screen pixels -> ground movement, scaled by zoom.
func pan(screen_delta: Vector2) -> void:
	var k := _goal_dist * 0.0022
	var right := Vector3(cos(_goal_yaw), 0, -sin(_goal_yaw))
	var fwd := Vector3(-sin(_goal_yaw), 0, -cos(_goal_yaw))
	_goal_target += (-right * screen_delta.x + fwd * screen_delta.y) * k
	_goal_target = _clamp_to_bounds(_goal_target)


## factor > 1 zooms in.
func zoom(factor: float) -> void:
	_goal_dist = clampf(_goal_dist / maxf(factor, 0.01), MIN_DIST, MAX_DIST)


func orbit(delta_yaw: float) -> void:
	_goal_yaw += delta_yaw


func tilt(delta_pitch: float) -> void:
	_goal_pitch = clampf(_goal_pitch + delta_pitch, MIN_PITCH, MAX_PITCH)


func focus(point: Vector3) -> void:
	_goal_target = _clamp_to_bounds(point)


## Glide to this camera distance (clamped to the zoom limits).
func set_distance(dist: float) -> void:
	_goal_dist = clampf(dist, MIN_DIST, MAX_DIST)


func distance() -> float:
	return _goal_dist


## Temporarily reframe on a dramatic action without moving the physical camera instantly.
func cinematic_frame(point: Vector3, distance: float, yaw: float, pitch: float) -> void:
	_goal_target = _clamp_to_bounds(point)
	_goal_dist = clampf(distance, MIN_DIST, MAX_DIST)
	_goal_yaw = yaw
	_goal_pitch = clampf(pitch, MIN_PITCH, MAX_PITCH)


func capture_pose() -> Dictionary:
	return {"target": _goal_target, "distance": _goal_dist,
			"yaw": _goal_yaw, "pitch": _goal_pitch}


func restore_pose(pose: Dictionary) -> void:
	if pose.is_empty():
		return
	cinematic_frame(pose["target"], float(pose["distance"]),
			float(pose["yaw"]), float(pose["pitch"]))


## Top-down tactical view toggle.
func toggle_top_down() -> void:
	_goal_pitch = deg_to_rad(55.0) if _goal_pitch > deg_to_rad(80.0) else MAX_PITCH


func snap(point: Vector3, dist: float) -> void:
	_goal_target = point
	_target = point
	_goal_dist = dist
	_dist = dist
	_apply()


func _apply() -> void:
	if camera == null:
		return
	var offset := Vector3(
			sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	camera.position = _target + offset
	camera.look_at(_target, Vector3.UP)


func _clamp_to_bounds(p: Vector3) -> Vector3:
	var lo := bounds.position
	var hi := bounds.end
	return Vector3(clampf(p.x, lo.x, hi.x), p.y, clampf(p.z, lo.z, hi.z))
