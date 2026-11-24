#!/usr/bin/env python3
"""Standalone orthographic renderer of actual BattleTech JSON loft/box geometry.

Requires numpy, matplotlib and Pillow. No Godot dependency.
Usage: python tools/render_miniature_recipe.py data/voxels/sagittaire.json --output sagittaire.png
Camera yaw is degrees around vertical; pitch is elevation above horizon.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from matplotlib.path import Path as PolygonPath
from PIL import Image, ImageDraw


def shape_voxels(shape):
    if "box" in shape or "shell" in shape or "erase" in shape:
        key = next(k for k in ("box", "shell", "erase") if k in shape)
        lo, hi = (np.asarray(v, dtype=int) for v in shape[key])
        for x in range(lo[0], hi[0] + 1):
            for y in range(lo[1], hi[1] + 1):
                for z in range(lo[2], hi[2] + 1):
                    yield (x, y, z)
        return
    loft = shape.get("loft")
    if not loft:
        return
    axis = loft["axis"]
    sections = loft["sections"]
    for a, b in zip(sections, sections[1:]):
        start, end = int(a["at"]), int(b["at"])
        if end < start or len(a["polygon"]) != len(b["polygon"]):
            continue
        for layer in range(start, end + 1):
            t = 0 if end == start else (layer - start) / (end - start)
            poly = np.asarray(a["polygon"], dtype=float) * (1-t) + np.asarray(b["polygon"], dtype=float) * t
            lo = np.floor(poly.min(axis=0)).astype(int)
            hi = np.ceil(poly.max(axis=0)).astype(int)
            grid = np.array([(u,v) for u in range(lo[0],hi[0]) for v in range(lo[1],hi[1])],dtype=int)
            if len(grid) == 0:
                continue
            mask = PolygonPath(poly).contains_points(grid + .5)
            for u,v in grid[mask]:
                yield (int(u),layer,int(v)) if axis == "y" else (int(u),int(v),layer)


def raster(recipe):
    materials = {m["name"]: tuple(int(m["color"][i:i+2],16) for i in (0,2,4))
                 for m in recipe.get("materials",[])}
    parts = {}
    for part in recipe["parts"]:
        name = part["name"]
        if "mirror" in part:
            source = parts[part["mirror"]]
            cells = {(-x-1,y,z):mat for (x,y,z),mat in source.items()}
        else:
            cells = {}
        for shape in part.get("shapes", []) + part.get("add", []):
            if "erase" in shape:
                for cell in shape_voxels(shape):
                    cells.pop(cell,None)
            else:
                mat = shape.get("mat","armor")
                for cell in shape_voxels(shape):
                    cells[cell] = mat
        parts[name] = cells
    merged = {}
    for cells in parts.values():
        merged.update(cells)
    return merged,materials


FACES = [
    ((1,0,0), [(1,0,0),(1,1,0),(1,1,1),(1,0,1)]),
    ((-1,0,0),[(0,0,1),(0,1,1),(0,1,0),(0,0,0)]),
    ((0,1,0), [(0,1,0),(0,1,1),(1,1,1),(1,1,0)]),
    ((0,-1,0),[(0,0,1),(0,0,0),(1,0,0),(1,0,1)]),
    ((0,0,1), [(1,0,1),(1,1,1),(0,1,1),(0,0,1)]),
    ((0,0,-1),[(0,0,0),(0,1,0),(1,1,0),(1,0,0)]),
]


def render(cells, materials, yaw, pitch, size=700):
    if not cells:
        raise ValueError("Empty recipe")
    xyz = np.array(list(cells),dtype=float)
    center = (xyz.min(axis=0)+xyz.max(axis=0))/2
    az = np.radians(yaw)
    el = np.radians(pitch)
    right = np.array([np.cos(az),0,-np.sin(az)])
    up = np.array([-np.sin(az)*np.sin(el),np.cos(el),-np.cos(az)*np.sin(el)])
    toward = np.cross(right,up)
    # Camera looks along the negative Z direction at yaw=0.
    toward = -toward
    projected = np.stack(((xyz-center)@right,(xyz-center)@up),axis=1)
    extent = max(np.ptp(projected,axis=0).max(),1)
    scale = size*.78/extent
    def screen(v):
        q = (v-center)@np.stack((right,up)).T
        return tuple((np.array([size/2,size/2])+q*np.array([scale,-scale])).tolist())
    img = Image.new("RGB",(size,size),(242,243,245))
    draw = ImageDraw.Draw(img)
    visible = []
    for pos,mat in cells.items():
        p = np.array(pos,dtype=float)
        for normal,corners in FACES:
            n = np.array(normal)
            if n@toward <= 0 or tuple(p+n.astype(int)) in cells:
                continue
            depth = (p-center)@toward
            base = materials.get(mat,(140,150,155))
            shade = .70 + .30*max(0,n@np.array([-.35,.7,-.6]))
            color = tuple(max(0,min(255,int(c*shade))) for c in base)
            visible.append((depth,[screen(p+corner) for corner in map(np.array,corners)],color))
    # Far surfaces first; deterministic orthographic painter.
    for _,quad,color in sorted(visible,key=lambda x:x[0]):
        draw.polygon(quad,fill=color)
    return img


def main():
    p=argparse.ArgumentParser()
    p.add_argument("recipe",type=Path)
    p.add_argument("--output",type=Path,default=Path("miniature_views.png"))
    p.add_argument("--size",type=int,default=640)
    p.add_argument("--yaw",type=float,nargs="*",default=[0,45,90,180])
    p.add_argument("--pitch",type=float,default=12)
    args=p.parse_args()
    cells,materials=raster(json.loads(args.recipe.read_text()))
    views=[render(cells,materials,y,args.pitch,args.size) for y in args.yaw]
    sheet=Image.new("RGB",(args.size*len(views),args.size),(245,245,245))
    for i,img in enumerate(views):
        sheet.paste(img,(i*args.size,0))
    sheet.save(args.output)
    print(f"{len(cells)} occupied cells; {len(views)} views; {args.output}")


if __name__=="__main__":
    main()
