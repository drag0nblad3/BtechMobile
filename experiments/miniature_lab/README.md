# Miniature-first Jenner reconstruction laboratory

**Draft experiment only. No merged model or production model recipe is changed.**
Everything is isolated to experiments/miniature_lab/. No photographs are
redistributed in the repository.

## Artifacts

- jenner_assembly.json: preserved independent baseline hypothesis
- jenner_resculpt.json: *new* loft-based Jenner resculpt, not production art
- miniature_lab.py: continuous cross-sections to voxel recipe plus joint and
  overlap checks; rejects geometry issues rather than fabricating bridges
- jenner_photo_annotations.json: four hand-estimated mini silhouettes from the
  same sculpt, camera yaw/elevation candidates and articulated stance samples
- photo_fit.py: pose-dependent 3D projections and camera search, total silhouette
  and selected component intersection-over-union (IoU) comparisons
- test_miniature_lab.py and test_photo_fit.py: ten local regression tests

Source miniature: **Catalyst Game Labs 2021 Jenner**, Inner Sphere Striker Lance
35729, base 63. Four-angle photographic montage:
https://jadedfalconer.com/Pictures/1Light/35jenner/Jenner6.jpg
Scuplt provenance:
https://jadedfalconer.com/Pages/1Light/jenner

The reference outlines were hand-estimated by inspecting a 750x1000 montage,
not segmented at native resolution. Poses and camera angles are chosen from
a finite small candidate set. The metric is a *low-confidence diagnostic*, not
a real percent sculpt accuracy or a calibrated photogrammetric validation.

## Reproduce (Python 3.9+ standard library)

From the repository root:

    python -m unittest discover -s experiments/miniature_lab -v

    python experiments/miniature_lab/photo_fit.py --source experiments/miniature_lab/jenner_assembly.json --reference experiments/miniature_lab/jenner_photo_annotations.json --size 58

    python experiments/miniature_lab/photo_fit.py --source experiments/miniature_lab/jenner_resculpt.json --reference experiments/miniature_lab/jenner_photo_annotations.json --size 58

    python experiments/miniature_lab/miniature_lab.py experiments/miniature_lab/jenner_resculpt.json --output experiments/miniature_lab/generated/jenner_trial.json --svg experiments/miniature_lab/generated/jenner_views.svg

The generated voxel recipe is offline only. The compiler blocks writes to
production directories; no game catalog, merged recipe, or rules asset changes.

## Changes made directly to this experiment

Replaced the rectangular beak with a flattened tapered cockpit and segmented
glazing. Reshaped the constant-section shoulder pods into variable section
beveled housings with actual forward-facing laser bores (two per side), aligned
muzzle coordinates and smaller outboard caps. Resculpted the center torso
and dorsal hump, plus real narrow upper grille recesses. Replaced stick-like
legs with bent, tapered thigh/shin/foot assemblies. Kept 12 independent parts
covering all eight record-sheet hit locations and checked 2x2 backed joints.

## Preliminary scores — approximate manually traced 2D silhouettes

| View | Baseline | Resculpt |
|---|---:|---:|
| Front left | 0.479 | 0.498 |
| Front right | 0.577 | 0.621 |
| Rear left | 0.616 | 0.642 |
| Rear right | 0.539 | 0.575 |
| **Mean** | **0.553** | **0.584** |

A 0.584 *IoU proxy* is not 58.4% miniature accuracy. Photo clutter,
unknown lens perspective and coarse outlines make the score uncertain.
The head's component-specific overlap remains low. No photographic
fidelity acceptance, Godot load test or phone rendering is claimed.

Local prototype: 10 Python tests passed, no detected geometric overlap,
component islands or weak joints. In-engine animation and performance
checks remain pending. Do not merge as production art or build an APK.

## Additional measured pass: camera/leg-pose landmarks and combined geometry

The independent landmark fitter (reference_fit.py) uses
jenner_photo_landmarks.json: three approximate same-sculpt photo views with
annotated dorsal peak, projecting cockpit, launcher edges, lower torso, and
knee/foot landmarks. Camera yaw/elevation/scale/translation are fitted first;
then individual two-joint leg pitches are fitted separately. These are
low-confidence hand-estimated points, not pixel-precise mask annotations;
perspective/lens distortion and the complete pose are not calibrated.

The next candidate is jenner_assembly_combined.json. It starts from the
independent jenner_resculpt.json (which has a stronger four-view silhouette
proxy than the separate v3/v4 exploration) and lowers the head by 0.06
source units while pushing the bottom two torso cross sections 0.10 source
units forward. This correction retains eight damage locations, physical
launcher ports and the strict geometry audit. The earlier experimental
v3/v4 sources are retained for diagnostic comparisons, not replacements.

| Coarsely hand-traced diagnostic | Initial experiment | Combined trial |
|---|---:|---:|
| Three-view rigid landmark RMSE (lower better) | 0.03500 | 0.02402 |
| Four-view silhouette IoU proxy (higher better) | 0.553 | 0.585 |
| Occupied source voxels | 14,864 | ~14,127 |
| Structural audit issues | 0 | 0 |

These are **low-confidence proxy scores**, not accuracy percentages.
The front cockpit component silhouette overlap is still only about
0.09–0.11 in two annotated three-quarter views, and this is a blocking
modeling defect. The landmark fitter and silhouette tester use different
camera/stance approximations; agreement is helpful but not proof of
miniature fidelity. The reference photographs are linked, never committed.

Commands from repository root:

    python -m unittest discover -s experiments/miniature_lab -v
    python experiments/miniature_lab/reference_fit.py experiments/miniature_lab/jenner_photo_landmarks.json experiments/miniature_lab/jenner_assembly.json experiments/miniature_lab/jenner_assembly_combined.json
    python experiments/miniature_lab/photo_fit.py --source experiments/miniature_lab/jenner_assembly_combined.json --reference experiments/miniature_lab/jenner_photo_annotations.json --size 58

Next: replace the still-generic cockpit and shoulder transitions with
component-matched plates, collect cleaner same-edition photos, calibrate
perspective, and do isolated Godot rig/performance smoke runs. Do not
install an experimental recipe into data/voxels/ or merge production art.
