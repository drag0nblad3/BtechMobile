# Official equipment and BattleMech expansion — 2026-11-23

This batch adds **11 new BattleMech designs** and **6 weapon definitions** to
the playable record-sheet catalog. All chassis names, tonnages, armor,
placements, equipment, critical-space materials, and roles were transcribed
from the individually named **MegaMek mm-data MTF** designs. New design
Battle Values are copied from matching official
[Master Unit List](https://masterunitlist.battletech.com/) variants; the
records deliberately use `source.bv: "mul"` rather than claiming a locally
verified paper-sheet number. Each record includes its exact `source.megamek`
path, `mul_id`, and canonical `mul_url`.

| Design file | Variant | BV2 | Identity |
| --- | --- | ---: | --- |
| `fafnir_fnr5` | Fafnir FNR-5 | 2636 | IS 100t, twin Heavy Gauss |
| `huron_warrior_hurwor4l` | Huron Warrior HUR-WO-R4L | 1530 | IS 50t, ER large laser/Gauss |
| `naginata_ngc3a` | Naginata NG-C3A | 1954 | IS 95t, C3 master/triple Artemis LRM15 |
| `anubis_abs3l` | Anubis ABS-3L | 951 | IS 30t, stealth armor |
| `no_dachi_nda1k` | No-Dachi NDA-1K | 1708 | IS 70t, sword/TSM/MRMs |
| `hellstar` | Hellstar | 3084 | Clan 95t, quad ER PPC |
| `war_dog_wrdg02fc` | War Dog WR-DG-02FC | 1814 | IS 75t, two one-shot Streak SRM2s |
| `men_shen_ms1o` | Men Shen MS1-O | 1550 | IS 55t OmniMech |
| `blood_asp_prime` | Star Adder (Blood Asp) Prime | 2654 | Clan 90t OmniMech |
| `fire_falcon_prime` | Fire Falcon Prime | 1451 | Clan 25t OmniMech |
| `regent_prime` | Regent Prime | 2437 | Clan 90t OmniMech |

## New equipment

| Catalog ID | Name | Critical verified properties |
| --- | --- | --- |
| `elrm5` | Extended LRM 5 | 3 heat, 6t, 1 slot, 18 shots/t |
| `elrm10` | Extended LRM 10 | 6 heat, 8t, 4 slots, 9 shots/t |
| `elrm15` | Extended LRM 15 | 8 heat, 12t, 6 slots, 6 shots/t |
| `elrm20` | Extended LRM 20 | 10 heat, 18t, 8 slots, 4 shots/t |
| `c_enhanced_ppc` | Clan Enhanced PPC | 12 damage, 15 heat, 7t, 3 slots, range 7/14/23 |
| `streak_srm2_os` | Streak SRM 2 (OS) | 2 missiles, 2t, 1 slot; failed lock preserves its shot |

Extended LRMs **do not** reuse the existing `nlrm*` Enhanced LRMs:
they have a **minimum range of 10** and brackets **12/22/38**. Their
ammo counts and BV are from MegaMek `AmmoType.java`, launcher stats from
`ISExtendedLRM{5,10,15,20}.java`. Enhanced PPC numbers come from
`CLEnhancedPPC.java`, and Streak one-shot from `ISStreakSRM2OS.java`.
For the one-shot Streak, `WeaponFire` now clears the spent flag on a
missed lock rather than refunding a nonexistent ammo bin.

## Verification and boundaries

- Run `godot --headless --import`, then
  `godot --headless -s tests/run_tests.gd -- official_expansion`;
  also run `godot --headless -s tests/run_tests.gd -- data` and the full
  CI pipeline. Tests check all design tonnages, critical slots, ammunition,
  source identities, and one-shot Streak behavior.
- **Availability:** the existing official MUL faction-era snapshot was not
  regenerated in this PR. New designs might appear *unverified* in Strict
  historical mode until `tools/import_mul_availability.py` is refreshed.
  Do not infer eligibility from their MegaMek files or introductory era.
- **Art:** the new design files specify their chassis `sprite` identifiers,
  but **do not provide new reference-fitted voxel sculptures**. The art and
  rigging for these 11 distinct silhouettes require a separate photo-guided
  sculpt-and-connectivity pass, not generic reuse of preexisting shapes.
- No mobile APK, copyrighted source record sheets, new homebrew variants, or
  gameplay-damage alterations were produced. Only the targeted Streak OS
  shot-retention bug was fixed.
- MegaMek mm-data source terms are **CC BY-NC-SA 4.0**. Verify licensing
  before commercial distribution.
