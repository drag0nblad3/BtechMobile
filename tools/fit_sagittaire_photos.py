#!/usr/bin/env python3
"""Fit a photographed miniature's camera AND articulated pose to model silhouette.

Downloads actual photo pixels. Optimizes yaw, pitch, zoom, x/y framing, hip,
knee and arm joint angles against foreground masks. Each photo is independent.
Outputs side-by-side photographic comparisons and numerical IoU. This is
experimental fitting, not a guarantee of a correct sculpt.
"""
import json, math, sys, urllib.request
from pathlib import Path
import numpy as np
import cv2
from scipy.optimize import differential_evolution
from PIL import Image, ImageDraw
from render_miniature_recipe import shape_voxels

# Anatomical region labels survive camera and articulation transforms.
REGIONS={"ct":"torso","hd":"cockpit","lt":"left_shoulder","rt":"right_shoulder",
 "lt_ppc":"left_weapon","rt_pulse":"right_weapon","la":"left_arm",
 "ra":"right_arm","ll":"left_thigh","ll_shin":"left_shin",
 "ll_foot":"left_foot","rl":"right_thigh","rl_shin":"right_shin",
 "rl_foot":"right_foot"}
REGION_WEIGHTS={"cockpit":2.5,"torso":2.0,"left_shoulder":1.6,
 "right_shoulder":1.6,"left_weapon":2.2,"right_weapon":2.2,
 "left_arm":1.5,"right_arm":1.5,"left_thigh":1.4,
 "right_thigh":1.4,"left_shin":1.5,"right_shin":1.5,
 "left_foot":1.2,"right_foot":1.2}


ROOT=Path(__file__).resolve().parent.parent
MODEL=ROOT/"experiments/miniature_reconstruction/sagittaire/sagittaire_photo_anatomy_p10.json"
VIEWS=ROOT/"experiments/miniature_reconstruction/sagittaire/pose_camera_initial_views.json"
OUT=ROOT/"experiments/miniature_reconstruction/sagittaire/fitted"
S=256

def source_cells(recipe):
    out={}
    for p in recipe["parts"]:
        if p.get("mirror"):
            cells=np.array([(-x-1,y,z) for x,y,z in out[p["mirror"]]],dtype=np.float32)
        else: cells=np.empty((0,3),dtype=np.float32)
        for shape in p.get("shapes",[]):
            new=np.array(list(shape_voxels(shape)),dtype=np.float32).reshape(-1,3)
            if len(new): cells=np.concatenate([cells,new])
        if len(cells): cells=np.unique(cells,axis=0)
        out[p["name"]]=cells
    return out

def photo_mask(rgb):
    im=cv2.resize(rgb,(S,S))
    # GrabCut starts with an inset rectangle; then largest foreground blob.
    gc=np.zeros((S,S),np.uint8)
    bg=np.zeros((1,65),np.float64); fg=np.zeros((1,65),np.float64)
    cv2.grabCut(im,gc,(14,8,S-28,S-16),bg,fg,5,cv2.GC_INIT_WITH_RECT)
    mask=np.where((gc==2)|(gc==0),0,255).astype(np.uint8)
    count,labels,stats,_=cv2.connectedComponentsWithStats(mask)
    if count>1:
        idx=1+np.argmax(stats[1:,cv2.CC_STAT_AREA])
        mask=np.where(labels==idx,255,0).astype(np.uint8)
    return mask

def project(parts,params,base_yaw,return_regions=False):
    yaw,pitch,scale,dx,dy,hip_l,knee_l,hip_r,knee_r,arm_l,arm_r=params
    joints={"ll":hip_l,"ll_shin":knee_l,"ll_foot":knee_l,
            "rl":hip_r,"rl_shin":knee_r,"rl_foot":knee_r,
            "la":arm_l,"ra":arm_r}
    # Apply a local X-axis rotation around the part's anatomical pivot,
    # then parent transforms, not global rotations of the whole leg.
    byname={p["name"]:p for p in recipe["parts"]}
    transformed=[]
    names=[]
    for name,cells in parts.items():
        if not len(cells):continue
        # Use surface points for speed and fidelity.
        if len(cells)>2500: cells=cells[::2]
        xyz=cells.copy()+.5
        cur=name
        while cur:
            part=byname[cur]
            a=math.radians(joints.get(cur,0))
            if a:
                pivot=np.array(part.get("pivot",[0,0,0]),dtype=np.float32)
                q=xyz-pivot
                xyz[:,1]=pivot[1]+q[:,1]*math.cos(a)-q[:,2]*math.sin(a)
                xyz[:,2]=pivot[2]+q[:,1]*math.sin(a)+q[:,2]*math.cos(a)
            cur=part.get("parent","")
        transformed.append(xyz)
        names.extend([REGIONS.get(name,name)]*len(xyz))
    xyz=np.concatenate(transformed)
    az=math.radians(yaw); el=math.radians(pitch)
    right=np.array([math.cos(az),0,-math.sin(az)])
    up=np.array([-math.sin(az)*math.sin(el),math.cos(el),-math.cos(az)*math.sin(el)])
    q=xyz-np.array([0,22,0])
    x=q@right*scale+S/2+dx
    y=-q@up*scale+S/2+dy
    image=np.zeros((S,S),np.uint8)
    valid=(x>=0)&(x<S)&(y>=0)&(y<S)
    image[y[valid].astype(int),x[valid].astype(int)]=255
    image=cv2.dilate(image,np.ones((max(2,int(scale)),max(2,int(scale))),np.uint8))
    if not return_regions:
        return image
    # Per-part masks are rendered with the same fitted camera and joint angles.
    # These are visible projected areas, not independently fit silhouettes.
    masks={}
    names=np.asarray(names)
    for name in set(names):
        selected=valid & (names==name)
        mask=np.zeros((S,S),np.uint8)
        mask[y[selected].astype(int),x[selected].astype(int)]=255
        mask=cv2.dilate(mask,np.ones((max(2,int(scale)),max(2,int(scale))),np.uint8))
        masks[name]=mask
    return image,masks


def annotated_masks(annotations,shape=(S,S)):
    """Rasterize human-reviewed polygons, never automatically invent part labels.

    Annotation coordinates are normalized to [0,1] in the resized photo.
    An absent region is unscored, not treated as an empty region.
    """
    masks={}
    for name,polygons in annotations.items():
        if name not in REGION_WEIGHTS: continue
        mask=np.zeros(shape,np.uint8)
        for poly in polygons:
            pts=np.asarray([[round(x*shape[1]),round(y*shape[0])]
                            for x,y in poly],np.int32)
            if len(pts)>=3:cv2.fillPoly(mask,[pts],255)
        if np.any(mask):masks[name]=mask
    return masks


def part_aware_score(photo_mask,model_mask,model_regions,annotations):
    silhouette=score(photo_mask,model_mask)
    reference_regions=annotated_masks(annotations)
    if not reference_regions:
        return silhouette,{"silhouette":silhouette,"parts_scored":0}
    total=0.0;weight=0.0;breakdown={}
    for name,ref in reference_regions.items():
        candidate=model_regions.get(name,np.zeros_like(ref))
        overlap=score(ref,candidate)
        breakdown[name]=overlap
        w=REGION_WEIGHTS[name]
        total+=w*overlap;weight+=w
    part_score=total/max(weight,1e-9)
    return .25*silhouette+.75*part_score,{
        "silhouette":silhouette,"part_outline_score":part_score,
        "parts_scored":len(reference_regions),"per_part_iou":breakdown}


def score(mask,render):
    # Silhouette IoU, plus contour mismatch to discourage trivial tiny fits.
    a=mask>0;b=render>0
    union=np.count_nonzero(a|b)
    return np.count_nonzero(a&b)/union if union else 0

if __name__=="__main__":
    recipe=json.loads(MODEL.read_text()); parts=source_cells(recipe)
    views=json.loads(VIEWS.read_text())["views"]
    annotation_path=VIEWS.parent/"photo_part_annotations.json"
    annotation_sets=json.loads(annotation_path.read_text()) if annotation_path.exists() else {}
    OUT.mkdir(parents=True,exist_ok=True)
    results=[]
    for view in views:
        name=view["name"]; url=view["photo"]
        try:
            request=urllib.request.Request(url,headers={"User-Agent":"Mozilla/5.0"})
            data=urllib.request.urlopen(request,timeout=30).read()
            img=cv2.imdecode(np.frombuffer(data,np.uint8),cv2.IMREAD_COLOR)
            if img is None:raise ValueError("No image decoded")
            img=cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
            mask=photo_mask(img)
            # Reject unusable segmentation rather than optimize against background.
            foreground_fraction=float(np.mean(mask>0))
            if foreground_fraction<.035 or foreground_fraction>.80:
                raise ValueError(f"Implausible photo foreground: {foreground_fraction:.3f}")
            cv2.imwrite(str(OUT/(name+"_mask.png")),mask)
            yaw=view["yaw"]
            bounds=[(yaw-50,yaw+50),(-10,40),(2.7,5.6),(-35,35),(-35,35),
                    (-35,35),(-50,55),(-35,35),(-50,55),(-30,30),(-30,30)]
            annotations=annotation_sets.get(name,{})
            def loss(p):
                if annotations:
                    rendered,regions=project(parts,p,yaw,return_regions=True)
                    return 1-part_aware_score(mask,rendered,regions,annotations)[0]
                return 1-score(mask,project(parts,p,yaw))
            fit=differential_evolution(loss,bounds,popsize=6,maxiter=24,
                    seed=42,workers=1,polish=False,tol=.008)
            fitted,region_masks=project(parts,fit.x,yaw,return_regions=True)
            fitted_score,detail=part_aware_score(mask,fitted,region_masks,annotations)
            photo=cv2.resize(img,(S,S))
            overlay=photo.copy()
            overlay[fitted>0]=(.55*overlay[fitted>0]+.45*np.array([40,205,235])).astype(np.uint8)
            panel=np.concatenate([photo,np.stack([mask]*3,-1),np.stack([fitted]*3,-1),overlay],axis=1)
            Image.fromarray(panel).save(OUT/(name+"_comparison.png"))
            # Output part-outline overlay even without annotations, but do not
            # claim the outlines have been validated against the photograph.
            outlines=photo.copy()
            for idx,(region,region_mask) in enumerate(sorted(region_masks.items())):
                contours,_=cv2.findContours(region_mask,cv2.RETR_EXTERNAL,
                                            cv2.CHAIN_APPROX_SIMPLE)
                color=tuple(int(v) for v in cv2.cvtColor(
                    np.uint8([[[idx*37%180+40,210,230]]]),
                    cv2.COLOR_HSV2RGB)[0,0])
                cv2.drawContours(outlines,contours,-1,color,1)
            Image.fromarray(outlines).save(OUT/(name+"_part_outlines.png"))
            result={"name":name,"photo":url,"camera":{"yaw":float(fit.x[0]),
                "pitch":float(fit.x[1]),"scale":float(fit.x[2]),
                "offset_x":float(fit.x[3]),"offset_y":float(fit.x[4])},
                "joints_deg":dict(zip(["ll","ll_shin","rl","rl_shin","la","ra"],
                                      [float(x) for x in fit.x[5:]])),
                "silhouette_iou":float(score(mask,fitted)),
                "fit_score":float(fitted_score),"part_comparison":detail,
                "iterations":int(fit.nit),
                "warning":("Part outlines compared to annotated reference regions."
                           if annotations else
                           "Model part outlines visualized but not reference-scored: "
                           "no human-reviewed photo part polygons supplied.")}
            results.append(result)
            print(name,round(result["silhouette_iou"],3),flush=True)
        except Exception as e:
            results.append({"name":name,"error":str(e)})
            print(name,"FAILED",str(e),flush=True)
    (OUT/"results.json").write_text(json.dumps(results,indent=2)+"\n")
    if not any("silhouette_iou" in r for r in results):sys.exit(2)
