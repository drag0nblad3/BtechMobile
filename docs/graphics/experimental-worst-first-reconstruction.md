# Worst-first miniature reconstruction queue

Experimental branch only. Production geometry must not be edited or merged without explicit authorization.

## Selection
1. Load the latest per-chassis calibrated reference scores and audit notes.
2. Exclude uncalibrated views and references from mismatched sculpt generations.
3. Rank by lowest **validated** component/anatomy score; use calibrated multi-angle score only as a tie-breaker.
4. If there is no trustworthy scored inventory, mark the queue **unranked** and complete a baseline audit before claiming any chassis is worst.
5. Work on exactly one chassis at a time. Preserve a frozen before snapshot.

## Per-chassis reconstruction
- Verify multiple images depict the same current Catalyst plastic sculpt.
- Record reference URL, sculpt generation, view, camera model, focal length estimate, landmark fit error, pose, and whether the image is score-eligible.
- Compare torso, cockpit, shoulders, weapons, hips, thighs, knees, calves, feet, and distinctive structures independently.
- Resculpt incorrect parts freely. Keep successful geometry when attachment repairs are pending; reconnect and rerig afterward.
- Reject floating islands, unsupported touching-only joints, duplicate shells, filler blocks, and bloat.
- Check that distinct mechanical shapes survive voxelization.
- Run both modeling pipelines' relevant tests and Godot smoke scenes; preserve test logs.
- Render front, three-quarter, side, rear, and before/after from real model geometry.
- Commit source geometry, reference metadata, reproducible camera/pose settings, tests, and honest residual defects.

## Queue status
PRELIMINARY TRIAGE — `tools/miniature_anatomy_triage.py` ranks authored torso depth (CT/HD/LT/RT) over source-geometry height. This is a bloat proxy, not a reference fidelity score. Initial manually inspected source extents: Sagittaire 0.794, Firestarter 0.739, BattleAxe 0.515. These are only three sampled chassis; the full catalog still needs scoring. Sagittaire is first **audit candidate**, not proven worst. Its forward weapon projections must be excluded from any unjustified torso reduction. Do not change geometry until sculpt-generation verification and camera/pose calibration.

## Completion gate
A chassis is finished only after source geometry, rig attachments, voxelization, tests, and calibrated multi-view comparisons are checked. Do not merge this branch automatically.
