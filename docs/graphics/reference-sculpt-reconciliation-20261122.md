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
