class_name ReferenceStanceRig
extends RefCounted
## Source-geometry silhouette projection under actual articulated part pivots.
## Angles rotate parts; nothing scales, shifts or alters the authored cells.

const MAX_BODY_TILT := 25.0
const MAX_JOINT_ROT := 120.0


static func profile(catalog: Dictionary, id: String, view: String) -> Dictionary:
    var spec: Dictionary = catalog.get("models", {}).get(id, {})
    var common: Dictionary = spec.get("default", {})
    var specific: Dictionary = spec.get(view, {})
    var joints: Dictionary = common.get("joints", {}).duplicate(true)
    joints.merge(specific.get("joints", {}), true)
    return {"joints": joints, "body_rotation_deg": specific.get(
        "body_rotation_deg", common.get("body_rotation_deg", [0, 0, 0]))}


static func errors(model: VxModel, pose: Dictionary) -> Array[String]:
    var issues: Array[String] = []
    var parts := {}
    for p: Dictionary in model.parts:
        parts[p["name"]] = p
    for id: String in pose.get("joints", {}):
        if not parts.has(id):
            issues.append("Unknown joint " + id)
            continue
        if String(parts[id].get("joint", "")).is_empty():
            issues.append("Part has no articulated joint: " + id)
            continue
        _check_angles(pose["joints"][id], MAX_JOINT_ROT, id, issues)
    _check_angles(pose.get("body_rotation_deg", [0, 0, 0]),
        MAX_BODY_TILT, "body", issues)
    return issues


static func _check_angles(values: Variant, limit: float, id: String,
        issues: Array[String]) -> void:
    if not values is Array or values.size() != 3:
        issues.append(id + ": requires three Euler angles in degrees")
        return
    for value: Variant in values:
        if not (value is float or value is int):
            issues.append(id + ": non-numeric angle")
            return
        if absf(float(value)) > limit:
            issues.append(id + ": exceeds safe pose rotation bound")
            return


static func _basis(angles: Array) -> Basis:
    return Basis.from_euler(Vector3(deg_to_rad(float(angles[0])),
        deg_to_rad(float(angles[1])), deg_to_rad(float(angles[2]))))


static func project(model: VxModel, view: String, pose: Dictionary,
        size: int = 64) -> Dictionary:
    var transforms := {}
    var pivots := {}
    var body_basis := _basis(pose.get("body_rotation_deg", [0, 0, 0]))
    var body := Transform3D(body_basis, Vector3.ZERO)
    var joints: Dictionary = pose.get("joints", {})
    var points := {}
    for part: Dictionary in model.parts:
        var id: String = part["name"]
        var parent: String = part.get("parent", "")
        var pivot: Vector3 = part["pivot"]
        var base: Vector3 = pivots.get(parent, Vector3.ZERO)
        var parent_transform: Transform3D = transforms.get(parent, body)
        var angles: Array = joints.get(id, [0, 0, 0])
        var local_joint := Transform3D(_basis(angles), pivot - base)
        var transform: Transform3D = parent_transform * local_joint
        transforms[id] = transform
        pivots[id] = pivot
        for c: Vector3i in part["cells"]:
            var center: Vector3 = Vector3(c) + Vector3.ONE * 0.5 - pivot
            var p: Vector3 = transform * center
            points[Vector3i(roundi(p.x), roundi(p.y), roundi(p.z))] = true
    return VxSilhouette.project(points, view, size)
