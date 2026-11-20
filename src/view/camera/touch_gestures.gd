class_name TouchGestures
extends Node
## Turns raw touch (and mouse, for desktop testing) into gestures.
## Touch: 1 finger drag = pan, tap, double tap; 2 fingers = pinch zoom,
## twist to orbit, drag up/down together to tilt.
## Mouse: left drag = pan, right drag = orbit/tilt, wheel = zoom.

signal tapped(pos: Vector2)
signal double_tapped(pos: Vector2)
signal panned(delta: Vector2)
signal pinched(factor: float)
signal twisted(radians: float)
signal tilted(delta_px: float)

const TAP_MAX_MOVE := 14.0
const TAP_MAX_TIME := 0.35
const DOUBLE_TAP_TIME := 0.35

var _touches := {}       # index -> position
var _press_pos := Vector2.ZERO
var _press_time := 0.0
var _moved := false
var _last_tap_time := -10.0
var _last_tap_pos := Vector2.ZERO
var _right_drag := false


func _unhandled_input(e: InputEvent) -> void:
	if e.device == InputEvent.DEVICE_ID_EMULATION:
		return  # Mouse events synthesized from touch; we read touch directly.
	if e is InputEventScreenTouch:
		_on_touch(e)
	elif e is InputEventScreenDrag:
		_on_drag(e)
	elif e is InputEventMouseButton:
		_on_mouse_button(e)
	elif e is InputEventMouseMotion:
		_on_mouse_motion(e)


func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = e.position
		if _touches.size() == 1:
			_begin_press(e.position)
		else:
			_moved = true  # Multi-touch is never a tap.
	else:
		_touches.erase(e.index)
		if _touches.is_empty():
			_end_press(e.position)


func _on_drag(e: InputEventScreenDrag) -> void:
	if not _touches.has(e.index):
		return
	if _touches.size() == 1:
		_touches[e.index] = e.position
		_note_move(e.position)
		if _moved:
			panned.emit(e.relative)
		return
	var keys := _touches.keys()
	var other: Vector2 = _touches[keys[0] if keys[0] != e.index else keys[1]]
	var before: Vector2 = _touches[e.index]
	_touches[e.index] = e.position
	var v0 := before - other
	var v1 := e.position - other
	if v0.length() > 1.0:
		pinched.emit(v1.length() / v0.length())
		twisted.emit(v0.angle_to(v1))
	# Each finger reports separately; half the vertical motion per finger.
	tilted.emit(e.relative.y * 0.5)


func _on_mouse_button(e: InputEventMouseButton) -> void:
	match e.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if e.pressed: pinched.emit(1.1)
		MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed: pinched.emit(1.0 / 1.1)
		MOUSE_BUTTON_RIGHT:
			_right_drag = e.pressed
		MOUSE_BUTTON_LEFT:
			if e.pressed:
				_begin_press(e.position)
			else:
				_end_press(e.position)


func _on_mouse_motion(e: InputEventMouseMotion) -> void:
	if _right_drag:
		twisted.emit(-e.relative.x * 0.008)
		tilted.emit(e.relative.y)
	elif e.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_note_move(e.position)
		if _moved:
			panned.emit(e.relative)


func _begin_press(pos: Vector2) -> void:
	_press_pos = pos
	_press_time = _now()
	_moved = false


func _note_move(pos: Vector2) -> void:
	if pos.distance_to(_press_pos) > TAP_MAX_MOVE:
		_moved = true


func _end_press(pos: Vector2) -> void:
	if _moved or _now() - _press_time > TAP_MAX_TIME:
		return
	var t := _now()
	if t - _last_tap_time < DOUBLE_TAP_TIME and pos.distance_to(_last_tap_pos) < 40.0:
		_last_tap_time = -10.0
		double_tapped.emit(pos)
	else:
		_last_tap_time = t
		_last_tap_pos = pos
		tapped.emit(pos)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
