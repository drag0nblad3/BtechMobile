# Fifty-pass whole-catalog source refinement

Status: Art prototypes; not yet approved against physical miniature references.

**Coverage:** 151 shape-first BattleMechs and 16 vehicles/infantry/support models. Fifty review-and-edit passes are recorded per model. The source transformation is in tools/voxel_quality_50.py and is idempotent. It does not alter combat rules, unit stats, pivots, hit locations, or damage logic.

Each model rotates five times through ten areas: front silhouette, side profile, waist/chest, shoulder roof, weapon arm clearance, cockpit/head, thighs, shins/digitigrade joints, feet, and unique gun/launcher mounts. Broad carapaces and iconic cockpit heads have distinct exceptions rather than a universal shape.

**Direct signature refinement:** Atlas recessed skull; Jenner forward disc; Wolverine compact angular head; Marauder beak and upper cannon; Timber Wolf paired LRM banks; Raven and Shadow Cat forward cockpits; King Crab claw guns; Rifleman separated long barrels; Hunchback IIC twin shoulder cannon housings; Warhammer PPC barrels; Hatchetman cleaver; Locust insect cockpit.

**Checks:** tests/unit/test_vx_fifty_quality.gd requires 50 passes, matched primary low/high contours, and <=50,000 loaded voxels for each support asset. The offline local 146-mech edit audit showed no new overlap, disconnected island, or parent-contact regressions after selective rollback on 40 cases; this audit does not prove old baseline failures are fixed. At last inspection earlier CI had 66 legacy geometry failures. Full Godot CI and multi-angle Catalyst reference comparisons remain required.

No APK built and no merge requested.
