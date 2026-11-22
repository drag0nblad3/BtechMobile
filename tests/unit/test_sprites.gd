extends TestCase
## Sprite view selection (no art needed).


func test_view_index_follows_camera() -> void:
	var b := Basis()  # 'Mech faces -Z (north)
	check_eq(SpriteMech.view_index(b, Vector3(0, 5, -10)), 0, "camera in front")
	check_eq(SpriteMech.view_index(b, Vector3(0, 5, 10)), 3, "camera behind")
	check_eq(SpriteMech.view_index(b, Vector3(10, 5, -6)), 1, "camera front-right (east of a north-facing 'Mech)")
	check_eq(SpriteMech.view_index(b, Vector3(-10, 5, -6)), 5, "camera front-left")
	var turned := Basis(Vector3.UP, -PI / 3.0)  # facing 1 (NE), as UnitView rotates it
	check_eq(SpriteMech.view_index(turned, -turned.z * 10.0), 0, "front follows facing")


func test_missing_sprite_falls_back() -> void:
	var def := designs().get_def("atlas_as7d")
	check(SpriteMech.try_build(def) == null, "no art yet -> placeholder")
