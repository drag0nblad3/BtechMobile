#!/usr/bin/env python3
"""Multi-source Jenner photo fitting; frozen camera/rig, conservative exclusions.

New photos are referenced by URL, never committed as image bytes. Hand-traced
points from 500px previews are NOT a calibrated reconstruction. A failed
camera or hidden knee means the whole photo is unscored.
"""
import argparse
import json
from pathlib import Path

import miniature_lab as geo
import photo_fit
import photo_registration as registration
import reference_fit

HERE=Path(__file__).resolve().parent
PAIRS={"front_left":"front_left_3quarter",
       "front_right":"front_right_3quarter",
       "rear_left":"rear_left_3quarter",
       "rear_right":"missing_reference_landmarks"}


def standard_registration(control, cells):
    outlines=json.loads((HERE/"jenner_photo_annotations.json").read_text())
    marks=json.loads((HERE/"jenner_photo_landmarks.json").read_text())
    frozen=registration.calibration(control,cells,outlines,marks,PAIRS)
    return outlines,frozen


def new_registration(control,cells,manifest):
    if manifest["sculpt"]!=control["sculpt"]:
        raise ValueError("different plastic-miniature sculpt")
    get_anchors=getattr(reference_fit,"anchors",None) or reference_fit.landmarks
    raw=get_anchors(control,cells)
    anchors={k:tuple(x*control["pitch"] for x in p) for k,p in raw.items()}
    result=[]
    for photo in manifest["new_photos"]:
        obs=registration.crop_observations(
            {"landmarks_px":{**photo["rigid_px"],**photo.get("pose_px",{})}},
            photo)
        camera=registration.fit_camera(anchors,obs,photo)
        row={"view":photo["name"],"source":photo["image_url"],
             "status":"unscored","region":photo["region"],
             "confidence":photo["confidence"]}
        if camera is None:
            row["reason"]="insufficient rigid landmarks"
            result.append(row)
            continue
        row["camera_attempt"]={k:camera[k] for k in
                               ("yaw","elevation","roll","distance","rigid_rmse")}
        # 8% crop error is already considerable at 500px. Never optimize
        # one candidate to a bad camera or invent an occluded far leg.
        if camera["rigid_rmse"]>.08:
            row["reason"]="camera landmarks disagree; diagnostic only"
        elif photo["region"]!="all_visible_body":
            row["reason"]="leg(s) occluded; upper-body shape cue only"
        else:
            fits={s:registration.fit_pose(anchors,obs,camera,s)
                  for s in ("l","r")}
            if any(v is None for v in fits.values()):
                row["reason"]="both independent leg poses are required"
            else:
                pose={}
                for s,leg in fits.items():
                    pose[s+"l"]=[leg["thigh_pitch"],0,leg["thigh_roll"]]
                    pose[s+"l_shin"]=[leg["shin_pitch"],0,0]
                row.update({"status":"registered_diagnostic",
                            "camera":camera,"pose":pose,"leg_fit":fits})
        result.append(row)
    return result


def photo_mask(photo,size):
    x0,y0,x1,y1=photo["crop_px"]
    poly=[[(x-x0)/(x1-x0),(y-y0)/(y1-y0)]
          for x,y in photo["outline_px"]]
    return geo.polygon_mask(poly,size)


def evaluate_registered(model,cells,manifest,rows,size=58):
    by_name={p["name"]:p for p in manifest["new_photos"]}
    output=[]
    for row in rows:
        result={"view":row["view"],"status":row["status"]}
        if row["status"]!="registered_diagnostic":
            result["reason"]=row["reason"]
        else:
            truth=photo_mask(by_name[row["view"]],size)
            projected=registration.registered_mask(
                model,cells,row["camera"],row["pose"],size)
            result.update({"iou":round(photo_fit.iou(projected,truth),4),
                           "fit_rmse":round(row["camera"]["rigid_rmse"],5),
                           "camera_yaw":row["camera"]["yaw"],
                           "camera_elevation":row["camera"]["elevation"],
                           "pose_status":"two visible legs fitted and frozen"})
        output.append(result)
    return output


def report(control,candidates,size=58):
    parts=geo.rasterize(control)
    if geo.audit(control,parts):
        raise ValueError("invalid control geometry")
    originals,old_frozen=standard_registration(control,parts)
    manifest=json.loads((HERE/"jenner_additional_reference_views.json").read_text())
    additional=new_registration(control,parts,manifest)
    report_rows=[]
    for label,spec in candidates:
        if spec["sculpt"]!=control["sculpt"]:
            raise ValueError("sculpt mismatch in comparison")
        cells=geo.rasterize(spec)
        faults=geo.audit(spec,cells)
        if faults:raise ValueError(label+" invalid geometry: "+str(faults[:4]))
        prior=registration.evaluate(spec,cells,originals,old_frozen,size)
        new=evaluate_registered(spec,cells,manifest,additional,size)
        report_rows.append({"model":label,"original_three_view_iou":
                            prior["mean_registered_iou"],
                            "original_registered_count":prior["registered_views"],
                            "additional_views":new,
                            "total_voxels":sum(map(len,cells.values())),
                            "geometry_faults":len(faults)})
    return {"sculpt":control["sculpt"],"source_photo_candidates":6,
            "original_registration":old_frozen["registration"],
            "additional_registration":additional,
            "candidates":report_rows,
            "warning":"Three painted crops and one unpainted frontal crop are scored; old rear-right and new oblique side are UN SCORED. The side photo is still a shape reference. Lens/FOV and hand traces are uncalibrated. Do not present numbers as miniature accuracy."}


def main():
    a=argparse.ArgumentParser()
    a.add_argument("--control",type=Path,default=HERE/"jenner_assembly_v11.json")
    a.add_argument("--compare",type=Path,nargs="+",required=True)
    a.add_argument("--output",type=Path)
    a.add_argument("--size",type=int,default=58)
    args=a.parse_args()
    model=json.loads(args.control.read_text())
    candidates=[(p.stem,json.loads(p.read_text())) for p in args.compare]
    result=report(model,candidates,args.size)
    output=json.dumps(result,indent=2)+"\n"
    if args.output:
        if not args.output.resolve().is_relative_to(HERE):
            raise SystemExit("Reports must stay inside isolated experimental lab")
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(output)
    print(output)


if __name__=="__main__":
    main()
