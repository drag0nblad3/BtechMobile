extends TestCase
## Candidate reference poses alter only actual articulated joints.

func _rig() -> VxModel:
    var model := VxModel.new()
    model.parts = [
        {"name": "ct", "parent": "", "pivot": Vector3(0, 5, 0),
            "joint": "", "cells": {}},
        {"name": "ll", "parent": "ct", "pivot": Vector3(-1, 4, 0),
            "joint": "hip", "cells": {}},
        {"name": "ll_shin", "parent": "ll", "pivot": Vector3(-1, 2, 0),
            "joint": "knee", "cells": {}},
        {"name": "ra", "parent": "ct", "pivot": Vector3(2, 7, 0),
            "joint": "shoulder", "cells": {}}
    ]
    return model


func test_poses_include_neutral_and_only_existing_joint_movements() -> void:
    var rig := _rig()
    var baseline := ReferenceStanceRig.profile({}, "test", "front")
    var source := rig.parts.duplicate(true)
    var samples := ReferencePoseCandidates.candidates(rig, baseline)
    check(samples.size() >= 4, "test rig should support several stances")
    check(samples[0]["candidate_id"] == "reference_pose_guess",
        "base neutral pose is always first")
    for pose: Dictionary in samples:
        check(ReferenceStanceRig.errors(rig, pose).is_empty(),
            "every pose must satisfy joint constraints")
        for joint: String in pose["joints"]:
            check(["ll", "ll_shin", "ra"].has(joint),
                "non-articulated or fabricated joints must never move")
    check(rig.parts == source,
        "stance candidates may never edit authored part cells or pivots")


func test_no_articulation_means_only_neutral() -> void:
    var static_model := VxModel.new()
    static_model.parts = [{"name": "hull", "joint": "", "parent": "",
        "pivot": Vector3.ZERO, "cells": {}}]
    var baseline := ReferenceStanceRig.profile({}, "tank", "side")
    var samples := ReferencePoseCandidates.candidates(static_model, baseline)
    check(samples.size() == 1,
        "static vehicle should have no invented articulated stance")
