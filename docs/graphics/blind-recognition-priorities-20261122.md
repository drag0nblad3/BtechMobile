# Blind identification and collision-driven sculpt priority

**22 November 2026 · Editable voxel BattleMechs · PR #202**

## What this audit actually measures

- Render every available `*_shape.json` without displaying the name or comparing it with any reference art. Provide anonymous, shuffled front/side/three-quarter cards with a **separate answer key**.
- Analyze normalized front, side, top and three-quarter occupancy projections for **all 151 source chassis**. Compute each model's five nearest shape neighbors; see [complete machine-readable report](blind-recognition-confusion.json).
- Risk thresholds are **critical ≥0.94**, **high ≥0.90**, **review ≥0.83**. These are *silhouette similarity* thresholds, **not human identification accuracy or probabilities**. A model that is visually similar to another may still have characteristic color or detail. The opposite is also true: a silhouette can differ but still be unrecognizable in isolation.
- The comparison is deliberately scale-normalized to expose generic body templates; final judgement must also include actual relative in-game scale and real lighting.

## Initial findings and highest-priority confusion families

The initial machine screening put roughly **130 of 151** chassis in the critical/high nearest-neighbor categories. This strongly indicates template-like repetition and makes shape identity the next higher priority than microdetail or voxel count.

| Confusing models | Diagnosis | Corrective sculpt priority |
|---|---|---|
| Hel / Starslayer | Almost identical torso, legs and mirrored arm templates | **Hel signature pass committed**: pointed forward sensor nose, rear aerials, single heavy arm cannon; continue leg-shape resculpt |
| BattleAxe / Ymir | Broad dome torso and similar twin-arm silhouette | **Ymir pass committed**: divided cockpit and asymmetric right shoulder launcher; larger underlying torso/leg redesign still desirable |
| Banshee / Cyclops | Interchangeable broad assault silhouettes | **Cyclops pass committed**: large single projecting sensor eye; further review shoulder architecture and guns |
| Griffin / Thunderbolt | Similar one-shoulder launcher/arm-gun shapes | **Thunderbolt pass committed**: round missile drum and port cluster; Griffin keeps squared rack |
| Firestarter / Phoenix Hawk | Similar medium/light humanoid with generic arms | **Both updated**: Firestarter twin flamer muzzles, Phoenix Hawk tall twin rear jump nacelles |
| Black Knight / Vindicator | Similar head/torso/front outline | Requires separate reference-led resculpt, not scaled body copying |
| Icarus II / Sentinel | Near-duplicate humanoid profile | Requires dedicated source component rewrite |
| Chameleon / Lancelot | Few discriminating visual cues | Inspect reference heads and shoulder/weapon silhouettes |
| Guillotine / Thanatos | Same broad upper-body mass at game-camera scale | Enforce separate arm and shoulder weapon shapes |
| Ostwar / Shogun | Repeated tall-shoulder silhouette | Review cockpit and torso taper before fine detailing |

**Important exception:** Crockett/Katana are closely related designs in the fiction and share many legitimate visual cues. Do not artificially force two genuinely related chassis to look unrelated simply to improve a similarity score. Confirm canonical shape and variant first.

## Required sculpt workflow from now on

1. **Blind first**: show unlabeled model alone at real gameplay camera distance, plus front/side/top for diagnosis. Make a written identity guess *before* revealing the chassis or consulting references.
2. **After unveiling, compare** the physical sculpt against multiple sources, prioritizing recent Catalyst plastic minis from front, side, top and rear. Identify the signature head, body segmentation, weapon count, barrel arrangement, major pods, leg architecture and stance.
3. **Resculpt identity-bearing major components** before panel lines: replace false generic masses, do not merely add tiny greebles or patch in 1-voxel trim. Keep genuine design relatives consistent.
4. **Check for collisions** with its nearest neighbors after each resculpt, and repeat the anonymous identification exercise. No pose/lighting tricks or arbitrary antennae just to game the metric.
5. Preserve the model's official loadout and pivots; every signature addition must survive ownership, parenting, six-connected geometry and negative-space audits. A model should pass *both* a technical test and a human recognizability check.

### Useful sources

- [Catalyst miniature catalog index](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
- [BattleAxe artwork and technical background](https://www.sarna.net/wiki/Battleaxe)
- [Ymir original visual reference](https://www.sarna.net/wiki/Ymir_(BattleMech))
- [Official BattleTech tabletop and art portal](https://battletech.com/tabletop/)

This report does **not** certify all 151 chassis as visually recognizable; its explicit purpose is to expose cases that currently are not. The current 6-chassis signature pass is a first remediation batch, not the end of this audit.
