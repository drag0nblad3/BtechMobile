class_name ReferenceCamera
extends RefCounted
## Camera-angle and projection calibration for reference silhouette evaluation.
## Geometry is never moved to compensate for a mismatched photograph.

const DEFAULTS := {
    "front": 0.0, "side": -90.0, "quarter": 45.0, "top": 0.0
}
const MARGIN := 3


static func preset(view: String) -> Dictionary:
    return {"yaw_deg": float(DEFAULTS.get(view, 0.0)),
        "pitch_deg": -90.0 if view == "top" else 0.0,
        "roll_deg": 0.0, "projection": "orthographic",
        "distance_heights": 3.5}


static func settings_errors(spec: Dictionary) -> Array[String]:
    var issues: Array[String] = []
    if not str(spec.get("projection", "orthographic")) in [
            "orthographic", "perspective"]:
        issues.append("projection must be orthographic or perspective")
    for key: String in ["yaw_deg", "pitch_deg", "roll_deg",
            "distance_heights"]:
        var value: Variant = spec.get(key, 0.0)
        if not (value is int or value is float):
            issues.append(key + " must be numeric")
            continue
        var f := float(value)
        if not is_finite(f):
            issues.append(key + " must be finite")
        if key == "pitch_deg" and absf(f) > 95.0:
            issues.append("pitch_deg out of range")
        if key == "roll_deg" and absf(f) > 180.0:
            issues.append("roll_deg out of range")
        if key == "distance_heights" and (f < 1.4 or f > 40.0):
            issues.append("camera distance_heights out of range")
    return issues


static func _project_vertex(vertex: Vector3, center: Vector3,
        basis: Basis, spec: Dictionary, distance: float) -> Vector2:
    var local: Vector3 = basis * (vertex - center)
    if spec.get("projection", "orthographic") == "perspective":
        var depth := maxf(0.15 * distance, distance - local.z)
        local *= distance / depth
    return Vector2(local.x, -local.y)


## Each item is 8 world-space corners of a transformed occupied voxel.
## Fit the projected mesh uniformly into a mask, never stretch X/Y separately.
static func mask(cells: Array[PackedVector3Array], spec: Dictionary,
        size: int = 64) -> Dictionary:
    if cells.is_empty():
        return {}
    var lo := Vector3(INF, INF, INF)
    var hi := Vector3(-INF, -INF, -INF)
    for cube: PackedVector3Array in cells:
        for p: Vector3 in cube:
            lo = lo.min(p)
            hi = hi.max(p)
    var center: Vector3 = (lo + hi) * 0.5
    var distance := (hi.y - lo.y) * float(spec.get("distance_heights", 3.5))
    distance = maxf(distance, 1.0)
    var rot := Vector3(deg_to_rad(float(spec.get("pitch_deg", 0.0))),
        deg_to_rad(float(spec.get("yaw_deg", 0.0))),
        deg_to_rad(float(spec.get("roll_deg", 0.0))))
    var basis := Basis.from_euler(rot).inverse()
    var projected: Array[PackedVector2Array] = []
    var low := Vector2(INF, INF)
    var high := Vector2(-INF, -INF)
    for cube: PackedVector3Array in cells:
        var polygon := PackedVector2Array()
        for point: Vector3 in cube:
            var uv := _project_vertex(point, center, basis, spec, distance)
            polygon.append(uv)
            low = low.min(uv)
            high = high.max(uv)
        projected.append(Geometry2D.convex_hull(polygon))
    var extent := maxf(0.001, maxf(high.x - low.x, high.y - low.y))
    var scale := float(size - 2 * MARGIN) / extent
    var shift := Vector2.ONE * (float(size - 1) * 0.5) - (
        low + high) * (0.5 * scale)
    var pixels := {}
    for hull: PackedVector2Array in projected:
        if hull.size() < 3:
            continue
        var poly := PackedVector2Array()
        var bblo := Vector2(INF, INF)
        var bbhi := Vector2(-INF, -INF)
        for point: Vector2 in hull:
            var p := point * scale + shift
            poly.append(p)
            bblo = bblo.min(p)
            bbhi = bbhi.max(p)
        for y in range(maxi(0, floori(bblo.y)), mini(size, ceili(bbhi.y))):
            for x in range(maxi(0, floori(bblo.x)), mini(size, ceili(bbhi.x))):
                if Geometry2D.is_point_in_polygon(
                        Vector2(x + 0.5, y + 0.5), poly):
                    pixels[Vector2i(x, y)] = true
    return pixels
