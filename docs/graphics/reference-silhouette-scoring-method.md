# Reference-silhouette review: full voxel catalog (22 November 2026)

**Status: inventory and scoring pipeline implemented; reference-fit evaluation NOT YET EXECUTED.**
Do not interpret blank score fields as zero or turn model-to-model confusion similarity
into a reference-image fit percentage.

## Catalog and evidence

- [Per-model scorecard](all-model-reference-silhouette-scorecard.csv): **334 distinct visual
  recipes**, comprising **289 BattleMech visual recipes** (281 shape-first studies plus eight
  standalone/variant recipes), **16** support archetypes, **22** record-sheet vehicles, and
  **7** battle-armor recipes.
- All records have individual fields for **front**, **side**, **quarter/45°**, **top**,
  weighted **overall**, reference source/status, improvement suggestions by angle,
  and the specific overall resculpt focus.
- 151 previously audited 'Mechs have optional nearest-neighbor similarity diagnostics.
  These are carried through strictly as **confusion risk, not a silhouette-to-reference
  score**. The other 138 distinct Mech visual recipes were not covered by that older
  diagnostic, and the CSV does not pretend otherwise.
- The current repository includes a few source-linked current-plastic reference
  anchors; for every other entry **plastic status remains unverified**, which is not
  a claim that no miniature exists.
- The repository does not currently contain a complete, licensed, annotated set of
  four-angle **foreground silhouette masks** corresponding to the current models.
  Every numerical reference-fit score is therefore blank by design.

## Scoring process

1. Prefer **modern Catalyst plastic** silhouette references where an equivalent
   chassis sculpt exists. Use official recognition-guide / TRO images, then documented
   legacy/metal miniatures for models lacking modern plastic. Record exact sculpt
   variant, provenance, pose and camera angle. Do not use an incidental fan sculpt
   as official ground truth.
2. **Match the reference stance by rigging before calculating similarity.**
   Identify the photographed miniature's pose, including relative foot position,
   knee flexion, hip yaw, torso lean, shoulder angle, forearm attitude, and weapon
   orientation. Use the **actual authored hierarchical pivot joints**, including
   digitigrade hocks and ankles; never rescale a limb, slide detached parts, or
   distort an image mask to mimic pose matching. Keep feet on plausible ground,
   and preserve connected shoulder/weapon supports. Each model needs a documented
   pose confirmation against its chosen reference; a neutral T-pose or generic
   idle animation is *not* assumed to match a miniature photo. Static vehicles
   are exempt from articulated-Mech stance review but still need camera alignment.
   Keep handedness and orthographic camera angles matching; segment the subject,
   remove the base and cast shadows. Three-quarter photos at unknown yaw cannot
   be compared to a fixed 45-degree projection; correct the camera instead of
   forcing a hip rotation. Do not mirror asymmetric chassis for convenience.
3. In [reference-stance-poses.json](reference-stance-poses.json), create an
   entry under `models.<chassis_id>` with `default.joints` and optional
   `front.joints`, `side.joints`, `quarter.joints`, `top.joints`. Each joint's
   value is Euler `[x,y,z]` rotation **in degrees**; joint names must match
   the model's actual authored articulated part names. Also allow
   `body_rotation_deg` for measured whole-rig lean, not for correcting a
   mistaken camera yaw. A single pose across views is preferred when all angles
   show the same miniature; use per-angle overrides only when the source photos
   genuinely depict different poses. Record the exact reference, rig adjustments,
   side/angle, and verification in the per-model scorecard. Never optimize joints
   to artificially maximize the metric: use the photographed stance first.

4. Export the **rigged, pose-adjusted** source voxel occupancy silhouettes:

       godot --headless --import
       godot --headless -s tools/export_reference_review_masks.gd -- /tmp/model-masks res://docs/graphics/reference-stance-poses.json

   This emits 64x64 ASCII mask grids for front, side, quarter, top (one directory
   per model). If comparing high-resolution painted renders instead, convert
   precisely aligned orthographic model silhouettes to black/white PNG masks.
   The ASCII export is shape-based rather than an in-game rendered screenshot;
   audit deviations caused by pose or bevels separately.
5. For each model, put reference files under
   `/tmp/reference-masks/<model-id>/<angle>.png` (or `.txt` with '#' foreground).
   Masks must be presegmented. White background/black subject or transparent
   background/opaque subject are accepted by the PNG loader (requires Pillow).

       python tools/score_reference_silhouettes.py \
         --scorecard docs/graphics/all-model-reference-silhouette-scorecard.csv \
         --renders /tmp/model-masks --references /tmp/reference-masks \
         --output /tmp/model-reference-scores.csv

6. **Do not score unverified poses.** Set the row's `stance_review_status`
   to `VERIFIED_RIG_MATCH` only after verifying every compared angle against its
   selected reference, and put the actual pose JSON path in `stance_profile`.
   For non-articulated assets, use `NOT_APPLICABLE_STATIC`. A BattleMech row
   with `UNVERIFIED_POSE` is refused even if four reference files exist.
   
   Score each angle on **0–100**, combining **70% mask intersection-over-union**
   and **30% 2-pixel-tolerant silhouette-boundary F1**, after an isotropic
   crop-and-center scale normalization to 128x128. The overall score uses
   **front 55%, side 28%, quarter 12%, top 5%**. The scorer only writes an
   overall score when **all four** model/reference pairs exist. Missing matches
   stay blank, with a partial-coverage status, never guessed.
7. Human review must validate the chosen reference and note specific profile
   mismatches (weapons, head, shoulder mount, chest waist, leg joint angle,
   backpack, top silhouette and gaps). Recheck with actual Godot voxel renders
   whenever the shape-mask score hides material/rendered anatomy problems.
   Retain the current scorecard's angle-specific improvement prompts and
   replace them with measured corrections as the comparisons are completed.

## Interpreting scores

100 is a perfect occupancy silhouette match **for the verified reference-matched rig pose** after scale/translation alignment;
it is **not** a quality label. A matching but incorrect 2D pose can score highly,
and component topology, weapon bores, articulation, perspective, paint and
gameplay appearance are assessed separately.

For triage, **85+** suggests close shape agreement, **70–84** suggests localized
resculpts, **50–69** indicates major silhouette mismatch, and **below 50**
warrants a rebuilt primary profile. These are starting review thresholds, not
empirically validated miniature scoring benchmarks. For a chassis without a
modern plastic sculpt, use a **less strict acceptance target** when the best
available official legacy artwork conflicts or has an ambiguous angle; do not
silently inflate its measured geometry score. Mark the lower-confidence source
and the relaxation in its review notes.

## Honesty and limitations

The earlier [multi-angle audit](../../tools/voxel_multiangle_audit.gd) checks
connectivity, proportions and shape confusion; it **does not provide the
requested optical reference-fit scores**. The contour-resculpt documentation
repeatedly treats its results as provisional until human photo/render approval.
The full scorecard therefore records the work to do rather than generating
plausible-looking percentages from unrelated metrics.

Synthetic image-mask score tests are in
`tests/tools/test_score_reference_silhouettes.py` and can run via
`python -m unittest discover -s tests/tools -p 'test_score_reference_silhouettes.py'`.
Stance corrections are temporary audit pose profiles only; the reference pose
must not be persisted as a default game stance or used to hide badly sculpted
body proportions. The mask projection uses centers of actual authored occupied
voxel cells after joint transforms; visual inspection of Godot render meshes is
still needed, especially for thin antennae and visible contact points.

This documentation and tooling change does not modify combat rules, official
design JSONs, existing voxel geometry, game rendering, or build an Android APK.
