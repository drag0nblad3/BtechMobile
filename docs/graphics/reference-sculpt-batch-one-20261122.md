# Twenty-chassis geometry refinement — batch 1 (22 November 2026)

## Scope

**20 distinct BattleMechs / 40 authored source files**: paired `_shape.json`
low-poly and detailed `.json` sculpt recipes. This batch starts after #247
and is independent of the still-open #248; none of those earlier 12 chassis
are included here. No unit designs, core rules, RNG, gameplay state, or
Android APK builds are touched.

Reference priorities are front view first, then side, three-quarter and top.
The actual source change is chiefly **selective rear armor contour resculpting**,
not a final hand-approved miniature match. Each chassis has different
thresholds, different amounts of contour retreat and different components
selected for revision. No attack muzzles, weapons lists, leg pivot arrays or
joint identities were deliberately moved.

| Chassis | Targeted geometry, protected identity |
| --- | --- |
| Javelin | Compact upper torso, thin shoulder/forearm armor, preserve paired LRM weapon layout |
| Enforcer | Reduce rear shoulder and limb thickness, keep heavy right-arm autocannon and left-arm laser silhouette |
| Black Knight | Taper torso/shoulder/arm aft profiles but preserve tall armored knight and energy weapon placements |
| Vindicator | Reduce overdeep asymmetric shoulders and arms without making both arms equal |
| Quickdraw | Trimmer back/arms/shins, retain jump-capable upright body and its arm mounts |
| BattleMaster | Reduce extreme rear upper armor and arm thickness but retain iconic broad assault shoulders |
| Centurion | Taper both shoulder rears independently and arm casings, retain left shield/right AC asymmetry |
| Thunderbolt | Compact oversized rear upper armor, **leave separate elevated RT rack untouched** |
| Dragon | Reduce bulky aft shell; maintain long forward cockpit and arm geometry |
| Commando | Narrow back/shoulder/limb depth without turning light scout into heavy slab |
| Locust | Very mild aft hull/engine pod correction; preserve forward snout and digitigrade legs |
| UrbanMech | Minor aft-shell adjustments; **do not slim cylindrical torso** or hide asymmetric AC arm |
| Awesome | Reduce unnecessary rear armor, keep three PPC mount areas and broad shoulder identity |
| Stalker | Mild upper hull slimming, preserve long nose, missile pods and digitigrade support legs |
| King Crab | Very mild rear carapace reduction, retain broad shell and paired massive gun claws |
| Annihilator | Narrow excessive rear mass around cannon arms, retain four forward guns |
| Banshee | Reduce aft torso/shoulder volume, preserve strong square heavyweight outline |
| Highlander | Trim rear body and limb envelopes, preserve thick legs, high weapons and assault posture |
| Orion | Taper rear torso/shoulders while retaining bulky military torso and weapon geometry |
| Trebuchet | Slim rear frame and forearms, leave missile mouths and launcher profiles unaffected |

## Validation

Added `tests/unit/test_vx_reference_batch_one.gd` that checks low/high
primary source-loft parity, polygon nondegeneracy, loadable VxModel hit
locations, digitigrade signatures and named distinctive components. This is
additional to CI's existing 151-model connectivity and silhouette workflow.

A source edit that preserves a distinctive part's coordinates has **not**
proven the resulting arrangement visually correct or mechanically supported;
the multi-angle photo-versus-render review and actual Godot runs remain
necessary. This is a completed *source-level refinement batch*, not a
sign-off that these twenty have reached final likeness.

## Visual reference catalog

Prefer modern Catalyst ForcePacks and photos over legacy pixel artwork,
while reviewing front and three-quarter plus side where available:
- [Catalyst Inner Sphere ForcePacks](https://store.catalystgamelabs.com/products/battletech-forcepack-inner-sphere)
- [Catalyst ComStar ForcePacks — King Crab, Highlander, Black Knight](https://store.catalystgamelabs.com/products/battletech-forcepacks-comstar)
- [Catalyst BattleMech miniature catalog / variants](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs)
- [Jaded Falconer modern plastic miniature galleries](https://jadedfalconer.com/)
