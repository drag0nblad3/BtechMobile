class_name ReferencePoseCandidates
extends RefCounted
## Exploratory reference-stance candidates. Only actual authored joints move.
## Pose tests do NOT approve camera, ground contact, or sculpt fidelity.

const CHANGES := {
    "wide_stance": {
        "ll": [0, 0, -10], "rl": [0, 0, 10],
        "la": [0, 0, -8], "ra": [0, 0, 8]},
    "narrow_stance": {
        "ll": [0, 0, 8], "rl": [0, 0, -8]},
    "step_left": {
        "ll": [-18, 0, -5], "ll_shin": [30, 0, 0],
        "ll_foot": [-12, 0, 0],
        "rl": [14, 0, 5], "rl_shin": [-12, 0, 0],
        "rl_foot": [4, 0, 0]},
    "step_right": {
        "rl": [-18, 0, 5], "rl_shin": [30, 0, 0],
        "rl_foot": [-12, 0, 0],
        "ll": [14, 0, -5], "ll_shin": [-12, 0, 0],
        "ll_foot": [4, 0, 0]},
    "aim_left": {
        "la": [-8, 0, -22], "ra": [4, 0, 7]},
    "aim_right": {
        "ra": [-8, 0, 22], "la": [4, 0, -7]},
    "shallow_crouch": {
        "ll": [-12, 0, -4], "rl": [-12, 0, 4],
        "ll_shin": [22, 0, 0], "rl_shin": [22, 0, 0],
        "ll_foot": [-8, 0, 0], "rl_foot": [-8, 0, 0]}
}


static func candidates(model: VxModel, baseline: Dictionary) -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    var supported := {}
    for part: Dictionary in model.parts:
        if not String(part.get("joint", "")).is_empty():
            supported[String(part["name"])] = true
    var neutral := baseline.duplicate(true)
    neutral["candidate_id"] = "reference_pose_guess"
    options.append(neutral)
    for id: String in CHANGES:
        var deltas: Dictionary = CHANGES[id]
        var pose := baseline.duplicate(true)
        var joints: Dictionary = pose.get("joints", {}).duplicate(true)
        var changed := false
        for joint: String in deltas:
            if not supported.has(joint):
                continue
            var offsets: Array = deltas[joint]
            var original: Array = joints.get(joint, [0, 0, 0])
            var angles: Array = []
            for index in 3:
                angles.append(float(original[index]) + float(offsets[index]))
            joints[joint] = angles
            changed = true
        if not changed:
            continue
        pose["joints"] = joints
        if not ReferenceStanceRig.errors(model, pose).is_empty():
            continue
        pose["candidate_id"] = id
        options.append(pose)
    return options
