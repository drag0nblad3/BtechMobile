# Camera-aware reference resculpt cycle 1 — 23 November 2026

This is an **authored source-geometry** pass on six high-priority BattleMechs, not a
camera/pose score optimization or a generic silhouette scale pass. It uses
the exploratory CGL plastic-photo reports and camera hypotheses from
[reference audit PR #268](https://github.com/drag0nblad3/BtechMobile/pull/268)
and `docs/graphics/plastic-reference-refined-158.csv` on that branch.
Reference source masks, lens, base cropping and actual joint pose are **not
visually approved**. Treat both the score and camera angles below as triage,
not a verified front view or proof of an improvement.

For each sculpt the main loft was changed with **height-specific contour
decisions**, protecting the inward side of shoulder/arm attachment masses
and the forward-facing weapon geometry. The nonuniform rear truncation trims
excess bulk from behind; no boxes, bores, joints, pivots, muzzle points,
hit locations, or original weapons were moved or deleted. Mirrored limbs
inherit the same edited geometry. Both editable low and detailed source tiers
receive identical main loft contours.

| Chassis | Prior exploratory photo fit | Best candidate yaw / pitch | Regional diagnostic | Geometry decision | Mean modified contour-area reduction by part |
|---|---:|---|---|---|---|
| blackjack | 34.2 (unverified) | 0°, -12° (provisional) | arm cannon / shoulder projection | narrow outer shoulder and gun-arm armor, remove rear torso bulk without shifting paired cannon axes | ct 4%; lt 11%; la 7% |
| crusader | 37.7 (unverified) | 15°, -12° (provisional) | torso / cannon-arm envelope | taper shoulder transition and deep rear armor, retain two physical forearm missile launchers | ct 5%; lt 9%; la 5% |
| rifleman | 40.3 (unverified) | 15°, -12° (provisional) | torso / cannon-arm envelope | remove aft gun-arm and shoulder armor bulk, keep wide articulated arm pivots and four barrels | ct 7%; lt 7%; la 7% |
| phoenix hawk | 37.9 (unverified) | 0°, -12° (provisional) | hip / leg assembly | thin thigh and shin armor around existing joints; preserve separated tall jet housings | ct 4%; ll 7%; ll_shin 9% |
| trebuchet | 40.2 (unverified) | 15°, 0° (provisional) | upper frame / missile shoulders | taper outer shoulder and chest armor, retain asymmetrical launcher and cannon ports | ct 5%; lt 9%; la 5% |
| locust | 38.4 (unverified) | -15°, 12° (provisional) | upper frame / shoulder racks | thin projecting upper armor while preserving pointed cockpit and reverse-jointed legs | ct 8%; lt 12%; la 4% |

The reported contour-area change is a **planar source cross-section**
measurement, *not* total voxel-count change, source-photo similarity gain,
or a measured connectivity improvement.

## Protections and next checks

- Preserve each named part, source/detailed rig, mirrored limbs, material
  roles, parent and joint hierarchy, weapon metadata, muzzle points and
  launch apertures. The scripted source edit checks these invariants.
- The new paired-source Godot test checks that corresponding lofts remain
  identical, all newly altered sections are nondegenerate and consistently
  wound, and every animated record-sheet hit location remains present.
- **Still required:** Godot headless full suite + voxel connectivity checks,
  multi-angle overlay with independently verified reference masks, physical
  backed-contact testing, open-muzzle inspection, and phone-size preview.
  Do **not** fill verified angle/overall score fields yet.
- No game rules or `data/units/*.json` changed. No APK and no unsolicited
  render.

## Next camera-informed priority
After pose/camera sweep QA, remeasure the same six, inspect front/side/quarter/top
overlays against alternative Catalyst views, and resculpt only residual
disagreements. The lowest exploratory scores with best yaw at the boundary
(Hatchetman, Kodiak, Valkyrie) and detached-foreground Rakshasa source
are explicitly deferred until camera range and segmentation are reviewed.
