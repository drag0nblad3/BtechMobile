# Targeted reference recovery — 23 November 2026

This pass checked the **12 previously source-less BattleMech visual recipes**
plus the **Tsunami** source whose original segmentation failed.
The [reproducible discovery and Godot camera-scoring workflow](https://github.com/drag0nblad3/BtechMobile/actions/runs/45179562210)
found **11 named source-gallery images** and scored **10**.
The `Nova T` *family-only* image was rejected for background/ink
coverage of **77.2%**. The remaining two Rattlesnakes have promising
exact-chassis artwork pages, but no reliable source image ingestion yet.
All numerical scores are **provisional camera candidates, not approved
shape-fidelity or matched-pose judgments**.

The exact discovered and tested gallery thumbnail URLs are versioned as
[newly-found-visual-references-20261123.json](newly-found-visual-references-20261123.json).
Only URLs, provenance and metrics are committed; copyrighted art remains
at its original hosts.

| Visual recipe | Actual source image / scope | Camera-fit exploratory score / 100 | Qualification |
| --- | --- | ---: | --- |
| `hatamoto_hi` | Games Unplugged #28 `HTM-27U` | 44.8 | Exact variant name and published illustration |
| `hatamoto_kaze` | Games Unplugged #28 `HTM-27V` | 43.0 | Exact variant |
| `hatamoto_ku` | `HTM-27W2` XTRO | 41.5 | Same chassis, **not** in-game `HTM-27W` |
| `hatamoto_mizo` | Games Unplugged #28 `HTM-27Y` | 45.1 | Exact variant |
| `hel` | `Hel_Shrapnel010.jpg` from the Eris page | 44.9 | Hel HL-1 (not Loki Mk II) |
| `hermes_iii` | Shrapnel #23 Hermes III `HER-6K` | 44.8 | Sibling, **not** in-game `HER-4K` |
| `nova_t` | Recognition Guide: ilClan Nova | — | Family only, **rejected** background segmentation (0.772 coverage) |
| `suburbanmech` | Recognition Guide: ilClan UrbanMech | 43.1 | Identical visual chassis, not exact equipment |
| `titan` | `TIT-1A` art from BattleTechnology #11 | 42.4 | **Apocryphal** historical image, not canonical variant match |
| `von_rohrs_hebi` | Original `Von_Rohrs.jpg` | 45.2 | Exact chassis, verify variant weapon placements |
| `tsunami` | **Original TS-P1** Record Sheets: 3055Uu image | **47.0** | Exact variant; replacement mask passes segmentation (foreground 45.2%) |
| `rattlesnake` | [Rattlesnake JR7-31 indexed line art](https://mech.guide/chassis/rattlesnake) | — | Chassis-labeled line-art page discovered, direct image not ingestion-verified |
| `rattlesnake_ii` | [Rattlesnake II RSN-1 indexed line art](https://mech.guide/chassis/rattlesnake-ii) | — | Exact model title on artwork page, direct image not ingestion-verified |

## Required manual checks before approval

- Confirm illustration generation, body segmentation and **limb-joint stance**.
  Camera-grid optimization alone is no substitute for an actual image-angle
  match. Do not inflate fit for a reference without modern plastic.
- Prioritize an exact `Hatamoto-Ku HTM-27W`, `Hermes III HER-4K`,
  `Nova T`, and `SuburbanMech` variant art where it exists.
- Seek a modern/suitable canonical Titan TI-1A image, not a Titan II.
- For the Rattlesnakes, `mech.guide` attributes line art to
  Topps / Catalyst but its downloadable image must be checked
  independently before being added to the automated image scorer.
- Use a tighter, **manually approved** silhouette background crop on the
  Nova reference rather than accepting failed segmentation thresholds.
- Retain the original Tsunami art as an alternative source for differing
  angles, but the replacement TS-P1 is the stronger basis for primary
  comparison.

No gameplay model, current canonical MUL eligibility, combat rules,
reference photo file, or approved multi-angle score was changed.
