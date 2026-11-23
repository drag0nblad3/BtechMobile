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

## Second sculpt pass: rounded lower cockpit and stepped shoulder armor (v5)

The v5 candidate is an additional experimental **source assembly**, not a
replacement for either the older experimental candidates or any merged
game model. Source: jenner_assembly_v5.json.

- Replaced the wedge-like cockpit hull with seven circular/oval cross
  sections, a shallow forward face, and segmented glazing.
- Added a deliberately modeled, mass-backed cockpit-to-torso neck instead
  of relying on automatic geometry bridges. No face overlap is permitted.
- Reshaped left/right shoulder fairings while preserving the paired arm pod
  positions and their independent damage locations.
- Made upper-torso missile/vent apertures into real negative space.
- Preserved all twelve articulated pieces and all eight record-sheet
  locations. No game rules, merged models, or battle art were edited.

The independent source-raster geometry audit reports 0 disconnected
components, 0 inter-part overlaps, and 0 weak, unsupported joints.
Local test run: 19 Python unittest tests passed, including the new
test_jenner_v5.py checks.

### Two distinct reference proxies (not accepted fidelity scores)

| Experimental candidate | 3-view landmark RMSE (lower) | 4-view coarse silhouette IoU (higher) |
|---|---:|---:|
| Previous combined geometry | 0.02402 | 0.585 |
| Rounded-cockpit/shoulder v5 | 0.02337 | 0.576 |

**Interpretation:** the nose-related landmarks improve slightly, but the
coarse silhouette metric regresses. This is NOT a net proven art improvement,
and v5 must not be promoted as the new accepted model. The manual annotated
photo crops contain pose, lens, and silhouette-label uncertainties. The
head is still the largest modeling problem.

### Visual comparison with the unchanged main model

[Open a four-angle comparison of the actual main Jenner voxel recipe and
v5 experimental recipe](generated/jenner_main_vs_v5.svg).

The visualization reads data/voxels/jenner_shape.json **from main** as of
blob 3a20aedd14ad63f187ee2e84bb595e015acd40bd. Its source is not
edited, copied into a production model, or merged. Both render rows are
generated from occupied voxels with matching orthographic view transforms:
front, three-quarter, side, and rear. This is a **source-geometry preview**,
not a Godot in-engine render; it does not include rig animations,
renderer-specific refinement, or lighting.

The next sculpting pass should focus on the plastic miniature's faceplate,
lower cockpit disc profile and dorsal/vent armor plates, then obtain sharper
head-specific reference images and calibrated camera poses. Preserve the
previous combined candidate as the scored baseline until both independent
reference tests support replacing it.

## Third pass: v6 — physically owned angled subassemblies and richer polygons

The new trial is `jenner_assembly_v6.json`, generated from the independent
v5 source by `make_jenner_v6.py`; **no merged Jenner has been opened for
editing**. All changes remain under `experiments/miniature_lab/`.

### More meaningful component separation

- 12 -> **25 rigid/rigged pieces**, including a forward nose cowling,
  separate cockpit crown, raised dorsal torso plate, paired slanted shoulder
  cap plates, pod endcaps, knee armor cuffs, angled calf plates, and toes.
- The moving lower-leg chain explicitly attaches through these actual
  subassemblies. Rig export now topologically sorts parent before child, which
  is required by VxModel's loader.
- `subassembly.py` partitions existing occupied material along author-supplied
  **inclined 3D planes**. Material and voxel ownership transfer rather than
  new overlapping plate slabs. Automatic repairs are forbidden.
- All 13 added interfaces require the existing backed 2×2 solid attachment
  patch **and** a measured child-to-parent contact normal within 38 degrees
  of the authored attachment angle.
- Reconstructed curved contours use Catmull-Rom intermediate vertices;
  sharp plate contours use additional chamfer facets. Total polygon-section
  vertices rise from **1,064 to 1,584** (max section 16 -> 32 points).
  Physical launcher openings remain subtractive.

### Checkable results (no photographic quality claims)

| Measure | v5 | v6 |
|---|---:|---:|
| Distinct components | 12 | 25 |
| Occupied voxels | 14,860 | 14,966 |
| Polygon-section vertices | 1,064 | 1,584 |
| Detected topology/attachment faults | 0 | 0 |
| Three-view approximate landmark RMSE | 0.02337 | 0.02355 |
| Four-view coarse silhouette IoU (size 50) | 0.578 | 0.578 |

The ~0.7% voxel change comes only from modifying primary polygon contours,
**not** splitting the pieces: the segmentation test proves its source geometry
is exactly conserved cell-for-cell and material-for-material. Neither
reference metric establishes improved plastic-miniature resemblance; the
landmark score is slightly worse within the uncertainty of hand-picked
pixels, and silhouette overlap is unchanged. The sculpt still needs a more
faithful cockpit and launcher proportion correction.

Reproduce from the repository root (standard-library Python):

    python experiments/miniature_lab/make_jenner_v6.py
    python -m unittest discover -s experiments/miniature_lab -v
    python experiments/miniature_lab/miniature_lab.py experiments/miniature_lab/jenner_assembly_v6.json --output experiments/miniature_lab/generated/jenner_v6_compiled.json --svg experiments/miniature_lab/generated/jenner_v6_views.svg

The v6 source is a **trial**, not production art. There has been no Godot
in-engine animation or device performance validation. All lower-priority
geometry refinements should continue in the experiment branch, while main
stays untouched.


## Further iteration: Jenner v7/v8 (30 assemblies, real oblique interfaces)

The v7 assembly adds five named components on top of v6: left and right
nose cheek cowls, left and right **inboard arm/pod mounting sockets**, and
an independent lower-torso/hip skirt. These are **angled owner transfers**:
the arm pods attach through their own load-bearing socket instead of merely
intersecting shoulder armor, and the hips attach to the separated skirt.
Each cheek, socket and skirt is solidly supported. The geometry remains
fully independent from all merged BattleMech models.

The v8 pass also shapes the central torso and both shoulder cross sections
with 16-point polygon profiles instead of the original 8-point sections.
Head and launcher shells retain their 24/32-point curves. All 29 parent-child
joints now carry explicit intended support directions, including the
original hip/knee/ankle chain, and are checked against the *measured*
face-contact normal and a contiguous backed 2x2 patch. The worst measured
attachment-normal deviation is under **15 degrees**; no seams are silently
filled.

| Check (same approximate source photos, not calibrated) | v5 | v7 | v8 |
|---|---:|---:|---:|
| Distinct geometry components | 12 | 30 | 30 |
| Total polygon cross-section vertices | 1,064 | 1,296 | 1,424 |
| Occupied voxels | 14,860 | 14,996 | 14,986 |
| Four-view silhouette IoU proxy, 58px | 0.576 | 0.582 | 0.582 |
| Three-view rigid landmark RMSE | 0.02337 | 0.02355 | 0.02355 |
| Geometry/attachment audit failures | 0 | 0 | 0 |

**Interpretation:** this is a useful structural authoring advance, not a
demonstrated major likeness improvement. The silhouette proxy increases
slightly at 58px, but at 50px is effectively unchanged. More detailed,
calibrated reference views and recognizable head/torso proportions remain
the most important next sculpting work.

Run from repository root:

    python experiments/miniature_lab/make_jenner_v7.py
    python experiments/miniature_lab/make_jenner_v8.py
    python -m unittest discover -s experiments/miniature_lab -v
    python experiments/miniature_lab/miniature_lab.py experiments/miniature_lab/jenner_assembly_v8.json --output experiments/miniature_lab/generated/jenner_v8_compiled.json --svg experiments/miniature_lab/generated/jenner_v8_silhouettes.svg

The actual v8 voxel geometry has also been rendered separately as a
four-angle shaded raster and a component-color assembly diagnostic. These
are **offline voxel-geometry previews**, not Godot in-engine captures. No
production recipe has been overwritten, no Android build was attempted,
and the v5/v6/v7 sources remain available for comparisons.

Do not promote v8 or merge this experiment as production art without a
high-confidence photographic fit and a Godot rig/animation smoke test.

## v9/v10 targeted sculpt correction — shape, not just segmentation

The **2021 Catalyst plastic Jenner** remains the only intended reference
generation (Inner Sphere Striker Lance, CAT35729). No alternate metal
sculpts are mixed into this comparison.

Two more experimental sculpt revisions are retained alongside v8:
- **v9**: flatten the projecting cockpit disc and distinguish three actual
  forward window panels plus two roof panes; narrow lower torso depth,
  angle knees forward and carve two shallow cuts separating three foot tips.
  Window panels now use an explicit **paint-only** voxel operation:
  glazing cannot add unsupported geometry outside the source hull.
- **v10**: widen and angle the shoulder fairings, reshape their real front
  creases, and shorten the inboard weapon-pod housings without extending
  their outboard reach. The medium-laser bores and the matching muzzle
  coordinates are remapped together. No duplicate arms or invisible
  connector blocks are introduced.

| Diagnostic (hand-estimated plastic reference) | v8 | v9 | v10 |
|---|---:|---:|---:|
| Independently owned pieces | 30 | 30 | 30 |
| Cross-section control vertices | 1,424 | 1,504 | 1,520 |
| Voxels | 14,986 | 14,802 | 15,226 |
| Four-view silhouette IoU, 58px (higher better) | 0.582 | 0.581 | 0.580 |
| Rigid landmark RMSE (lower better) | 0.02355 | 0.02324 | 0.02322 |
| Connection, island and overlap errors | 0 | 0 | 0 |
| Worst joint-direction deviation | 9.25° | 9.25° | 9.25° |

**Important limitation:** reference masks and landmarks are hand-estimated.
A one- or two-thousandth change is not evidence of accurate miniature
likeness. This is a **plausible geometric improvement**, not a verified
fidelity win: the raw silhouette proxy actually slips slightly. We retain
v8/v9 as controls, rather than promoting v10 or altering the merged Jenner.

To inspect and reproduce the offline source-geometry proof:

    python -m unittest discover -s experiments/miniature_lab -v
    python experiments/miniature_lab/miniature_lab.py experiments/miniature_lab/jenner_assembly_v10.json --output experiments/miniature_lab/generated/v10_compiled.json --svg experiments/miniature_lab/generated/v10_silhouettes.svg
    python experiments/miniature_lab/photo_fit.py --source experiments/miniature_lab/jenner_assembly_v10.json --reference experiments/miniature_lab/jenner_photo_annotations.json --size 58
    python experiments/miniature_lab/reference_fit.py experiments/miniature_lab/jenner_photo_landmarks.json experiments/miniature_lab/jenner_assembly_v8.json experiments/miniature_lab/jenner_assembly_v10.json

The isolated sculpt has passed Python geometry tests, **not an in-engine
Godot pose/renderer smoke test**. A four-angle shaded voxel render and
an eight-panel v8-versus-v10 comparison were produced from actual source
geometry in the conversation. New artwork remains opt-in and draft.


## Camera and pose registration — required before claiming a photo match

**Do not compare the neutral-pose source silhouette against a posed,
perspective photograph.** Otherwise a changed camera or bent ankle can be
mistaken for incorrect geometry. The older `photo_fit.py` scores in this
document are retained for historical reproducibility but are now explicitly
labeled **legacy unregistered diagnostics**, not accepted similarity scores.

The new `photo_registration.py` pipeline makes the adjustment explicit:

1. Restrict each photograph to the **same plastic sculpt generation**.
2. Fit camera **yaw, elevation, roll, effective distance/perspective,
   uniform scale and image translation** to annotated, rigid torso landmarks.
   The camera crop is fixed to the photograph, not independently recentered
   for each candidate model. Mirror and anisotropic stretch are prohibited.
3. Fit each leg's **thigh pitch, thigh roll, and knee flex** to knee, ankle,
   and foot landmarks *after* camera fitting. Geometry is not edited to
   resolve stance differences.
4. **Freeze the registered camera, image transform, and pose** from a
   nominated control model and apply the identical registration to all
   candidates. Only then compute silhouette IoU. Camera/rig choices never
   maximize the candidate's silhouette overlap.
5. Mark photos **unscored** when camera or pose landmarks are missing.
   Report the residual landmark errors, measured view coverage, and unknown
   optical calibration. Never portray approximate IoU as a percent of
   plastic-miniature accuracy.

Reproduce on the independent v8 and v10 experimental Jenner:

    python -m unittest discover -s experiments/miniature_lab -p test_photo_registration.py -v
    python experiments/miniature_lab/photo_registration.py --calibration-model experiments/miniature_lab/jenner_assembly_v8.json --compare experiments/miniature_lab/jenner_assembly_v8.json experiments/miniature_lab/jenner_assembly_v10.json --masks experiments/miniature_lab/jenner_photo_annotations.json --landmarks experiments/miniature_lab/jenner_photo_landmarks.json --output experiments/miniature_lab/generated/jenner_registered_v8_v10.json

The initial synthetic camera/leg tests passed locally. Using the current
coarsely hand-labeled photos and 58px masks, a locally registered comparison
of v8 and v10 yielded **0.7178 versus 0.7184**, respectively, across
**3 of 4** matched views. The fourth photograph has insufficient pose and
camera landmarks and therefore receives **no score**. The numbers are so
close that neither should be called a demonstrated likeness improvement.

**Not yet calibrated:** original lens focal length/FOV, camera distortion,
camera location measured on set, and full foot/ankle/arm pose. Camera
distances were inferred from rough landmarks and are only relative to the
model scale. Calibrated or better-lit image sets are required before setting
acceptance thresholds. No merged source art or production pipeline changed.

## Jenner v11 — five successive camera/stance-matched sculpting passes

The new `make_jenner_v11.py` source reproducibly starts from the independent
v10 JSON, never from any model on `main`. It performs five distinct geometry
passes. The exported v11 sculpt remains in `jenner_assembly_v11.json`,
with detailed per-pass results in `jenner_v11_pass_scores.json`.

- **01 · Torso:** remove excess rear hull depth while preserving 30 owner
  parts, all head/hip pivots, and the front launcher. This alone is a minor
  silhouette tradeoff rather than a guaranteed likeness gain.
- **02 · Cockpit:** extend, flatten and re-profile the distinctive forward
  Jenner disc with individually retained, paint-only glass panes.
- **03 · Shoulders and pods:** give the shoulder plating directional slopes
  and a less generic faceted profile on both weapon housings.
- **04 · Knees:** refine front/rear thigh and shin contours but leave
  contact endpoints and the photographed stance solver unchanged.
- **05 · Dorsal sensor:** add a short, 24-vertex, physically connected
  sensor dish/cap visible in the current Catalyst plastic sculpt.

### Measured but still low-confidence changes

One registration is fitted against the control v8 Jenner using a shared
2021 sculpt photo set, then **frozen across the entire v10/v11 sweep**.
The comparison includes camera yaw, elevation, roll, effective distance,
crop translation and per-leg pose. Do not independently align each v11
shape to maximize a silhouette score.

| Experimental source pass | Voxels | Frozen-view IoU | Landmark RMSE | Geometry faults |
|---|---:|---:|---:|---:|
| v10 control | 15,234 | 0.7182 | 0.02308 | 0 |
| 01 Torso | 14,786 | 0.7177 | 0.02300 | 0 |
| 02 Cockpit | 14,784 | 0.7185 | 0.02258 | 0 |
| 03 Shoulder/pods | 14,919 | 0.7183 | 0.02247 | 0 |
| 04 Knees | 14,965 | 0.7186 | 0.02247 | 0 |
| 05 Sensor dish / v11 | **14,977** | **0.7211** | **0.02183** | **0** |

These numbers are **not** measured plastic-miniature accuracy. Three out
of four reference photos have a usable provisional registration; the
rear-right photo is explicitly **unscored**, not counted as a zero. The
original camera lens/FOV and photo mask accuracy are unknown. Multiple
alternatives were rejected because of structural overlaps/disconnected
child parts or poorer view fits; see the earlier baseline pass results.
This is a small but directionally useful improvement, not a definitive
art replacement.

Validation: all five intermediate assemblies and final 30-part sculpt
passed the non-bridging occupancy/attachment audit. Their 29 attachment
interfaces still require backed 2×2 structural contacts and directionally
valid joint normals. The **seven new targeted v11 tests passed locally**
using a repository-equivalent control source. A previous full local lab
suite passed 53 tests; a separate current full CI confirmation is needed
before promoting v11. An isolated, actual-geometry four-view render and
v10/v11 comparison are available in the conversation.

Reproduce from the repository root:

    python experiments/miniature_lab/make_jenner_v11.py
    python -m unittest discover -s experiments/miniature_lab -p 'test_jenner_v11.py' -v
    python experiments/miniature_lab/photo_registration.py --calibration-model experiments/miniature_lab/jenner_assembly_v8.json --compare experiments/miniature_lab/jenner_assembly_v10.json experiments/miniature_lab/jenner_assembly_v11.json --masks experiments/miniature_lab/jenner_photo_annotations.json --landmarks experiments/miniature_lab/jenner_photo_landmarks.json

**No production `data/voxels/` or `src/` changes; no merge, Android APK
build, or in-engine Godot smoke test in this pass.**
