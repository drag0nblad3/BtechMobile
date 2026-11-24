# Jenner JR7-D — torso and leg anatomy review (2021 Catalyst plastic)

**Status:** critical modeling review. `jenner_assembly_v12.json` remains the
accepted *experimental control*. `jenner_assembly_v13_trial.json` is a
**non-promoted** torso/calf experiment. Nothing under `data/voxels/`, game
rules, merged main models, or production renderer is modified.

## Source evidence and calibration cautions

- Same-generation 2021 Inner Sphere Striker Lance CAT35729, base 63.
- [Frontal unpainted miniature](https://www.rpgminihunter.com.au/cdn/shop/files/Fit_P1190416_Final_1200x1200.jpg?v=1708318633):
  reasonably useful full-body perspective and stance registration, but low-res.
- [Oblique unpainted miniature](https://www.rpgminihunter.com.au/cdn/shop/files/Fit_P1190417_Final_1200x1200.jpg?v=1708318633):
  valuable for the leg armor and torso-side shape, **not a scored photo**
  because earlier camera residual ≈0.114 crop units and one leg is occluded.
- The original painted four-angle photos contain three provisionally scored
  views; all scoring must freeze camera position, roll/elevation, crop, lens
  assumption and independently fitted left/right leg pose.

## What is still wrong

| Region | Observed from the real 2021 miniature | v12 geometry problem | Corrective modeling direction |
|---|---|---|---|
| Upper central torso | Stepped equipment stack with a recessed upper grille, angled shoulder insets and a lower forward cockpit | Main body still reads as a tall, continuous prismatic slab; its outer X half-width is nearly unchanged from y=1.61 to 2.08 (about 0.35 model units) | Rebuild the dorsal rack as layered bevelled assemblies; preserve physically embedded grille apertures, shoulder load faces and cockpit support |
| Lower torso/hip saddle | Compact frame, partly obscured by forward cockpit, with thighs emerging at distinct shoulder/hip angles | Large plain central wall beneath the disc; hips look like two vertical stilt roots | Taper posterior lower body; sculpt hip sockets, armor frame and side undercuts from calibrated 3/4 and rear views |
| Upper legs/knees | Shaped, heavily armored thighs with pronounced circular/knuckle-like joint transitions | Long, low-detail taper into an overly geometric knee seam | Independently sculpt thigh armor and genuine knee cap/hub without bridging around the joint, check material ownership after oblique partition |
| Shins/calves | Calf volume with a forward knee guard and layered, chamfered plating | A thin Z-strut silhouette, particularly in the direct side view | Fuller *local* middle calf sections, offset armor and bevelled front/rear plates; keep joint endpoints unchanged |
| Feet | Three distinct claws extending forward, with narrow separations | Blocky shoe ends and shallow cut grooves; source vertex changes can disappear at 0.04 voxel pitch | Make deep, supported, individually bounded toe masses with real negative gap continuity through front tips; validate at rendered voxel resolution |

The frontend neutral-pose render makes mirrored legs look more symmetric than
the physical miniature. **Do not reshape a leg to compensate for a different
camera or pose.** A side-angle photo without a reliable camera registration
can suggest *what components exist*, but cannot provide a trustworthy
numeric shape or angle target.

## Targeted torso/calf v13 trial, and rejected operation

Tested an isolated trial with a small rear CT taper at three y-levels, fuller
*mid-calf* cross sections, and source-contour toe-tip changes. A broader
thigh prototype **failed** because it disconnected both claimed
`ll`/`rl` knee-armor ownership regions. That change was **reverted**.

The working v13 trial passed an independent source-voxel audit:
- **30/30** individually connected components.
- **29/29** load-bearing 2×2 face-backed parent joints.
- **0** overlapping claimed cells.
- Maximum attachment-normal error **14.45°**.
- Occupied source cells: **15,126 v12 → 15,064 v13 trial**.
- CT occupied cells: 3,970 → 3,804. Mid-calf shins: 270 → 319
  **per side**. Foot source polygons changed, but foot voxel occupancy
  **did not**; do not count the toe work as visual improvement.

The change **has not passed a frozen camera/pose photo-fit comparison**
and has not been examined with the Godot rig and its battle poses. Therefore
**do not promote v13 or overwrite v12**, even though the structural
audit passes.

[Open matched front/3/4/side source-voxel comparison](generated/jenner_v12_vs_v13_anatomy.svg).

## Acceptance gates for further passes

1. Recalibrate two new front/3/4 real photos with a measured camera/lens or
   reliable corresponding rigid landmarks. Keep at least one held-out view.
2. Match independent hip, thigh, knee, calf and ankle poses to each
   photographed stance. Report residuals and unscored views.
3. Build angled supportable real masses (not merely painted lines or
   nested overlapping shells), then independently render front/side/top/3/4.
4. Audit 30 connected owners, 29 load-bearing faces, correct
   attachment-normal directions and source-to-export muzzle alignments.
5. Report per-part scores for **CT, pelvis, thigh, knee, shin and foot**,
   and screen for bloating, duplicate parts, absent armor or material gaps.
6. Promote only if clean geometry, better registered part-specific matches,
   correct in-engine rig pose and user-approved renders all agree.
