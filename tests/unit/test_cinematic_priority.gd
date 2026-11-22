extends TestCase


func test_cinematic_duration_is_short_and_bounded() -> void:
	check(CinematicDirector.HOLD_ACTION <= 1.0)
	check(CinematicDirector.HOLD_IMPACT <= 1.5)
	check(CinematicDirector.MAX_QUEUE <= 2)


func test_camera_impulse_is_clamped() -> void:
	var rig := CameraRig.new()
	rig.impact_kick(25.0)
	check(rig._shake <= 0.14, "effects must not disorient tactical controls")
