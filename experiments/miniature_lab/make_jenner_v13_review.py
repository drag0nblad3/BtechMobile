"""Experimental v13 Jenner torso/leg *anatomy review*, not accepted art.

No production JSON access. This trial changes the lower CT taper, adds loft
control sections to legs, and re-profiles toe tips. It does not move rig
pivots, change the stance, or assert improved reference fidelity.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def rounded(n):
    return round(n, 5)


def bevel(poly, fraction=.105):
    result = []
    for i, p in enumerate(poly):
        a, b = poly[(i-1) % len(poly)], poly[(i+1) % len(poly)]
        result.extend([
            [rounded(p[k]*(1-fraction)+a[k]*fraction) for k in (0, 1)],
            [rounded(p[k]*(1-fraction)+b[k]*fraction) for k in (0, 1)],
        ])
    return result


def intermediate_sections(sections, shin=False):
    if len(sections)!=3 or len(sections[0]["polygon"])!=8:
        raise ValueError("expected Jenner 3-section, 8-point leg hull")
    detail=[]
    for i, sec in enumerate(sections):
        detail.append(sec)
        if i+1==len(sections):
            break
        nxt=sections[i+1]
        poly=[]
        for k,p in enumerate(sec["polygon"]):
            midpoint=[]
            for j,v in enumerate(p):
                m=(v+nxt["polygon"][k][j])/2
                if shin and i==0 and j==1:
                    m+=.012
                midpoint.append(rounded(m))
            poly.append(midpoint)
        detail.append({"at":rounded((sec["at"]+nxt["at"])/2),
                       "polygon":poly})
    return [{"at":s["at"],"polygon":bevel(s["polygon"])} for s in detail]


def build():
    spec=json.loads((HERE/"jenner_assembly_v12.json").read_text())
    part={p["name"]:p for p in spec["parts"]}
    # Lower torso is almost as wide as the chest at the hips in v12.
    # Keep physical CT/hip connection while removing slab-like underside.
    for i in range(3):
        sec=part["ct"]["shapes"][0]["sections"][i]
        weight=(1,.75,.35)[i]
        for point in sec["polygon"]:
            point[0]=rounded(point[0]*(1-.065*weight))
            point[1]=rounded(point[1]+(.045 if point[1]<0 else -.012)*weight)
    for side in ("l","r"):
        for name in (side+"l",side+"l_shin"):
            shape=part[name]["shapes"][0]
            shape["sections"]=intermediate_sections(
                shape["sections"], shin=name.endswith("shin"))
        # Conservative front toe shape adjustment; actual voxel silhouette
        # still needs to be checked after camera and leg pose calibration.
        for i in range(2):
            for point in part[side+"l_foot"]["shapes"][0]["sections"][i]["polygon"]:
                if point[1]<-.2:
                    point[1]=rounded(point[1]-.013*(1-i*.5))
    spec["shape_refinement_revision"]="miniature-v13-torso-leg-anatomy-review-20261123"
    spec["review_status"]=(
        "UNACCEPTED anatomy trial pending pose-fitted multi-photo comparison "
        "and engine render; do not promote v13 automatically")
    return spec


if __name__=="__main__":
    output=HERE/"jenner_assembly_v13_review.json"
    output.write_text(json.dumps(build(),indent=2)+"\n")
    print("Wrote",output)
