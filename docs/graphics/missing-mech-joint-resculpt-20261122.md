# Missing BattleMech joint resculpt — 22 November 2026

This integrates the **42 previously missing BattleMechs** from #192/#242 into current `main` while keeping its newer model catalog and physics-independent battle visuals. All 84 coarse/detail source files are retained as unique models; none of the 29 support vehicle/battle-armor files already integrated in #249 are reintroduced.

## Repair method

Original multi-angle CI reported **203 weak load-bearing contacts** in 42 Mechs after its legacy automatic repairs, despite zero part islands. The source sculpts were checked with a conservative occupancy-grid tool (`tools/qa/missing_mech_socket_repair.js`). It seeks minimum-cost **2×2 backed contact patches with depth on both sides** at real original mass near a parent/child seam. Repairs are inserted as local structure-material boxes *before subtractive bores*, not by moving animation pivots, extending whole torso cross-sections, scaling body parts, or filling missile apertures. The offline method additionally rejects collisions with other owners and protects every original erase region and muzzle neighborhood. Coarse and detailed source files receive identical corrected load-bearing geometry. 

The complete cohort received **348 individual local attachment edits** (a provisional source-grid estimate covering all contacts that required correction before the existing automatic repairs) for approximately **2,358 additional coarse voxel cells**, about 1–4% of each sculpt, without expanding whole bodies. The Rattlesnake needed a hand-targeted head-neck solution: recess the rear of its head weapon housing just enough to create a compact structural neck; the forward muzzle and authored holes were retained.

These are **engineering fixes, not approval of reference resemblance**. They do not claim that all 42 silhouettes match Catalyst's miniatures. Front, side, oblique, top and rear comparison, and distinguishing the closely related chassis from one another, remain necessary art review. The geometry process records source grid behavior, and the Godot `VxConnectivity` and `VxIntegrity` validators remain authoritative.

## Merge gates

- Full Godot 4.5 CI and headless battle UI/sculpt smoke checks must pass.
- Run `tests/unit/test_vx_imported_joint_sockets.gd`, plus multi-angle and catalog connectivity workflows; do not relax their 2×2, backed-depth or no-islands requirements.
- Review any changes to silhouettes/weapon interiors, including on 3× detail meshes; repair actual bodies rather than adding big blocks.
- No rules, design records, damage decisions or combat RNG changed. No APK build.

The source generator's 50 automated edit cycles are not separate artistic approvals.
