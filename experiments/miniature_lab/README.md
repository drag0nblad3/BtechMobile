# Miniature-first reconstruction lab (NOT production art)

This is an isolated **proof of concept**, not a replacement for existing
BattleMech sculpts. The merged models in `data/voxels/`,
`data/graphics/voxel_chassis.json`, and `src/view/units/` are untouched.
Nothing in this directory registers models with the game or changes rules.

## What has been tried

A new **Jenner JR7-D** component assembly is independently authored from the
2021 Catalyst Game Labs Inner Sphere Striker Lance sculpt, rather than using
or modifying the merged Jenner. Its editable source is
`jenner_assembly.json`. The current assembly has separate CT, LT, RT, head,
arm/pod, thigh, shin, and foot geometry (12 articulated/owned components,
all eight damage locations).

Geometry is defined in continuous coordinates using **independent polygon
cross-sections**, including planes normal to x, y, or z. The compiler
samples these editable lofts at the desired voxel pitch, applies subtractive
cuts for physical openings, and writes a legacy `VxModel`-compatible recipe.
All coordinates are quantized only during compilation, not during design.

The audit rejects:
- overlapping cells belonging to different articulated components;
- disconnected pieces inside a component;
- missing parents or joints without a **contiguous 2x2 face patch backed
  by material on both sides**.

The compiler **does not perform connectivity repair**. Modelers must correct
the assembly itself. A broken model refuses export; old models are never
auto-adjusted. The output does not claim physical fidelity just because it
passes these tests.

## Run (standard-library Python 3.9+; no Godot, no external photos required)

```sh
python -m unittest discover -s experiments/miniature_lab -v
python experiments/miniature_lab/miniature_lab.py \
  experiments/miniature_lab/jenner_assembly.json \
  --output experiments/miniature_lab/generated/jenner_trial.json \
  --svg experiments/miniature_lab/generated/jenner_views.svg
```

The compiled JSON is an **offline experiment only**. Review it independently
before copying anything into a Godot test scene. The command actively refuses
to write files anywhere in the production repository tree.

For manually annotated source photographs, add normalized silhouette
polygons to an annotation JSON and pass `--annotations ... --report ...`.
The comparison searches the specified yaw/elevation candidates and reports
whole-model IoU plus any annotated component-specific IoUs. An unannotated
photo is labeled *unscored* rather than assigned a fictional similarity
percentage. The camera optimizer is orthographic and currently **does not
fit limb posing or photographic perspective**.

## Reference provenance (external links only)

- Intended version: **Catalyst Game Labs 2021 Jenner** (Inner Sphere Striker
  Lance, product 35729, miniature base 63).
- Photograph catalog: https://jadedfalconer.com/Pages/1Light/jenner
- Multi-view painted reference: https://jadedfalconer.com/Pictures/1Light/35jenner/Jenner6.jpg

Reference photos have *not* been copied into the repository. Different
generations of the same chassis must not be mixed when annotating.

## What this prototype demonstrates, and what remains

The isolated Jenner scaffold compiles to roughly **15k voxels**, not 100k:
voxel density deliberately follows silhouette and details rather than
an arbitrary target. Its geometry has passed local topology and aperture
tests, but the **reference-aligned sculpt and recognizability test are NOT
complete**. In particular, front silhouette and upper armor breaks need
significant additional work; the four-view SVG is only a shape diagnostic,
not a physically shaded in-engine render.

Before any model can be considered for production, the next experiment must:
1. Obtain high-quality photos of the *same* plastic sculpt from front, side,
   rear, top, with pose/camera annotations and usage provenance.
2. Fit camera **and** stance, then annotate named components and score
   silhouette overlap, landmark offsets, negative spaces, and volume.
3. Rebuild components with large geometric corrections until the reference
   tests visibly improve. Compare against the *current* merged Jenner without
   editing that model.
4. Test rig pivots, VxModel loadability, authored openings, and Android
   performance in a separate Godot scene; keep the merged model untouched
   unless separately authorized.

Do not merge this experiment automatically into the game catalog.
