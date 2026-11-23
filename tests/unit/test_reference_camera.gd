extends TestCase
## Camera calibration changes the projected outline, not authored voxel cells.

static func _cube(origin: Vector3) -> PackedVector3Array:
    var out := PackedVector3Array()
    for x in 2:
        for y in 2:
            for z in 2:
                out.append(origin + Vector3(x, y, z))
    return out


func _sample() -> Array[PackedVector3Array]:
    return [_cube(Vector3(-3, 0, -2)), _cube(Vector3(0, 3, 2)),
        _cube(Vector3(3, 0, 5)), _cube(Vector3(-1, 7, -4))]


func test_camera_yaw_and_pitch_change_an_asymmetric_outline() -> void:
    var voxels := _sample()
    var front := ReferenceCamera.mask(voxels, ReferenceCamera.preset("front"), 64)
    var side := ReferenceCamera.mask(voxels, ReferenceCamera.preset("side"), 64)
    var top := ReferenceCamera.mask(voxels, ReferenceCamera.preset("top"), 64)
    check(not front.is_empty(), "front photo alignment must produce a mask")
    check(front != side, "yaw adjustment must change side silhouette")
    check(front != top, "pitch adjustment must change top silhouette")


func test_perspective_changes_depth_parallax_and_does_not_edit_cells() -> void:
    var cubes := _sample()
    var snapshot := cubes.duplicate(true)
    var camera := ReferenceCamera.preset("quarter")
    var ortho := ReferenceCamera.mask(cubes, camera, 64)
    camera["projection"] = "perspective"
    camera["distance_heights"] = 1.5
    var perspective := ReferenceCamera.mask(cubes, camera, 64)
    check(ortho != perspective, "reference perspective must alter projected silhouette")
    check(cubes == snapshot, "camera adjustment cannot modify model geometry")


func test_camera_overrides_are_per_view_not_per_sculpt() -> void:
    var catalog := {"models": {"example": {
        "default": {"camera": {"projection": "perspective",
            "distance_heights": 3.2}},
        "front": {"camera": {"yaw_deg": 12.0, "pitch_deg": -9.0}},
        "side": {"camera": {"yaw_deg": -84.0}}
    }}}
    var front := ReferenceStanceRig.profile(catalog, "example", "front")
    var side := ReferenceStanceRig.profile(catalog, "example", "side")
    check(front["camera"]["yaw_deg"] == 12.0, "front has matched yaw")
    check(front["camera"]["projection"] == "perspective", "common lens carries")
    check(side["camera"]["yaw_deg"] == -84.0, "side has independent yaw")
    check(side["camera"]["pitch_deg"] == 0.0, "side defaults to horizontal")


func test_invalid_camera_is_not_accepted_as_a_measured_pose() -> void:
    var bad := {"projection": "fish-eye", "pitch_deg": 140,
        "distance_heights": 0.5}
    check(ReferenceCamera.settings_errors(bad).size() == 3,
        "unsupported camera or impossible target position must be rejected")
