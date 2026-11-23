# Reference-informed source resculpt: fourteen other imported BattleMechs (23 November 2026)

This batch covers the 14 other chassis from the 42 imported through #242, separately from the 20 modified in merged #259 and 8 in #261.

| Chassis | Individual visual and structural decisions |
| --- | --- |
| Jinggau | Hexagonal broader cockpit canopy, central rooted sensor mast, tapered upper rear torso; keeps distinctive side weaponry |
| Kingfisher | Wider square-browed cockpit, shallow high rear torso and stout shin armor, with substantial separate arm weapon pods |
| Peacekeeper | Angular forward helmet, twin integral comms antennae and long gun arms, smaller roof and legs |
| Raptor | Needle-front cockpit and rear dorsal spine, compact missile sponsons, thin reverse-jointed calf structures |
| Rattlesnake II | Wider upright recon visor, narrow center roof and plantigrade legs, deliberately distinguishable from its predecessor |
| Rattlesnake | Original extended Jenner-derived nose, aft-sloping compact torso and birdlike reverse-jointed legs; existing hard-won head-breech repair retained |
| Shiro | Narrow tall samurai shoulder pennants **physically rooted into the upper torsos**, separate cannon and sword left untouched |
| Stealth | Sharp high central visor and outward angular shoulder panels, light jump-capable reverse limbs |
| Tempest | Canted high side collar and rear armor taper, heavy asymmetric arm weapon; head weapon mount intentionally unchanged |
| Thunder | Oversized arm autocannon and flared lower leg greaves, retaining broad torso and distinct exposed arms |
| Thunderbolt IIC | Broad head under tall independent missile pod, substantial lower greaves and narrower upper-back roof |
| Tian-zong | Deep armored central cockpit and two high shoulder gun arms, slimmer forearm cuffs and back |
| Tiburon | Compact protruding sensor nose, thin middle, long light reverse-jointed legs |
| Toro | Broad old-era visor above short box chest with side launchers and sturdy greaves |

Reference hierarchy: prioritize newer Catalyst plastics and BattleTech Technical Readout/Recognition Guide art over incidental fan alternates. Specific cross-checks: Jinggau https://www.sarna.net/wiki/Jinggau, Kingfisher https://www.sarna.net/wiki/Kingfisher, Peacekeeper https://www.sarna.net/wiki/Peacekeeper_(BattleMech), Shiro https://www.sarna.net/wiki/Shiro_(BattleMech), Raptor https://www.sarna.net/wiki/Raptor_(OmniMech), Rattlesnake https://www.sarna.net/wiki/Rattlesnake, Thunderbolt IIC https://www.sarna.net/wiki/Thunderbolt_IIC, Tempest https://www.sarna.net/wiki/Tempest, Thunder https://www.sarna.net/wiki/Thunder_(BattleMech), Stealth https://www.sarna.net/wiki/Stealth, Tian-zong https://www.sarna.net/wiki/Tian-Zong, Toro https://www.sarna.net/wiki/Toro.

**Work not yet visually approved.** These are geometry source edits, not proof of a one-to-one likeness: final front, side, rear, top and oblique mesh renders and comparisons with miniature angles are required. The original 42-chassis strong 2x2 backed joint patches from #242 remain unchanged, and no changes are made to independent weapon bore regions, muzzle coordinates, animation pivots or official record sheet assets.

The tests in `tests/unit/test_vx_reference_remaining_fourteen.gd` check low/high geometric parity, positive loft area, review labels, preserved rigs, weapons and individual Shiro sword/banner parts. Godot 4.5 full CI, multi-angle/bounded-joint review and 3x detailed connectivity audit must all pass before any merge. No APK or core rule changes.
