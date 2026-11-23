# Pre-sculpt official reference pair experiment — 23 November 2026

A reference-driven **sculpt preflight** is now recorded before changing any
Conjurer/Dominator or HawkWolf/Black Hawk source geometry.

The program downloads the original official Sarna-hosted published drawings
transiently and compares **manually traced rough external silhouettes**
(excluding illustrated terrain, shadows, signature and isolated ink).
The mask annotations are visible and reviewable in
`docs/graphics/reference-pair-candidates.json`. GitHub Actions exports the
real Godot voxel projection for each matched model and reports
`reference ↔ reference`, `model ↔ model`, two `model ↔ own reference`
and two `model ↔ wrong reference` scores. See
`docs/graphics/reference-pair-baseline.json` for the frozen before-pass.

## Conjurer / Dominator — pre-sculpt

| Quantity | Score / 100 |
|---|---:|
| Reference silhouette similarity (rough traced quarter) | **60.2** |
| Existing game model similarity (quarter) | **67.8** |
| Conjurer vs own source | **35.8** |
| Dominator vs own source | **32.8** |
| Conjurer identity margin (own minus wrong art) | **+3.2** |
| Dominator identity margin | **−0.8** |

**Reference-driven provisional target:** Game pair similarity **52.2–68.2**,
AND aim for **+5 own-art fit improvement for each model** and a clearly
positive identity margin. The current pair score is *inside the generous
tracing uncertainty band*, so **reducing pair similarity by itself is not a
success criterion**.

Both references show broad shouldered, two-legged machines with distinct
asymmetric weapons. But the Conjurer has a **high horned helmet**, narrower
upright shoulder architecture and higher arm-mounted pulse gun. The Dominator
has a **low recessed head** under a far wider horizontal shoulder/gun deck,
long shoulder-mounted right torso ER large laser, long lower right arm PPC,
low center V chest and an independent battlefist. Prioritize these specific
differences rather than adding oversized floating slabs.

### Second trial: HawkWolf / Black Hawk Standard

The available canonical HawkWolf 3145 art shows an upright frame with huge,
downward-raked **15-tube arm racks**. Black Hawk Standard 3145 Mercenaries art
shows a deeply crouched, diagonally aimed and strongly foreshortened body
(not the Nova Omni). Those illustrations are **not pose-comparable**.
The raw rough-mask score of **38.4** vs game-model **58.1** is recorded
only as a diagnostic. The official acceptance **target remains null** until
a camera/rig matching pass or appropriately posed reference becomes available.

## Method limitations

- These are provisional outer-contour annotations from **one image per
  chassis**, neither 4-angle image validation nor pixel-perfect measured fits.
- Models currently use a neutral 3/4 projection; photo yaw, camera elevation
  and joint stance must still be registered before calling these final scores.
- The frozen before-sculpt baseline is essential: do not recalculate the
  reference target from the *new model* or chase the same model-to-model
  confusion score regardless of artwork.
- A large movement in own-art fit must be inspected for changed stance
  or foreground masking, not automatically called an art improvement.
- Do not export source copyrighted art into the Git repo. The GitHub Action
  keeps only coarsened derived contours, Godot masks and diagnostic metrics.
