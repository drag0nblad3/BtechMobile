# Reference sculpt: twenty-chassis fourth batch (23 November 2026)

Another twenty previously untreated chassis receive targeted source loft
adjustments: **Goliath, Scorpion, Rakshasa, Warlord, Chameleon, Cobra, Hornet,
Imp, Nightstar, Pillager, Salamander, Shogun, Thug, Titan, Turkina,
Executioner, Nova, Summoner, Hellbringer, and Dire Wolf**.

## Exception-specific geometry

- Goliath and Scorpion are **real four-leg designs**: the front limbs are
  articulated LA/RA legs with separate shins and feet, not arms to be cut down.
  Only slight rear carapace and side armor changes were applied, leaving
  turret and all four leg assemblies untouched. Never apply humanoid
  torso-to-leg ratios to these chassis.
- Rakshasa's CT loft runs along the Z axis. The rear hull outboard cross
  section received a small width correction; its long head, reverse-knee
  assembly and distinct rotary/pulse weapon parts were retained.
- Warlord, Cobra, Hornet, Imp, Salamander and Titan have separately authored
  gun housings. Main hull and limb envelopes were adjusted while the
  distinct housing parts remain independent.
- Nightstar, Turkina, Nova, Summoner, Hellbringer and Rakshasa retain
  digitigrade rigs and forward weapon clusters.
- Pillager and Thug were profiled as thick assault designs, not slim
  humanoids. Their excessive rear carapace was reduced but their wide
  shoulder identity is intentionally retained.
- The Dire Wolf retains its iconic broad Clan assault shoulder weapons and
  stable heavy legs rather than using the dimensions of a light recon Mech.

Where a detailed tier is a `source` alias of the authored `_shape`
recipe, only the actual source was edited; duplicating a source as a
standalone high-detail file would break the design chain.

## Check and follow-up

The new `tests/unit/test_vx_reference_batch_four.gd` asserts primary
loft parity, polygon area, quadruped limb chains, Clan reverse-jointed
gaits, and existence of independent launchers and gun housings.

Connectivity and visual likeness **still require CI plus rendered
front/side/three-quarter comparison**. This batch is a source-level
correction pass, not a claim that all art references are faithfully
matched. Reference emphasis: Catalyst modern plastic sculpts.

- [Catalyst Clan ForcePacks](https://store.catalystgamelabs.com/products/battletech-forcepack-clan)
- [BattleTech Catalyst miniature catalog](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)

No gameplay rule edits, unit JSON changes, or Android build.
