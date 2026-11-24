#!/usr/bin/env python3
"""Fair photo comparison when a reconstructed rig has relocated its pivots.

Rule: freeze photographic camera and scale on an unchanged control sculpt.
If a pivot moved during *physical reattachment*, solve its articulated
thigh/foot stance again from observed knee/ankle/foot landmarks. Do not
refit camera or optimize any silhouette score. Uncalibrated views unscored.
"""
import json
from pathlib import Path

import miniature_lab as geo
import photo_registration as camera
import reference_fit as marks
import multisource_fit as multi

HERE=Path(__file__).resolve().parent


def world_anchors(spec, cells):
    """Reference fitter works in grid cells; convert all to world units."""
    anchors=marks.anchors(spec,cells)
    return {name:tuple(v*spec["pitch"] for v in point)
            for name,point in anchors.items()}


def pose_for_pivots(spec, cells, photographed_landmarks, photo, fixed_cam,
                    original_pose=None, original_spec=None):
    """Refit only after an actual pivot relocation; camera is immutable."""
    orig={p["name"]:p.get("pivot") for p in
          (original_spec or spec)["parts"]}
    now={p["name"]:p.get("pivot") for p in spec["parts"]}
    changed=sorted(k for k in now if now[k]!=orig.get(k))
    if not changed:
        if original_pose is None:
            raise ValueError("unchanged pivots require frozen original pose")
        return {"pose":original_pose,"changed_pivots":[],
                "leg_fit":None,"method":"frozen_angle_values"}
    observations=camera.crop_observations(
        photographed_landmarks,photo)
    raw=world_anchors(spec,cells)
    fitted={side:camera.fit_pose(raw,observations,fixed_cam,side)
            for side in ("l","r")}
    if any(x is None for x in fitted.values()):
        return {"status":"unscored",
                "reason":"insufficient leg landmarks for relocated hinge",
                "changed_pivots":changed}
    pose={}
    for side,leg in fitted.items():
        pose[side+"l"]=[leg["thigh_pitch"],0,leg["thigh_roll"]]
        pose[side+"l_shin"]=[leg["shin_pitch"],0,0]
    return {"pose":pose,"leg_fit":fitted,
            "changed_pivots":changed,
            "method":"landmark_pose_refit_camera_frozen"}


def compare(control,trial, size=58):
    """Evaluate the same reliable 2021 photo set, with honest exclusions."""
    reference=json.loads(
        (HERE/"jenner_photo_annotations.json").read_text())
    landmarks=json.loads(
        (HERE/"jenner_photo_landmarks.json").read_text())
    extra=json.loads(
        (HERE/"jenner_additional_reference_views.json").read_text())
    old=geo.rasterize(control)
    new=geo.rasterize(trial)
    if geo.audit(control,old) or geo.audit(trial,new):
        raise ValueError("geometry invalid; cannot compare")
    original,frozen=multi.standard_registration(control,old)
    score_old=camera.evaluate(control,old,original,frozen,size)
    data={}
    mask_by_name={x["name"]:x for x in original["views"]}
    landmark_by_name={x["name"]:x for x in landmarks["views"]}
    mapping={"front_left":"front_left_3quarter",
             "front_right":"front_right_3quarter",
             "rear_left":"rear_left_3quarter"}
    comparisons=[]
    for row in frozen["registration"]:
        v=row["view"]
        if row["status"]!="diagnostic_only":
            comparisons.append({"view":v,"status":"unscored",
                                "reason":row.get("reason")})
            continue
        obs=landmark_by_name[mapping[v]]
        # Use the PHOTO'S camera, not a new best-fit camera for v16.
        trial_pose=pose_for_pivots(
            trial,new,obs,mask_by_name[v],row["camera"],
            row["pose"],control)
        if trial_pose.get("status")=="unscored":
            comparisons.append({"view":v,**trial_pose})
            continue
        truth=camera.photo_fit.make_reference(mask_by_name[v],size)
        pred=camera.registered_mask(
            trial,new,row["camera"],trial_pose["pose"],size)
        old_view=next(x for x in score_old["views"] if x["view"]==v)
        comparisons.append({
            "view":v, "status":"diagnostic_only",
            "old_iou":old_view["iou"],
            "new_iou":round(camera.photo_fit.iou(pred,truth),4),
            "camera_fixed":True,
            "pose_rule":trial_pose["method"],
            "changed_pivots":trial_pose["changed_pivots"],
            "leg_pose_rmse":{s:round(f["rmse"],4)
                              for s,f in trial_pose["leg_fit"].items()}
            if trial_pose["leg_fit"] is not None else None})
    # Additional unpainted frontal photo, same calibration and stance rule.
    further=multi.new_registration(control,old,extra)
    for row in further:
        if row["status"]!="registered_diagnostic":
            comparisons.append({"view":row["view"],"status":"unscored",
                                "reason":row["reason"]})
            continue
        photo=next(p for p in extra["new_photos"]
                   if p["name"]==row["view"])
        obs={"landmarks_px":{**photo["rigid_px"],
                             **photo.get("pose_px",{})}}
        trial_pose=pose_for_pivots(
            trial,new,obs,photo,row["camera"],row["pose"],control)
        if trial_pose.get("status")=="unscored":
            comparisons.append({"view":row["view"],**trial_pose})
            continue
        truth=multi.photo_mask(photo,size)
        before=camera.registered_mask(
            control,old,row["camera"],row["pose"],size)
        after=camera.registered_mask(
            trial,new,row["camera"],trial_pose["pose"],size)
        comparisons.append({
            "view":row["view"], "status":"diagnostic_only",
            "old_iou":round(camera.photo_fit.iou(before,truth),4),
            "new_iou":round(camera.photo_fit.iou(after,truth),4),
            "camera_fixed":True,
            "pose_rule":trial_pose["method"],
            "changed_pivots":trial_pose["changed_pivots"]})
    scored=[v for v in comparisons if v["status"]=="diagnostic_only"]
    return {
        "control":control.get("shape_refinement_revision"),
        "trial":trial.get("shape_refinement_revision"),
        "scores":comparisons,
        "mean_control":round(sum(x["old_iou"] for x in scored)/len(scored),4)
        if scored else None,
        "mean_trial":round(sum(x["new_iou"] for x in scored)/len(scored),4)
        if scored else None,
        "warning":"Camera frozen across models. Poses re-fit ONLY when physical rig pivots move, using landmark error, not silhouette overlap. Hand-traced photos and unmeasured lens remain diagnostic only."
    }


def main():
    import argparse
    a=argparse.ArgumentParser()
    a.add_argument("--control",type=Path,
                   default=HERE/"jenner_assembly_v15_trial.json")
    a.add_argument("--trial",type=Path,
                   default=HERE/"jenner_assembly_v16_trial.json")
    a.add_argument("--output",type=Path)
    args=a.parse_args()
    control=json.loads(args.control.read_text())
    trial=json.loads(args.trial.read_text())
    result=json.dumps(compare(control,trial),indent=2)+"\n"
    if args.output:
        if not args.output.resolve().is_relative_to(HERE):
            raise SystemExit("No outputs outside the experiment")
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(result)
    print(result)


if __name__=="__main__":
    main()
