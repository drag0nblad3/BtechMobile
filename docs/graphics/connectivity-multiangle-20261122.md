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


## Final post-refinement verification

Full Godot audit on commit `34e00d1`:

| Geometry quality gate | Before round | After round |
|---|---:|---:|
| Chassis audited | 151 | 151 |
| Parts containing disconnected voxel components | 46 | **0** |
| Parent-child joints without a 2×2, two-layer-backed solid face | 88 | **0** |

All three hero sculpts (Atlas, Jenner and Wolverine) are clean under the
same gate as the full catalog. Jenner's formerly detached forward-disc shoulder
braces were given a proper solid cross-section; a few disconnected 1–8 voxel
leftovers were explicitly removed from their source manifests. The additional
Havoc, Thunderbolt and Victor single-voxel scraps were likewise corrected
at source, rather than hidden in the validator.

The final 16 weak contacts were corrected with compact interior supports on
Archer, Awesome, Griffin, Kit Fox, Marauder, Scorpion, Shadow Hawk, Summoner,
Timber Wolf, and Warhammer. Edited shapes are copied to the matching high/low
LOD manifests. None of the 16 repairs modifies the overall weapon loadout,
combat stats, limb pivot positions, muzzle coordinates, or unit record sheet.

The Icarus II vs Starslayer blind multi-angle similarity fell from
**0.8811 to 0.7199**, while the intentionally related Katana and Crockett
still resemble one another. Spartan's dome and Katana/Crockett's prominent
missile ears now separate their visible shoulder silhouettes.

Automated safeguards: the dedicated `voxel-multiangle.yml` workflow checks
**every** edited model manifest, runs generalized topology and projection
unit tests, exports a 151-chassis blind-guess report, and fails unless **both
island-bearing part count and weak-joint count are exactly zero**. It also
exports the approved 4-angle hero render sheet. The full CI suite separately
catches game, persistence, animation and scene regressions. No APK is built.


## 2026-11-22: multi-angle sculpt differentiation, round 2

This is an **authored-geometry change**, not a colorway change or a rename.
It updates both `*_shape.json` (editable coarse sculpt) and `*.json`
(gameplay high-resolution sculpt) for four previously confusable chassis,
plus source lofts for three major showcase chassis. All geometry was
checked as *voxelized masses*, not only boxes or bounding volumes.

| Chassis | Changes for recognizability |
|---|---|
| Battleaxe | Retuned into a squarer and narrower central armored frame, a unique elevated **single** left shoulder LRM chimney, two chest launcher banks and substantial paired forward arm guns. Removed noise-like deep torso erases before rebuilding deliberate front panels. |
| Sagittaire | Substantially retapered chest waist, long **central beak** with pointed lower prow, distinct paired tall swept shoulder fins, and multiple side arm gun sponsons. The side projection no longer follows Battleaxe's flatter nose. |
| Firestarter | Leaner upper torso, low flat head, paired slim forward flamer sleeves and short vertical rear-shoulder fuel/flamer tanks. No Phoenix Hawk-style raised swept wings. |
| Phoenix Hawk | Distinct high angular head, a narrower armored chest, an asymmetric forward gun/gauntlet pair, and large backward-swept raised jump-pack winglets visible from **both front and side**. |
| Atlas | Lowered and recessed existing skull as a whole (including eye sockets and jaw); reprofiled shoulder roof to rounded, inset sections; reduced excess rear-torso shell depth. No duplicated facial or arm masses. |
| Wolverine | Moved narrow angular head down and forward; reshaped one continuous right-arm cannon without duplicate gun-box assemblies; extended single opposite gauntlet and sharpened the separate shoulder SRM housing. |
| Jenner | Resculpted the **existing** forward disk-shaped cockpit into a thinner, oval front projection (nose at z=-39 in sculpt grid), narrowed the front torso/shoulder roof, retained the paired laser hardpoints and full digitigrade lower-leg assembly. One source micro-island generated by the taper was subsequently eliminated explicitly. |

### Measured silhouette and connectivity results

The category-blind overlap test still weighs **front 55%, side 28%,
three-quarter 12%, top 5%**; it compares occupied orthographic pixels
at consistent normalized aspect ratios.

- Battleaxe/Sagittaire **0.8193 → 0.7064** after the source resculpt.
- Firestarter/Phoenix Hawk **0.8065** before; **neither is now in the
  other's top-three closest matches**.
- Atlas's nearest different chassis **0.6240 → 0.6088**;
  Wolverine **0.6457 → 0.6433** (improvement is more visible in
  recognizable weapon/head features than in total outline overlap);
  Jenner **0.5626 → 0.5669** (the narrower front disk trades a small
  increase in anonymous overlap for a more miniature-faithful shape).
- Structural quality on the final source: **151/151 chassis audited,
  zero floating islands, zero weak parent-child contacts**.
- Focused tests: **5 connectivity tests + 5 silhouette tests, all pass**;
  the standalone Godot full CI also passes on this source revision.

The new `tools/capture_silhouette_review.gd` builds a compact actual
Godot greedy-meshed voxel comparison of all **seven** candidates from
**front, side, three-quarter**, and exports
`seven_chassis_multiangle.png` next to the four-angle hero sheet and
catalog report in the geometry-workflow artifact. This should be the
starting point for the next human recognizability inspection; silhouette
overlap alone does not prove identity recognition.

### Sources and visual precedence

Current Catalyst plastic/reference sculpt imagery takes priority; front
shape first, side shape second, other angle details after gross proportions
have the right silhouette. Sources examined in this pass:

- Battleaxe, contemporary tabletop plastic photo:
  https://www.wargamesemporium.co.uk/products/battletech-battleaxe-single-mech
- Sagittaire, photographed tabletop sculpt:
  https://www.ebay.com/itm/197889190361
- Phoenix Hawk premium:
  https://battletech.com/blog/2023/10/27/now-available-battletech-adventures-ghosts-of-obeedah-corrected-rifleman-and-phoenix-hawk-premium-miniatures/
- Wolverine premium:
  https://store.catalystgamelabs.com/products/battletech-premium-miniature-wolverine
- Firestarter and Jenner: Catalyst plastic figurines from the Inner
  Sphere Recon/Striker Lance line, cross-checked with catalog references.

**Known limitations:** Battleaxe still has some box-shaped weapon panels,
the Atlas face is not yet fully indistinguishable from its plastic sculpt,
and Wolverine's asymmetric hand and gun deserve further fine-polygon work.
Strong silhouette metrics are a screening tool, not a claim that all
figures have achieved museum-grade likeness. No APK was built.
