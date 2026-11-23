# Reference-led launcher and silhouette pass — 23 November 2026

This change follows the 151-sculpt integrity reconciliation in PR #243. It addresses
specific omissions in the source shape-study tier and reduces unsupported **mass**,
not merely the render scale. Both source recipes are edited for new parts and
proportion corrections. All changes are cosmetic and preserve the record sheet,
weapon mount locations, articulated joint identities, and combat RNG.

| Chassis | Source-level sculpture decision |
|---|---|
| Timber Wolf (Mad Cat) | Shape study now carries 20 separate bores on each raised LRM-20 pod, plus the 40 muzzle points already present on the detailed model. No second pod layer. |
| Archer | Shape study now preserves both 20-tube torso launchers; the detailed recipe's separate open hatches and launcher mounts remain intact. |
| Warhammer | Move the existing six-port RT SRM rack from a painted torso overlay into a child component. Apply the exact backed pod and six physical cavities to the shape study; keep PPC cannon arms as they were. |
| Shadow Hawk | Add two **slim** mirrored rear shoulder fins as parented parts, to distinguish the high shoulder silhouette without expanding the torso into large slabs. |
| Phoenix Hawk | Trim upper central and shoulder *rear* contours, retaining thin limbs, pronounced cockpit and the separate tall paired jump apparatus. |
| Marauder | Reduce excessive aft torso and shoulder depth, deliberately preserve the projecting low cockpit prow, dorsal cannon, and paired PPC arms. |

Checks to run on the PR: the full Godot suite; both quality tiers of the
151-model connectivity audit; front, side, three-quarter and top profiles;
and the source-level port/backed-component tests in
`tests/unit/test_vx_sculpt_ports.gd`. A passing audit alone is **not**
a claim that the models have attained final miniature likeness. No APK.

### Visual references

- [Catalyst Phoenix Hawk Premium Miniature](https://store.catalystgamelabs.com/products/battletech-phoenix-hawk-premium-miniature): dynamic three-quarter silhouette, rear jet pack and slim limb proportions
- [Catalyst Kell Hounds Striker Lance](https://store.catalystgamelabs.com/products/battletech-kell-hounds-striker-lance): Griffin forward launcher and separate gun arm, useful as comparison when inspecting the revised medium chassis
- [CGL Timber Wolf sculpt catalog](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs): distinctive paired tall missile shoulders and forward cockpit
- [CGL Inner Sphere Battle Lance](https://www.sarna.net/wiki/BattleTech:_Inner_Sphere_Battle_Lance): Warhammer shoulder weapon asymmetry
- [Shadow Hawk miniature gallery](https://jadedfalconer.com/Pages/2Medium/Shadow%20Hawk): tall shoulder outlines versus narrow body
- [Archer ARC-2R equipment and missile layout](https://mech.guide/units/archer-arc-2r): two 20-tube LRM racks, not generic solid shoulder boxes

These references guide geometry decisions; automated silhouette similarity
remains only diagnostic and cannot independently verify photo matching.
