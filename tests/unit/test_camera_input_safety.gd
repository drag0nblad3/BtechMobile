extends TestCase
## Invalid camera input never reaches rendering transforms.


func test_camera_ignores_nonfinite_gestures() -> void:
	var rig := CameraRig.new()
	var before := rig.capture_pose()
	rig.pan(Vector2(INF, 0))
	rig.zoom(NAN)
	rig.zoom(0.0)
	rig.orbit(INF)
	rig.tilt(NAN)
	check_eq(rig.capture_pose(), before)
	for i in 100:
		rig.orbit(3.0)
	check(absf(float(rig.capture_pose()["yaw"])) <= PI)
	rig.free()


func test_unknown_touch_release_is_not_a_map_tap() -> void:
	var gestures := TouchGestures.new()
	var taps: Array[Vector2] = []
	gestures.tapped.connect(func(p: Vector2): taps.append(p))
	var touch := InputEventScreenTouch.new()
	touch.index = 9
	touch.position = Vector2(300, 300)
	touch.pressed = false
	gestures._on_touch(touch)
	check(taps.is_empty())
	gestures.free()
