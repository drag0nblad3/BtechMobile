#!/usr/bin/env python3
"""Anonymous, multi-view voxel-ID gallery and catalog confusion audit.

No names or references appear on image cards. The separate key is sealed off
from the gallery. Similarity measures confusion risk, NOT a human ID success
rate. Development-side only: pip install numpy pillow.
"""
import argparse
import json
import math
import random
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SIZE = 80
VIEWS = ("front", "side", "top", "quarter")
WEIGHTS = (.47, .23, .20, .10)
SEED = 20261122


def loft_cells(cells, op):
    loft = op["loft"]
    axis = loft.get("axis", "y")
    stations = loft["sections"]
    for section in range(len(stations) - 1):
        a, b = stations[section:section+2]
        lo, hi = int(a["at"]), int(b["at"])
        if hi <= lo:
            continue
        for station in range(lo, hi + (section == len(stations) - 2)):
            alpha = min(1, max(0, (station + .5 - lo) / float(hi - lo)))
            poly = np.asarray(a["polygon"]) * (1 - alpha) + np.asarray(b["polygon"]) * alpha
            x0, x1 = math.floor(min(poly[:, 0])), math.ceil(max(poly[:, 0]))
            y0, y1 = math.floor(min(poly[:, 1])), math.ceil(max(poly[:, 1]))
            if x1 <= x0 or y1 <= y0:
                continue
            im = Image.new("1", (x1 - x0 + 2, y1 - y0 + 2))
            draw = ImageDraw.Draw(im)
            draw.polygon([(float(v[0]) - x0, float(v[1]) - y0) for v in poly], fill=1)
            for j in range(y1 - y0 + 1):
                for i in range(x1 - x0 + 1):
                    if not im.getpixel((i, j)):
                        continue
                    pos = (x0 + i, station, y0 + j) if axis == "y" else (
                        x0 + i, y0 + j, station)
                    cells.add(pos)


def paint(cells, shapes):
    for op in shapes:
        if "loft" in op:
            loft_cells(cells, op)
            continue
        kind = next((k for k in ("erase", "box", "shell") if k in op), None)
        if not kind:
            continue
        lo, hi = op[kind]
        for x in range(int(lo[0]), int(hi[0]) + 1):
            for y in range(int(lo[1]), int(hi[1]) + 1):
                for z in range(int(lo[2]), int(hi[2]) + 1):
                    if kind == "erase":
                        cells.discard((x, y, z))
                    else:
                        cells.add((x, y, z))


def model_points(path):
    recipe = json.loads(path.read_text())
    parts = {}
    for part in recipe["parts"]:
        if part.get("mirror"):
            cells = {(-x - 1, y, z) for x, y, z in parts[part["mirror"]]}
        else:
            cells = set()
            paint(cells, part.get("shapes", []))
        paint(cells, part.get("add", []))
        parts[part["name"]] = cells
    occupied = set().union(*parts.values()) if parts else set()
    if not occupied:
        raise ValueError("empty model: " + str(path))
    return np.asarray(list(occupied), dtype=np.float32) + .5


def projection(points, view):
    x, y, z = points.T
    if view == "front":
        u, v = x, y
    elif view == "side":
        u, v = z, y
    elif view == "top":
        u, v = x, z
    elif view == "quarter":
        u, v = .77*x - .64*z, .95*y + .18*x + .19*z
    else:
        raise ValueError(view)
    u, v = np.asarray(u), np.asarray(v)
    scale = (SIZE - 12) / max(float(np.ptp(u)), float(np.ptp(v)), 1.)
    xx = np.clip(np.rint((u - (u.min()+u.max())*.5)*scale + SIZE*.5), 0, SIZE-1).astype(int)
    yy = np.clip(np.rint((v - (v.min()+v.max())*.5)*scale + SIZE*.5), 0, SIZE-1).astype(int)
    im = Image.new("L", (SIZE, SIZE))
    ImageDraw.Draw(im).point(list(zip(xx.tolist(), yy.tolist())), fill=255)
    im = im.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1.25))
    feature = np.asarray(im, dtype=np.float32).ravel() / 255.
    feature /= max(1e-8, float(np.linalg.norm(feature)))
    return feature, im


def run(root, out):
    out.mkdir(parents=True, exist_ok=True)
    paths = sorted(root.glob("*_shape.json"))
    names, vectors, pictures = [], [], []
    for path in paths:
        pts = model_points(path)
        vec, views = [], {}
        for view in VIEWS:
            v, img = projection(pts, view)
            vec.append(v)
            views[view] = img
        names.append(path.stem[:-6])
        vectors.append(np.stack(vec))
        pictures.append(views)
    features = np.stack(vectors)
    sim = np.einsum("nvp,mvp->nmv", features, features)
    scores = np.tensordot(sim, np.asarray(WEIGHTS), axes=([2], [0]))
    np.fill_diagonal(scores, -1)
    closest = np.argsort(-scores, axis=1)
    models = []
    for i, name in enumerate(names):
        neighbors = [
            {"name": names[j], "similarity": round(float(scores[i,j]), 4),
             "front": round(float(sim[i,j,0]), 3),
             "side": round(float(sim[i,j,1]), 3),
             "top": round(float(sim[i,j,2]), 3)}
            for j in closest[i,:5]
        ]
        top = neighbors[0]["similarity"]
        risk = "critical" if top >= .94 else "high" if top >= .90 else (
               "review" if top >= .83 else "lower")
        models.append({"model": name, "risk": risk, "closest": neighbors,
                       "top_similarity": top})
    pairs = sorted(
        [{"a": names[i], "b": names[j],
          "similarity": round(float(scores[i,j]), 4)}
         for i in range(len(names)) for j in range(i+1, len(names))],
        key=lambda row: -row["similarity"])
    report = {
        "model_count": len(names),
        "views": list(VIEWS),
        "weights": list(WEIGHTS),
        "method": "Scale-normalized 4-view silhouette cosine similarity. These are candidates for blind human review, not demonstrated misidentification.",
        "critical_models": sum(x["risk"] == "critical" for x in models),
        "high_models": sum(x["risk"] == "high" for x in models),
        "top_pairs": pairs[:100],
        "models": models}
    (out / "blind_confusion_report.json").write_text(json.dumps(report, indent=2) + "\n")
    indices = list(range(len(names)))
    random.Random(SEED).shuffle(indices)
    cols, count, tile_w, tile_h = 4, 24, 280, 174
    for page in range(math.ceil(len(names)/count)):
        selection = indices[page*count:(page+1)*count]
        canvas = Image.new("RGB", (cols*tile_w,
            math.ceil(len(selection)/cols)*tile_h), (18,23,30))
        draw = ImageDraw.Draw(canvas)
        for k, i in enumerate(selection):
            x, y = (k%cols)*tile_w, (k//cols)*tile_h
            draw.text((x+12,y+7), "BLIND %03d" % (page*count+k+1),
                      fill=(235,235,238))
            for v, view in enumerate(("front","side","quarter")):
                img = Image.new("RGB",(SIZE,SIZE),(30,38,44))
                img.paste((157,174,163), mask=pictures[i][view])
                canvas.paste(img, (x+5+90*v,y+29))
            draw.text((x+7,y+116),"Front        Side       3/4",
                      fill=(145,151,156))
            draw.text((x+7,y+137),"Guess: _____________",
                      fill=(185,187,192))
            draw.line([(x+5,y+tile_h-2),(x+tile_w-5,y+tile_h-2)],
                      fill=(60,65,70))
        canvas.save(out/("blind_page_%02d.png" % (page+1)),optimize=True)
    (out/"blind_key.json").write_text(json.dumps({
        "BLIND %03d"%(k+1):names[i] for k,i in enumerate(indices)
    },indent=2)+"\n")
    print("BLIND_IDENTITY|models=%d|critical=%d|high=%d|pages=%d" % (
        len(names),report["critical_models"],report["high_models"],
        math.ceil(len(names)/count)))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root",type=Path,default=Path("data/voxels"))
    parser.add_argument("--out",type=Path,default=Path("/tmp/vx-blind-identity"))
    args=parser.parse_args()
    run(args.root,args.out)
