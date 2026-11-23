#!/usr/bin/env python3
"""Standalone experimental miniature assembly compiler and view analyzer.

Reads ONLY experimental spec files; generated files never overwrite shipped
data/voxels/ models. Python standard library only.
"""
import argparse
import json
import math
from pathlib import Path

DIRECTIONS = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0),
              (0, 0, 1), (0, 0, -1))


def inside(poly, px, py):
    """Even-odd point-in-polygon test for a cross-section."""
    hit = False
    j = len(poly) - 1
    for i, (x, y) in enumerate(poly):
        a, b = poly[j]
        if (y > py) != (b > py) and px < (a - x) * (py - y) / (b - y) + x:
            hit = not hit
        j = i
    return hit


def section_point(axis, xyz):
    x, y, z = xyz
    return {"x": (x, y, z), "y": (y, x, z), "z": (z, x, y)}[axis]


def field_contains(shape, xyz):
    at, u, v = section_point(shape["axis"], xyz)
    for a, b in zip(shape["sections"], shape["sections"][1:]):
        if a["at"] <= at <= b["at"]:
            t = (at - a["at"]) / (b["at"] - a["at"])
            if len(a["polygon"]) != len(b["polygon"]):
                raise ValueError("loft sections must have matching vertices")
            poly = [(p[0] + (q[0] - p[0]) * t,
                     p[1] + (q[1] - p[1]) * t)
                    for p, q in zip(a["polygon"], b["polygon"])]
            return inside(poly, u, v)
    return False


def shape_bounds(shape):
    axes = {"x": (0, 1, 2), "y": (1, 0, 2), "z": (2, 0, 1)}
    ai, ui, vi = axes[shape["axis"]]
    values = [[], [], []]
    for sec in shape["sections"]:
        values[ai].append(sec["at"])
        for u, v in sec["polygon"]:
            values[ui].append(u)
            values[vi].append(v)
    return [(min(dim), max(dim)) for dim in values]


def rasterize(spec):
    pitch = spec["pitch"]
    all_parts = {}
    for part in spec["parts"]:
        cells = {}
        for shape in part["shapes"]:
            sections = shape["sections"]
            if len(sections) < 2 or shape["axis"] not in ("x", "y", "z"):
                raise ValueError("need 2+ loft sections and a valid axis")
            ats = [s["at"] for s in sections]
            if any(b <= a for a, b in zip(ats, ats[1:])):
                raise ValueError("loft section positions must increase")
            bounds = shape_bounds(shape)
            for x in range(math.floor(bounds[0][0] / pitch),
                           math.ceil(bounds[0][1] / pitch)):
                for y in range(math.floor(bounds[1][0] / pitch),
                               math.ceil(bounds[1][1] / pitch)):
                    for z in range(math.floor(bounds[2][0] / pitch),
                                   math.ceil(bounds[2][1] / pitch)):
                        c = (x, y, z)
                        world = tuple((q + .5) * pitch for q in c)
                        if field_contains(shape, world):
                            if shape.get("op") == "subtract":
                                cells.pop(c, None)
                            else:
                                cells[c] = shape["mat"]
        if not cells:
            raise ValueError("empty component: " + part["name"])
        if part["name"] in all_parts:
            raise ValueError("duplicate component: " + part["name"])
        all_parts[part["name"]] = cells
    return all_parts


def components(cells):
    pending = set(cells)
    n = 0
    while pending:
        n += 1
        stack = [pending.pop()]
        while stack:
            c = stack.pop()
            for d in DIRECTIONS:
                q = tuple(c[i] + d[i] for i in range(3))
                if q in pending:
                    pending.remove(q)
                    stack.append(q)
    return n


def strong_contact(child, parent):
    """Require a contiguous 2x2 contact patch with mass behind BOTH faces."""
    for c in child:
        for d in DIRECTIONS:
            axes = [k for k in range(3) if d[k] == 0]
            for a in (-1, 1):
                for b in (-1, 1):
                    block = []
                    for u, v in ((0, 0), (a, 0), (0, b), (a, b)):
                        q = list(c)
                        q[axes[0]] += u
                        q[axes[1]] += v
                        block.append(tuple(q))
                    if all(q in child and
                           tuple(q[i] - d[i] for i in range(3)) in child and
                           tuple(q[i] + d[i] for i in range(3)) in parent and
                           tuple(q[i] + 2 * d[i] for i in range(3)) in parent
                           for q in block):
                        return True
    return False


def audit(spec, parts):
    """Reject flawed geometry; NEVER auto-fill seams or invent supports."""
    errors = []
    owned = {}
    for part in spec["parts"]:
        name = part["name"]
        cells = parts[name]
        if components(cells) != 1:
            errors.append(name + ": disconnected interior")
        for c in cells:
            if c in owned:
                errors.append("overlap: %s / %s at %s" % (name, owned[c], c))
            owned[c] = name
    for part in spec["parts"]:
        name = part["name"]
        parent_name = part.get("parent", "")
        if not parent_name:
            continue
        if parent_name not in parts:
            errors.append("%s: missing parent %s" % (name, parent_name))
            continue
        parent = parts[parent_name]
        if not strong_contact(parts[name], parent):
            errors.append("%s: no backed 2x2 face contact to %s" %
                          (name, parent_name))
    return errors


def encode_boxes(cells):
    """Compress x-runs without merging armor/structure roles."""
    rows = {}
    for (x, y, z), mat in cells.items():
        rows.setdefault((y, z, mat), []).append(x)
    boxes = []
    for (y, z, mat), xs in sorted(rows.items()):
        xs.sort()
        start = end = xs[0]
        for x in xs[1:] + [None]:
            if x is not None and x == end + 1:
                end = x
            else:
                boxes.append({"box": [[start, y, z], [end, y, z]], "mat": mat})
                if x is not None:
                    start = end = x
    return boxes


def export(spec, parts):
    pitch = spec["pitch"]
    out = {"id": spec["id"] + "_experiment",
           "name": spec["name"] + " (experimental)",
           "unit": spec["unit"], "voxel_size": pitch, "subdivide": 1,
           "exclusive_parts": False, "legs": spec["legs"],
           "punch": spec.get("punch", False),
           "materials": spec["materials"], "parts": [], "muzzles": {}}
    for p in spec["parts"]:
        obj = {key: p[key] for key in ("name", "loc", "parent", "joint")
               if key in p}
        obj["pivot"] = [round(v / pitch, 4)
                        for v in p.get("pivot", [0, 0, 0])]
        obj["shapes"] = encode_boxes(parts[p["name"]])
        out["parts"].append(obj)
    # Preserve the exact bore-to-muzzle relationship through quantization.
    for loc, points in spec.get("muzzles", {}).items():
        out["muzzles"][loc] = [[round(v / pitch, 4) for v in point]
                               for point in points]
    return out


def project(p, yaw=0, elevation=0):
    """Yaw 0 views from -z; vertical image coordinate is y."""
    x, y, z = p
    a, b = math.radians(yaw), math.radians(elevation)
    sideways = math.cos(a) * x + math.sin(a) * z
    depth = -math.sin(a) * x + math.cos(a) * z
    return sideways, math.cos(b) * y + math.sin(b) * depth


def silhouette(parts, yaw=0, elevation=0, size=100, framing=None):
    cells = set().union(*(set(part) for part in parts.values()))
    points = [project(tuple(q + .5 for q in c), yaw, elevation)
              for c in cells]
    if framing is None:
        min_x, max_x = min(x for x, _ in points) - 1, max(x for x, _ in points) + 1
        min_y, max_y = min(y for _, y in points) - 1, max(y for _, y in points) + 1
        span = max(max_x - min_x, max_y - min_y)
        framing = ((min_x + max_x) / 2, (min_y + max_y) / 2, span)
    cx, cy, span = framing
    mask = set()
    radius = max(1, math.ceil(size / span * .58))
    for x, y in points:
        px = round((x - cx) / span * size + size / 2)
        py = round(size / 2 - (y - cy) / span * size)
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                if 0 <= px + dx < size and 0 <= py + dy < size:
                    mask.add((px + dx, py + dy))
    return mask, framing


def polygon_mask(polygon, size=100):
    """Manual reference silhouettes: points normalized to [0,1] image crop."""
    return {(x, y) for x in range(size) for y in range(size)
            if inside(polygon, (x + .5) / size, (y + .5) / size)}


def compare(spec, parts, annotations, size=100):
    """Fit per-photo camera yaw/elevation, never silently reshape the model."""
    results = []
    for view in annotations.get("views", []):
        if not view.get("outline"):
            results.append({"view": view.get("name", ""),
                            "status": "unscored: no outline"})
            continue
        truth = polygon_mask(view["outline"], size)
        best = None
        for yaw in view.get("yaw_candidates", [0]):
            for elev in view.get("elevation_candidates", [0]):
                found, framing = silhouette(parts, yaw, elev, size)
                union = len(found | truth)
                iou = len(found & truth) / union if union else 0
                if best is None or iou > best["iou"]:
                    best = {"view": view.get("name", ""),
                            "yaw": yaw, "elevation": elev,
                            "iou": round(iou, 4), "framing": framing}
        component_scores = {}
        for name, polygon in view.get("parts", {}).items():
            if name not in parts:
                raise ValueError("unknown reference component: " + name)
            predicted, _ = silhouette({name: parts[name]}, best["yaw"],
                                      best["elevation"], size, best["framing"])
            target = polygon_mask(polygon, size)
            component_scores[name] = round(
                len(predicted & target) / len(predicted | target), 4)
        best["components"] = component_scores
        results.append(best)
    return {"chassis": spec["id"], "views": results,
            "note": "Camera fitted only; pose and perspective not fitted"}


def svg_views(spec, parts, destination):
    size, gap = 180, 22
    views = [("FRONT", 0, 0), ("SIDE", 90, 0),
             ("REAR", 180, 0), ("TOP", 0, 85)]
    blocks = []
    for idx, (label, yaw, elev) in enumerate(views):
        mask, _ = silhouette(parts, yaw, elev, size=size)
        x0 = 12 + idx * (size + gap)
        blocks.append('<text x="%d" y="24" text-anchor="middle" '
                      'fill="#e2e8f0" font-size="14">%s</text>' %
                      (x0 + size / 2, label))
        blocks.append('<rect x="%d" y="36" width="%d" height="%d" '
                      'rx="8" fill="#18202a"/>' % (x0, size, size))
        for row in range(size):
            xs = sorted(x for x, y in mask if y == row)
            if not xs:
                continue
            start = end = xs[0]
            for x in xs[1:] + [None]:
                if x is not None and x == end + 1:
                    end = x
                else:
                    blocks.append('<rect x="%d" y="%d" width="%d" '
                                  'height="1" fill="#aab9c7"/>' %
                                  (x0 + start, row + 36, end - start + 1))
                    if x is not None:
                        start = end = x
    width = 12 + len(views) * (size + gap)
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" '
           'width="%d" height="234" viewBox="0 0 %d 234">'
           '<rect width="100%%" height="100%%" fill="#0c1118"/>' %
           (width, width)) + "".join(blocks) + "</svg>"
    Path(destination).write_text(svg, encoding="utf-8")


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("source", type=Path)
    cli.add_argument("--output", type=Path, required=True)
    cli.add_argument("--svg", type=Path)
    cli.add_argument("--annotations", type=Path)
    cli.add_argument("--report", type=Path)
    args = cli.parse_args()
    repo_root = Path(__file__).resolve().parents[2]
    output = args.output.resolve()
    lab_dir = (repo_root / "experiments" / "miniature_lab").resolve()
    if output.is_relative_to(repo_root) and not output.is_relative_to(lab_dir):
        raise SystemExit("Refusing to write any shipped model or other production file")
    spec = json.loads(args.source.read_text(encoding="utf-8"))
    parts = rasterize(spec)
    faults = audit(spec, parts)
    if faults:
        raise SystemExit("Geometry audit failed:\n" + "\n".join(faults[:30]))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(export(spec, parts), indent=2) + "\n",
                           encoding="utf-8")
    if args.annotations:
        result = compare(spec, parts,
                         json.loads(args.annotations.read_text(encoding="utf-8")))
        print(json.dumps(result, indent=2))
        if args.report:
            args.report.write_text(json.dumps(result, indent=2) + "\n",
                                   encoding="utf-8")
    if args.svg:
        args.svg.parent.mkdir(parents=True, exist_ok=True)
        svg_views(spec, parts, args.svg)
    print("%s: %d parts, %d voxels, zero audited defects" %
          (spec["id"], len(parts), sum(map(len, parts.values())))


if __name__ == "__main__":
    main()
