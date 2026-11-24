#!/usr/bin/env python3
"""Five synchronized views of two actual voxel recipes, never AI artwork."""
import argparse
import json
import math
from pathlib import Path

from miniature_lab import rasterize

HERE = Path(__file__).resolve().parent
ANGLES = (("FRONT",0,0),("FRONT 3/4",35,16),("RIGHT SIDE",90,3),
          ("REAR",180,5),("ELEVATED",35,70))
COLORS = {"CT":"#a5b4bd","HD":"#d5dbd9","LT":"#a5bbc7",
          "RT":"#a5bbc7","LA":"#8396a5","RA":"#8396a5",
          "LL":"#b4bfc5","RL":"#b4bfc5","glass":"#52a6c6",
          "structure":"#657883"}
W,H,CW,CH = 177,218,205,258


def positions(spec):
    by = {p["name"]:p for p in spec["parts"]}
    out=[]
    for part,cells in rasterize(spec).items():
        loc=by[part]["loc"]
        for (x,y,z),mat in cells.items():
            out.append(((x+.5)*spec["pitch"],(y+.5)*spec["pitch"],
                        (z+.5)*spec["pitch"],
                        mat if mat in ("glass","structure") else loc))
    return out


def project(point,yaw,elevation):
    x,y,z,_=point
    a,b=math.radians(yaw),math.radians(elevation)
    u=math.cos(a)*x+math.sin(a)*z
    dep=-math.sin(a)*x+math.cos(a)*z
    return (u,math.cos(b)*y+math.sin(b)*dep,
            math.cos(b)*dep-math.sin(b)*y)


def frame_pair(a,b,label,angle):
    yaw,el=angle
    pairs=[[(*project(v,yaw,el),v[3]) for v in points] for points in (a,b)]
    flat=[p for group in pairs for p in group]
    minx,maxx=min(p[0] for p in flat),max(p[0] for p in flat)
    miny,maxy=min(p[1] for p in flat),max(p[1] for p in flat)
    cx,cy=(minx+maxx)/2,(miny+maxy)/2
    scale=min((W-16)/(maxx-minx+.22),(H-12)/(maxy-miny+.22))
    views=[]
    for row,group in enumerate(pairs):
        depth=[float("inf")]*(W*H)
        pixels=[None]*(W*H)
        radius=max(1,round(scale*.04*.52))
        for u,v,d,mat in group:
            px=round(W/2+(u-cx)*scale)
            py=round(H/2-(v-cy)*scale)
            for y in range(max(0,py-radius),min(H,py+radius+1)):
                for x in range(max(0,px-radius),min(W,px+radius+1)):
                    i=y*W+x
                    if d<depth[i]:
                        depth[i]=d
                        pixels[i]=COLORS[mat]
        paths={}
        for y in range(H):
            x=0
            while x<W:
                color=pixels[y*W+x]
                start=x
                while x<W and pixels[y*W+x]==color:
                    x+=1
                if color:
                    paths[color]=paths.get(color,"")+(
                        f"M{start} {y}h{x-start}v1h-{x-start}z")
        ox,oy=20+label*CW,36+row*CH
        geometry="".join(f'<path fill="{color}" d="{data}"/>'
                         for color,data in paths.items())
        views.append(
            f'<g transform="translate({ox} {oy})">'
            f'<rect width="{W}" height="{H}" rx="5" '
            f'fill="#121c28" stroke="#304455"/>'
            f'{geometry}</g><text x="{ox}" y="{oy-9}" '
            f'fill="#e0ebf4" font-family="sans-serif" '
            f'font-size="12">{["BASELINE","TRIAL"][row]} '
            f'· {ANGLES[label][0]}</text>')
    return "".join(views)


def render(baseline,candidate):
    left,right=positions(baseline),positions(candidate)
    panels="".join(frame_pair(left,right,i,angle[1:])
                   for i,angle in enumerate(ANGLES))
    width,height=1043,578
    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{width}" height="{height}" '
            f'viewBox="0 0 {width} {height}">'
            f'<desc>Two actual source-voxel geometry recipes under exactly '
            f'matched orthographic camera angles, neutral rig pose. '
            f'This is NOT photographic registration or a Godot screenshot.'
            f'</desc><rect width="100%" height="100%" fill="#0b1420"/>'
            f'<text x="16" y="21" fill="#edf4fa" font-size="16" '
            f'font-family="sans-serif" font-weight="700">'
            f'Jenner voxel geometry · common cameras</text>{panels}'
            f'<text x="16" y="{height-13}" fill="#9bb0c3" '
            f'font-size="11">Experimental comparison only; production '
            f'art unchanged</text></svg>')


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--baseline",type=Path,
                        default=HERE/"jenner_assembly_v12.json")
    parser.add_argument("--trial",type=Path,
                        default=HERE/"jenner_assembly_v14_trial.json")
    parser.add_argument("--out",type=Path,
                        default=HERE/"generated/jenner_v14_from_python.svg")
    args=parser.parse_args()
    if not args.out.resolve().is_relative_to(HERE):
        raise SystemExit("Do not write outside the experiment")
    output=render(json.loads(args.baseline.read_text()),
                  json.loads(args.trial.read_text()))
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(output)
    print(args.out)


if __name__=="__main__":
    main()
