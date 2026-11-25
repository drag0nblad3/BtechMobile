# Held source sculpt repairs and divergent candidates

All fifteen held candidates were replayed from the pinned experimental source
and passed the independent strict neutral source-cell audit: no physical
islands, no part-local islands, no weak explicit parent interfaces, and all
89 modeled axial weapon points clear. See
`held-sculpt-repair-20261124.json` for exact per-model results and operations.

Nine repaired candidates are now installed in both production quality tiers
(eight transferred, one source-linked). Six repaired candidates with
independently authored conflicting high-tier geometry are archived in
`experiments/divergent_mech_review_20261124` alongside the original fourteen
competing candidates. The user selected A for all twenty; retain the original matching production pairs.
The B candidates are archival only (selection merged in PR #324). No tier-pair tests are weakened.

Comparison captures use actual Godot VxPart meshes with identical orthographic
camera, lighting, world scale and neutral pose per pair, with front,
three-quarter, side, rear and top views. A is the existing detailed recipe;
B is the separately archived shape rebuilt at the same subdivision multiplier
without importing incompatible high-resolution edits. This is a visual
comparison, not a photographic validation. The four initial render artifact
sets are from run 45511869607. The six additional candidates are captured
by the branch render workflow.

Source-only diagnostics are not proof of fine-raster, animation, or reference
fidelity. No unit designs, rules, or APK changed.
