# CI and test ownership

This document records which checks are merge gates and which are opt-in evidence
generators. The intent is to keep game-rule regressions protected without
starting full-screen render farms or online reference scraping for routine PRs.

## Automated checks

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `ci.yml` | Pull requests, pushes to `main`, manual | Complete Godot unit suite, offline Python tools unit tests, save/replay and Academy smokes, battle/UI/menu smokes, voxel benchmarks, scene import |
| `voxel-integrity.yml` | PRs touching voxel geometry/rig code, manual | Shape and fine-resolution full-catalog connectivity checks |
| `voxel-multiangle.yml` | PRs touching voxel geometry/rig code, manual | Geometry and silhouette unit tests plus whole-catalog island, joint, and angle audit |

The full Godot suite loads every `tests/unit/test_*.gd` and invokes all
`test_*` methods, so rerunning single unit-test groups **after** the full suite
is not independent coverage. `battle_save` remains as an early targeted check
for faster persistence feedback. Python test discovery covers every
`tests/tools/test_*.py`, including the photo-score and reference provenance
tests, without fetching external images.

## Manual evidence and special-purpose tools

- `android.yml` — manual APK export only (never run in ordinary CI).
- `melee-resculpt.yml` — manual targeted melee regression and Godot screenshot
  artifact. It does not rerun the complete unit/UI suites or commit PNGs.
- `preview-full-loft-voxels.yml`, `voxel-reference-catalog-batches.yml` —
  manual visual/model reference evidence.
- `voxel-missing-references.yml`, `voxel-photo-sculpt-delta.yml`,
  `voxel-reference-pair-targets.yml`, `voxel-reference-scoring.yml`,
  `voxel-sarna-remaining.yml`, and `voxel-tro-art-batches.yml` — manual,
  potentially expensive reference-image/camera sweeps. Their offline Python
  assertions still run in CI.
- `voxel-multiangle.yml` retains four render-review operations on **manual**
  runs; its geometry audit stays automatic.

The older `mul-collect.yml`, `voxel-quality-50.yml`,
`voxel-second-fifty.yml`, `voxel-critical-refinement.yml`, and
`voxel-blind-identity.yml` are branch-scoped workflows that may **write
source files**. They are not general-purpose PR merge gates. Review their
destination branches before dispatching or retiring them; deleting a workflow
from `main` does not remove the copy on an old feature branch.

## Test cleanup guidelines

1. Retain deterministic combat rules, save/restore/replay, AI, equipment,
   faction/era, connectivity, and gameplay UI regression assertions.
2. Prefer catalog-driven tests over one new copy of the same loft/rig checks
   per modeling batch. Existing `test_vx_reference_batch_*.gd` files also
   encode batch-specific chassis, weapon and gait expectations: migrate those
   assertions first, then remove redundant boilerplate, not whole cohorts.
3. Run expensive graphical comparisons on demand; save artifacts rather than
   auto-committing generated images from CI. A pass/fail gate must be
   deterministic and independent of an external photo host.
4. Check required GitHub status checks before deleting or renaming jobs. A
   removed required check can otherwise block merges indefinitely.
5. For a new workflow, prefer `workflow_dispatch` unless it catches a
   regression not covered by these existing automated gates. Avoid
   branch-name-specific triggers that outlive the feature branch.
