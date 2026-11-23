# BattleMech geometry batch thirteen — 20 additional silhouettes

Twenty previously untreated (in this sculpt program) chassis:
Shockwave, Shootist, Snake, Spartan, Spector, Starslayer, Striker,
SuburbanMech, Swordsman, Talon, Talos, Tarantula, Thanatos, Thorn,
Thunder Hawk, Thunder Stallion, Tsunami, Valkyrie, Venom and Verfolger.

Source geometry changes selectively reduce excessive rear torso,
shoulder, arm and lower-leg volumes with chassis-dependent taper and cutoffs.
Weapon-facing geometry and original joints/pivots are preserved.
Some detailed models are source aliases; the authored shape automatically
feeds their high-resolution counterpart without duplicating geometry files.

## Special anatomies

- **Tarantula**: true quad, not a humanoid. Preserved the long forward
  gun and all four articulated leg chains. Only mild aft carapace/shoulder
  changes were made.
- **Thunder Stallion**: true quad with long fuselage, larger aft hull.
  Preserved four articulated legs and distinctive wide body; only mild
  rear hull changes.
- **Thanatos**: kept its raised shoulder weapons and forward arm packs
  while pulling back the unnecessarily deep rear torso.
- **Thunder Hawk**: kept separate forward gun layout and tall shoulder
  silhouette, trimmed rear body profile.
- **Snake / Talon / Tsunami / Shockwave**: preserved digitigrade gait and
  slender scout limb geometry.

## Tests and qualification

`tests/unit/test_vx_reference_batch_thirteen.gd` checks valid loft
cross-sections, rig inventory, source alias resolution, digitigrade
signature, and all four leg chains for both quads.
Also run repository-wide connectivity/silhouette and Godot CI.

The sculpt work is source-level and does not prove completed Catalyst
plastic-miniature likeness; additional rendered multi-angle comparisons
and resculpting of inaccurate components remain essential.

References considered: modern Catalyst miniature catalog and the
Tarantula quad Technical Readout images. No core rules, equipment
loadouts, seeded dice, or Android APK build changed.
