extends TestCase
## Guard against accidental pitch when pinching and rotating the camera.


func _two_touch() -> TouchGestures:
	var gestures := TouchGestures.new()
	for i in 2:
		var touch := InputEventScreenTouch.new()
		touch.index = i
		touch.position = Vector2(100 + i * 100, 100)
		touch.pressed = true
		gestures._on_touch(touch)
	return gestures


func _drag(gestures: TouchGestures, index: int, pos: Vector2, delta: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.index = index
	drag.position = pos
	drag.relative = delta
	gestures._on_drag(drag)


func test_pinch_does_not_tilt() -> void:
	var gestures := _two_touch()
	var pinch: Array[float] = []
	var tilt: Array[float] = []
	gestures.pinched.connect(func(v: float): pinch.append(v))
	gestures.tilted.connect(func(v: float): tilt.append(v))
	_drag(gestures, 1, Vector2(220, 100), Vector2(20, 0))
	check_eq(pinch.size(), 1, "pinch should zoom")
	check_eq(tilt.size(), 0, "pinch must not tilt")
	gestures.free()


func test_twist_does_not_tilt() -> void:
	var gestures := _two_touch()
	var orbit: Array[float] = []
	var tilt: Array[float] = []
	gestures.twisted.connect(func(v: float): orbit.append(v))
	gestures.tilted.connect(func(v: float): tilt.append(v))
	_drag(gestures, 1, Vector2(200, 120), Vector2(0, 20))
	check(orbit.size() > 0, "twist should orbit")
	check_eq(tilt.size(), 0, "twist must not tilt")
	gestures.free()


func test_two_finger_drag_still_tilts() -> void:
	var gestures := _two_touch()
	var tilt: Array[float] = []
	gestures.tilted.connect(func(v: float): tilt.append(v))
	_drag(gestures, 0, Vector2(100, 101), Vector2(0, 1))
	_drag(gestures, 1, Vector2(200, 101), Vector2(0, 1))
	check_eq(tilt.size(), 2, "parallel drag should tilt")
	gestures.free()
