#!/usr/bin/env python3
"""Produce matched-camera, articulated orthographic renders for photo comparisons.

This renderer transforms each part about its own pivot and follows its parent
hierarchy. Each photo gets its own camera yaw, elevation, zoom and limb angles.
The input views must be *measured* from the photo; defaults are never claimed
to be calibrated. Exports one PNG per view and a JSON provenance manifest.

Usage:
 python tools/render_miniature_pose_views.py recipe.json views.json --output-dir renders

views.json:
 {"views":[{"name":"front","photo":"https://...","yaw":0,"pitch":8,
            "roll":0,"zoom":6,"joints_deg":{"ll":-12,"ll_shin":24,
            "rl":10,"rl_shin":-17,"la":-8,"ra":12}}]}
"""
import argparse
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy.spatial.transform import Rotation

from render_miniature_recipe import raster, FACES


def transform_point(point, part_name, by_name, angle_by_part):
    p = np.asarray(point, dtype=float)
    chain = []
    while part_name:
        part = by_name[part_name]
        chain.append(part)
        part_name = part.get("parent", "")
    for part in chain:
        angle = float(angle_by_part.get(part["name"], 0))
        if angle:
            pivot = np.asarray(part.get("pivot", [0,0,0]), dtype=float)
            axis = "y" if part["name"] == "ct" else "x"
            p = pivot + Rotation.from_euler(axis, angle, degrees=True).apply(p-pivot)
    return p


def render_pose(recipe, view, size=720):
    # Rasterize separately to preserve moving-part ownership.
    by_name = {p["name"]: p for p in recipe["parts"]}
    # Expand mirrored parts from the source while retaining original parent.
    from render_miniature_recipe import shape_voxels
    material_colors = {m["name"]: tuple(int(m["color"][i:i+2],16) for i in (0,2,4))
                       for m in recipe["materials"]}
    part_cells = {}
    for part in recipe["parts"]:
        if "mirror" in part:
            src = part_cells[part["mirror"]]
            cells = {(-x-1,y,z):mat for (x,y,z),mat in src.items()}
        else:
            cells = {}
        for shape in part.get("shapes", []) + part.get("add", []):
            for coord in shape_voxels(shape):
                if "erase" in shape:
                    cells.pop(coord,None)
                else:
                    cells[coord] = shape.get("mat","armor")
        part_cells[part["name"]] = cells

    yaw = math.radians(view["yaw"])
    pitch = math.radians(view["pitch"])
    roll = math.radians(view.get("roll",0))
    right = np.array([math.cos(yaw),0,-math.sin(yaw)])
    up = np.array([-math.sin(yaw)*math.sin(pitch),math.cos(pitch),-math.cos(yaw)*math.sin(pitch)])
    forward = np.cross(up,right)
    screen_rotation = np.array([[math.cos(roll),-math.sin(roll)],
                                [math.sin(roll),math.cos(roll)]])
    transformed = {}
    for name,cells in part_cells.items():
        for cell,mat in cells.items():
            # Keep part ownership for articulated surfaces.
            transformed[(name,cell)] = (transform_point(np.array(cell)+.5,name,by_name,
                                                         view.get("joints_deg",{})),mat)
    positions = np.array([item[0] for item in transformed.values()])
    center = np.array(view.get("target", positions.mean(axis=0)),dtype=float)
    zoom = float(view.get("zoom",size/65))
    def proj(p):
        q = np.array([(p-center)@right,(p-center)@up])@screen_rotation
        return (size/2+q[0]*zoom,size/2-q[1]*zoom)
    image = Image.new("RGB",(size,size),(239,241,244))
    draw = ImageDraw.Draw(image)
    polygons=[]
    # Cube corners are articulated, so faces follow the part rotation.
    for (name,cell),(point,mat) in transformed.items():
        p=np.asarray(cell,dtype=float)
        own=part_cells[name]
        for normal,corners in FACES:
            neighbor=tuple((p+np.asarray(normal)).astype(int))
            if neighbor in own:
                continue
            quad=[transform_point(p+np.asarray(corner),name,by_name,
                                  view.get("joints_deg",{})) for corner in corners]
            normal_world=np.cross(quad[1]-quad[0],quad[2]-quad[0])
            if normal_world@forward<=0:
                continue
            color=material_colors.get(mat,(135,150,155))
            intensity=.68+.32*max(0,float(normal_world@np.array([-.3,.8,.5]))/
                                    max(1e-8,np.linalg.norm(normal_world)))
            color=tuple(int(v*intensity) for v in color)
            polygons.append((float(point@forward),[proj(q) for q in quad],color))
    for _,poly,color in sorted(polygons,key=lambda x:x[0]):
        draw.polygon(poly,fill=color)
    return image


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("recipe",type=Path)
    parser.add_argument("views",type=Path)
    parser.add_argument("--output-dir",type=Path,required=True)
    parser.add_argument("--size",type=int,default=720)
    args=parser.parse_args()
    recipe=json.loads(args.recipe.read_text())
    views=json.loads(args.views.read_text())["views"]
    args.output_dir.mkdir(parents=True,exist_ok=True)
    manifest=[]
    for v in views:
        output=args.output_dir/(v["name"]+".png")
        render_pose(recipe,v,args.size).save(output)
        manifest.append({"output":str(output),"photo":v.get("photo"),
                         "camera":{k:v[k] for k in ("yaw","pitch","roll","zoom") if k in v},
                         "joints_deg":v.get("joints_deg",{}),
                         "calibrated":bool(v.get("calibrated",False))})
    (args.output_dir/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")


if __name__=="__main__":
    main()
