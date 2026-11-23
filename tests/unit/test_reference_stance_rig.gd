extends TestCase
## Pose-matched silhouette scoring may move authored joints but never edit cells.

func _sample_mech() -> VxModel:
    var m := VxModel.new()
    var torso := {}
    var thigh := {}
    var shin := {}
    for y in range(5, 11):
        for x in range(-2, 3):
            torso[Vector3i(x, y, 0)] = 0
    for y in range(2, 5):
        thigh[Vector3i(-1, y, 0)] = 0
    for y in range(-1, 2):
        shin[Vector3i(-1, y, 0)] = 0
    m.parts = [
        {"name": "ct", "parent": "", "pivot": Vector3(0, 6, 0),
            "joint": "", "cells": torso},
        {"name": "ll", "parent": "ct", "pivot": Vector3(-1, 4, 0),
            "joint": "hip", "cells": thigh},
        {"name": "ll_shin", "parent": "ll", "pivot": Vector3(-1, 1, 0),
            "joint": "knee", "cells": shin}
    ]
    return m


func test_pose_changes_projected_silhouette_without_moving_source_cells() -> void:
    var m := _sample_mech()
    var original: Dictionary = m.parts[2]["cells"].duplicate(true)
    var standing := ReferenceStanceRig.profile({}, "example", "side")
    var flexed := {"joints": {"ll": [30, 0, 0], "ll_shin": [-50, 0, 0]},
        "body_rotation_deg": [0, 0, 0]}
    check(ReferenceStanceRig.errors(m, flexed).is_empty(),
        "normal articulated stance should be accepted")
    var before := ReferenceStanceRig.project(m, "side", standing, 64)
    var after := ReferenceStanceRig.project(m, "side", flexed, 64)
    check(before != after, "knee and hip motion must change side outline")
    check(m.parts[2]["cells"] == original, "rig matching must not mutate source geometry")


func test_rejects_fabricated_non_joint_rotation() -> void:
    var m := _sample_mech()
    var bad := {"joints": {"ct": [45, 0, 0], "missing_joint": [0, 0, 5]},
        "body_rotation_deg": [0, 0, 0]}
    check(ReferenceStanceRig.errors(m, bad).size() == 2,
        "no unauthorized body part articulation or invented joint names")


func test_common_and_view_specific_joint_rotations() -> void:
    var catalog := {"models": {"sample": {
        "default": {"joints": {"ll": [12, 0, 0], "ll_shin": [-24, 0, 0]}},
        "front": {"joints": {"ll": [8, 0, 0]}}
    }}}
    var front := ReferenceStanceRig.profile(catalog, "sample", "front")
    var side := ReferenceStanceRig.profile(catalog, "sample", "side")
    check(front["joints"]["ll"][0] == 8, "specific pose must override default")
    check(front["joints"]["ll_shin"][0] == -24, "unmodified joints remain posed")
    check(side["joints"]["ll"][0] == 12, "other angles use common pose")
