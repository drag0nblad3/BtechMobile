# Final seven untouched BattleMech source silhouettes (23 November 2026)

This final **partial batch** covers seven designs left in the 281-model
source-shape catalog after thirteen twenty-chassis cohorts and twelve
earlier individually refined chassis: Von Rohrs Hebi, Werewolf,
Wolf Trap, Wyvern, Yeoman, Ymir, and Yu Huang.

Two additional catalog designs (Toro and Uziel) were under separate
reference-focused review in concurrent PRs #263 and #261; they were
intentionally **not duplicated** here.

## Profile and specific feature work

Each received selective primary source geometry tapering of unnecessarily
deep rear torso, shoulder or leg volume, with front weapons, hit locations
and articulated rig hierarchy unchanged. For existing detailed-source
aliases, only the actual `_shape.json` source was edited. Ymir has
independent detailed geometry updated in parallel.

- **Yeoman**: protect two towering asymmetric shoulder-mounted missile
  box housings, each with **25 separate muzzle positions and 25 cut-through
  source bore instructions** (50 muzzle ports altogether). Only small
  concealed rear torso and shin contours were changed.
- **Wolf Trap**: preserve distinctive upper missile-pod and arm cannon
  geometry, remove unnecessary aft bulk.
- **Von Rohrs Hebi / Werewolf**: preserve reverse-jointed gait and
  weapon origins while slimming rear upper structure.
- **Wyvern**: preserve shoulder launcher and independent arm guns.
- **Ymir**: reduce overdeep rear assault hull while retaining forward guns.
- **Yu Huang**: retain asymmetric heavy weapon layout and tall torso.

Tests: `tests/unit/test_vx_reference_final_seven.gd` checks source/detail
contracts, loft area, all animation hit locations, special weapon
placements, Yeoman's 50 muzzle ports and individual source bores.

## Signoff limitation

These are **authored contour edits**, not final multi-angle
miniature-identification approvals. Full CI, face-connected mass audit,
individual supported accessory QA, and rendered front/side/three-quarter
review against current miniatures are required before treating the models as
complete. The entire catalog has now been touched by the sculpt program or
explicitly covered in concurrent PRs, but a high-fidelity art approval
remains separate.

No official design JSON, rules engine, replay dice, or Android build changed.
