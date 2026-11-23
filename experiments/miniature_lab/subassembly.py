"""Material-preserving miniature subassembly cuts with oriented support checks.

Plane cuts are authored in world-space. A claimed cell moves from one owner
to another, keeping material and physical volume unchanged. This tool never
repairs or adds voxel geometry.
"""
import math

DIRECTIONS = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0),
              (0, 0, 1), (0, 0, -1))


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def normalize(a):
    length = math.sqrt(dot(a, a))
    if length < 1e-8:
        raise ValueError("zero-length plane or joint normal")
    return tuple(x / length for x in a)


def has_point(part, center):
    """Every inclined splitting plane must contain this world-space point."""
    for plane in part["partition"]["planes"]:
        normal = normalize(plane["normal"])
        relative = tuple(center[i] - plane["origin"][i] for i in range(3))
        if dot(normal, relative) < -1e-8:
            return False
    return True


def claim(parts, item, pitch):
    parent_name = item["claim_from"]
    if parent_name not in parts:
        raise ValueError("missing partition source: " + parent_name)
    source = parts[parent_name]
    claimed = {}
    for cell, mat in list(source.items()):
        center = tuple((axis + .5) * pitch for axis in cell)
        if has_point(item, center):
            claimed[cell] = mat
            del source[cell]
    if not claimed or not source:
        raise ValueError("partition empty or consumed parent: " + item["name"])
    return claimed


def contact_faces(child, parent):
    faces = {}
    for c in child:
        for d in DIRECTIONS:
            if tuple(c[i] + d[i] for i in range(3)) in parent:
                faces[d] = faces.get(d, 0) + 1
    return faces


def normal_report(child, parent):
    faces = contact_faces(child, parent)
    if not faces:
        return {"area": 0, "normal": (0, 0, 0)}
    summed = tuple(sum(d[i] * n for d, n in faces.items())
                   for i in range(3))
    return {"area": sum(faces.values()), "normal": normalize(summed),
            "faces": {str(d): count for d, count in faces.items()}}


def check_direction(item, child, parent):
    if "attach_normal" not in item:
        return []
    found = normal_report(child, parent)
    if found["area"] == 0:
        return [item["name"] + ": no parent contact faces"]
    wanted = normalize(item["attach_normal"])
    angle = math.degrees(math.acos(max(-1, min(1,
                         dot(wanted, found["normal"])))))
    tolerance = item.get("angle_tolerance_deg", 30)
    if angle > tolerance:
        return ["%s: connection normal deviates %.1f degrees (>%.1f)" %
                (item["name"], angle, tolerance)]
    return []
