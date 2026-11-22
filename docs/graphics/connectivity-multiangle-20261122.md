# Connectivity and multi-angle silhouette refinement — 2026-11-22

This round replaces chassis-specific geometry fixes with occupied-voxel topology,
and adds **name-blind multi-view comparisons** for the full BattleMech catalog.
It changes only view geometry and quality tooling; weapon stats, hit locations,
record sheets, muzzle metadata, articulation pivots, and gameplay rules remain
authoritative in their original systems.

## Connectivity gate

`src/view/vox/vx_connectivity.gd` treats each **face-adjacent** connected voxel
mass as a component; corner and edge touch do not connect masses. An articulated
parent/child joint is structurally sound only if it has a **2×2 face patch
backed by a second layer of occupied voxels on both sides**. One face neighbor
(or even four unrelated touch points) is insufficient.

For `exclusive_parts` sculpts, `VxModel` now tries local 2×2-supported welds:

- Components separated by five occupied-grid steps or less can be joined to
  the largest connected mass; a failed weld never becomes a new anchor.
- Parent joints can be repaired within seven steps near their authored pivot;
  the pivot itself does not count as contact or substitute for geometry.
- All prospective weld cells are checked against ownership of **every other
  part**. No new coincident voxel faces or long unsupported struts are added.
- The direct fine-loft raster path repairs after rasterization, because that
  path rebuilds its voxel grid rather than subdividing the coarse repaired one.
- Distant or obstructed defects are **reported, not hidden** by removing chunks,
  moving pivots, or closing off unrelated spaces.

`VxConnectivity.audit(model)` yields `island` and `weak_joint` findings for
any remaining defects. A repair attempt is **not** a declaration that the
complete catalog is error-free: inspect and resculpt remaining offenders in
the authored JSON with multi-angle references.

## Blind silhouette identification

`VxSilhouette` generates normalized *occupied* 2D projections, with no
textures, colors, chassis names, or unit metadata. Distinctive geometry needs
to hold up from multiple orientations:

| Projection | Weight |
|---|---:|
| Front | **55%** |
| Side | **28%** |
| Three-quarter / diagonal | 12% |
| Top | 5% |

The front-facing identification is primary; a side profile is the main
tiebreaker. The closest matches are *potentially confusable chassis*, not a
claim that either silhouette faithfully matches its real-world miniature.
Compare flagged pairs against multiple reference angles, giving extra weight
to current Catalyst plastic sculpts, before editing lofts or weapon mounts.

Particular reference-driven visual gates for the next source-geometry pass:
Atlas: recessed skull and broadly aligned round shoulder roofs without
excessive torso depth; Jenner: strongly forward, broad disc-shaped cockpit
with narrow legs and recognizable side pods; Wolverine: small angular head,
one shoulder missile rack, differentiated weapon arm and visible hand.
Do not collapse chassis into a generic armored humanoid.

## Run

```sh
godot --headless --import
godot --headless -s tests/run_tests.gd -- vx_connectivity
godot --headless -s tests/run_tests.gd -- vx_silhouette
godot --headless -s tools/voxel_multiangle_audit.gd -- /tmp/voxel_multiangle_audit.json
```

The JSON report records remaining island parts and weak joints, and the three
closest name-blind silhouette matches per chassis. Review high similarity
pairs manually, front and side first, then three-quarter and top, and rerun
the topology gate after each meaningful resculpt. Do not treat numeric
similarity as a substitute for reference matching.

### Scope / verification

Tests exercise disconnected components, a missing internal joint layer,
corner-only contact, nearby welds, unrepairable large gaps, origin-independent
contact, front-vs-side weighting, lookalike detection and real model profiles.
The repo's complete Godot CI remains the required integration check.
No Android APK is produced by these tools.


## Source geometry round: articulated-mass consolidation and lookalikes

The follow-up sculpt pass explicitly changes the authored sources, not merely the
testing criteria.

- **Atlas:** the original 73 independent pieces become 12 actual articulated
  masses. 47 non-articulating detail assemblies (including the LRM rack,
  skull/jaw, shoulder bands, knee/ankle collars, hand details, and pelvis)
  are integrated into the correct parent part. The 14 right-side mirrored
  details are inherited from their left-side counterpart. The existing
  skull recess, shoulder roof, and weapon reference silhouette are retained.
- **Jenner:** 62 pieces become 14 actual articulated masses. The distinctive
  forward disc-shaped cockpit, laser pods, feet, hock and tarsus ornaments
  are united with their owner. Preserve the digitigrade hock, ankle, and
  shoulder pivots.
- **Wolverine:** 48 pieces become 12 actual articulated masses. Its SRM
  shoulder, separate autocannon/hand assembly, angular head, jump pack,
  and leg fairings are merged without losing their front-facing contours.
- **Icarus II:** independent shoulder vent silhouettes, asymmetric right
  fist vs left cannon, and a distinct head crown, based primarily on current
  Catalyst plastic-sculpt references.
- **Starslayer:** offset raised long-range shoulder cannon, opposing SRM
  bank, and differentiated arms; primary silhouette no longer follows the
  Icarus II layout.
- **Katana / Crockett:** added their distinctive *paired elevated launcher
  ears* and matched long arm guns. These are intentionally kept closely
  related: in the fiction the Katana is an established Crockett-derived
  redesignation, **not** an unrelated chassis to force apart.
- **Spartan:** a wide rounded low-domed shoulder/roof structure and right
  arm pulse gun profile instead of Katana-style paired missile towers.

The high-detail and shape-first versions of the four revised silhouette
families are edited in tandem. No changes to weapon tables, hit locations,
movement pivots, or game rules. Characteristic features and missing mechanical
mass are repaired with source solids; the runtime connector should only
close remaining *small* breaks.

All three heroes still require post-edit auditing. A topology report compares
complete face-connected components and supported joints; its remaining
fault count, rather than the fact that repair code ran, determines which
source geometry needs another sculpt.
