# Post-PR-213 BattleMech sculpt reconciliation — 22 November 2026

## Why the integration needed a second pass

PR #213 verified 151 face-connected model sculpts, but the base branch advanced
while it was in review. On merge, some older 50-pass JSON sources replaced
later 100-pass, distinct-silhouette revisions that were already passing CI.
The combined model loader also pruned unresolved small islands. That could
remove authored optical details or conceal a real defect instead of repairing it.

This follow-up is source-level visual art work, **not a rules change**.
It restores earlier verified sculpt geometry for reference-heavy critical models,
retains the distinct PR #213 proportion work on the rest, and keeps structural
integrity audits explicit. An orphaned component must be repaired at the source
or reported, not erased just to make a metric pass.

## Source-resculpt decisions

The three priority models below come from the last green 100-pass source
snapshot (commit `2779714f`) and have further edited structural contour
stations in both gameplay and low-resolution shape JSON:

| Chassis | Front / rear body-depth factors | Main changes |
|---|---|---|
| Battleaxe | 0.84 / 0.80 | Compact torso, more tapered shoulder roof; preserve single raised launcher |
| Sagittaire | 0.80 / 0.79 | Angular central beak, less continuous deep side armor; preserve paired weapon groups |
| Firestarter | 0.82 / 0.80 | Substantially thinner 35-ton armor masses, narrower forearms and shin contours, separate flamer/jump apparatus |

These factors refer only to **selected loft polygons**, not the complete
measured silhouette or the full body-plus-weapons depth. Their adjustment does
not alter pivots, official equipment, muzzle locations, variant definitions,
damage mapping, or game rules.

Reference priority is current Catalyst plastic (where available), followed by
modern art and earlier metal sculpts. Source references:
- Battleaxe: Catalyst Proliferation Cycle ForcePack,
  https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs
- Sagittaire: Catalyst Eridani Light Horse Hunter Lance,
  https://store.catalystgamelabs.com/products/battletech-eridani-light-horse-hunter-lance
- Firestarter: Inner Sphere Recon Lance,
  https://www.sarna.net/wiki/BattleTech:_Inner_Sphere_Recon_Lance

The original 100-pass shape revision and 59-chassis identity work are preserved
rather than replacing them with unreviewed mass transforms. Models with
intentional depth or atypical structure (Jenner, Locust, Raven, Hollander,
Hunchback IIC, King Crab, UrbanMech and quadrupeds) are not given a global
humanoid-proportion constraint.

## Verification gates

- Godot CI unit tests, all visual scenes and smoke checks.
- Catalog-wide 151-shape strict 3D connectivity and backed-joint audit.
- Name-blind front, side, quarter and top projection comparisons.
- Manual front and side review, with current plastic references for the most
  visually confusable silhouettes.
- No deleted islands, no synthetic cosmetics deciding rule damage, no APK.

A passing geometry audit is necessary, **not proof of reference likeness**.
Any incomplete visual or CI checks must remain explicit in the pull request.

## Follow-up P2 specialized sculpts

Twelve additional chassis received paired high/low source-geometry revisions,
without editing record sheets or muzzle positions: **Axman, Kodiak, Turkina,
Caesar, Legionnaire, Pillager, Thunder Hawk, Mauler, Stalker, Dire Wolf,
Mad Dog, and Piranha**. The adjustments use per-chassis torso, shoulder and
limb contours rather than a catalog-wide width cutoff. They retain axe blades,
claws, saucer torsos, shoulder rockets, prominent Gauss barrels, digitigrade
legs, and clustered micro-weapons as appropriate. Silhouette likeness remains
subject to render inspection; raw loft ratios are not reference-matching scores.

Reference checkpoints include Catalyst's Mad Dog Premium miniature, Clan
Command Star Dire Wolf, Clan heavy/scout plastic variants, Turkina and Kodiak
plastic poses, plus Inner Sphere Assault Lance Pillager. These are source
geometry changes, not a claim of independently verified 3D reference fitting.

## Source lineage, loft stations and integrity

The merge had replaced 100-pass shape files with earlier 50-pass versions on
51 chassis. Four compatible non-proportion signature sculpts (Havoc,
Icarus II, Scorpion and Victor) retain the previously passing 100-pass source
geometry from commit `2779714f`. Ten additional signature chassis, including
Atlas, Jenner and Wolverine, use the later structurally consolidated models
from PR #213: replacing them with their earlier disconnected detail assemblies
had reintroduced dozens of floating islands and unsupported joints.
Battleaxe and Sagittaire retain fresh source loft corrections, while the other
35 affected chassis preserve their 41-model proportion work and recover
genuine historic review provenance. Repair notes
identify those records as lineage, not proof that a new 50-cycle review ran.
Ten malformed authored loft-station sequences were corrected at their source,
in paired high/low recipes, by ensuring distinct strictly ascending stations.

The destructive tiny-orphan pruning branch is removed. Seven isolated parts
on six models were identified in the strict 151-shape audit and source-cleaned:
BattleMaster (10 cells), Fire Moth (1), Goliath (2), Gunslinger (two mirrored
single-cell chips), Shogun (1), and Thunderbolt (1), amounting to seventeen
actual authored-grid stray cells rather than any runtime masking. Larger
unresolved material must be repaired with real supporting geometry and never
hidden by silently altering the audit.

The final 100-pass source review records for Battleaxe and Sagittaire are
restored directly from the green pre-merge source, and Jenner's consolidated
head nose receives an oval leading contour with a source-profile width ratio
above the generalized front-disc test's minimum. These edits do not replace
or relax any test constraint.

**Remaining visual QA:** the earlier 41 proportions, the twelve new P2
contour revisions, and the unaffected 98 catalog chassis still require
full side/front reference comparison before the catalog can be declared
complete. The 151-model structural workflow and CI decide technical acceptance.
