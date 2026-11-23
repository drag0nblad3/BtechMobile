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

The legacy one-off `voxel-quality-50.yml`, `voxel-second-fifty.yml`,
and `voxel-critical-refinement.yml` workflows were retired. They were
hard-wired to historical branches and one required exactly 151 models,
though the catalog now contains more. Their Python sculpt tools remain
available for separate, reviewed changes. `mul-collect.yml` and
`voxel-blind-identity.yml` remain manual-only, read-only diagnostics with
downloadable report artifacts. Matching copies on the original feature
branches were also disabled/removed so those branches cannot revive the
auto-commit workflows simply by receiving a new push.

## Consolidated voxel cohort tests

Thirteen numbered `tests/unit/test_vx_reference_batch_*.gd` suites have
been replaced by:

- `tests/fixtures/voxel_reference_cohorts.json` — the exact 260 unique
  historical chassis and their paired-resolution, sculpt area and rig contracts
- `tests/unit/test_vx_reference_catalog_profiles.gd` — shared coverage for
  source/detail parity, finite lofts, articulations, muzzle parity and the
  cohorts that require actual VxModel hit-location loading
- `tests/unit/test_vx_reference_signatures.gd` — specific gait, weapon,
  shell, alias and quadruped invariants
- `tests/unit/test_vx_reference_anatomy_spotchecks.gd` — Atlas fist
  volumes and physically backed Jenner head connection

These are **tests**, not automatic resculpt steps. Existing broader catalog
checks in `test_vx_catalog.gd` and `test_vx_integrity.gd` remain.


## Test cleanup guidelines

1. Retain deterministic combat rules, save/restore/replay, AI, equipment,
   faction/era, connectivity, and gameplay UI regression assertions.
2. Keep catalog-driven loft/rig assertions in the cohort manifest and
   preserve unusual weapon, silhouette and articulation checks as focused
   signature tests rather than adding another 20-chassis copy of the same code.
3. Run expensive graphical comparisons on demand; save artifacts rather than
   auto-committing generated images from CI. A pass/fail gate must be
   deterministic and independent of an external photo host.
4. Check required GitHub status checks before deleting or renaming jobs. A
   removed required check can otherwise block merges indefinitely.
5. For a new workflow, prefer `workflow_dispatch` unless it catches a
   regression not covered by these existing automated gates. Avoid
   branch-name-specific triggers that outlive the feature branch.
