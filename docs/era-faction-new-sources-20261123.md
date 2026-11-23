# Additional era and faction availability sources — 2026-11-23

## Existing authoritative baseline

**Keep the official Master Unit List (MUL) snapshot as the authority for
which unit variants are fieldable**, by faction and era.
The existing `tools/import_mul_availability.py` imports MUL's public
[versioned manifest](https://masterunitlist.battletech.com/data/manifest.json)
and 12-era matrix. The current `docs/mul-import-coverage.json` records
**674/697** exact-verified unit variants, **23 unresolved variants**,
**71 factions**, and **41,311 positive faction-era cells** (snapshot 2026-11-22).
Avoid replacing published MUL negatives with heuristic or community positives.

Official primary source interfaces:
- [MUL eras](https://masterunitlist.battletech.com/eras) — formal era
  boundaries and active-faction context
- [MUL faction hubs](https://masterunitlist.battletech.com/factions/federated-suns)
  — faction-specific published unit sets, not necessarily relative frequencies
- [MUL named unit pages](https://masterunitlist.battletech.com/units/no-dachi-nda-2ko)
  — variant identity, introductory year, published faction-era matrix
- [MUL data manifest](https://masterunitlist.battletech.com/data/manifest.json)
  — **preferred machine-readable canonical** source, already imported

## Newly confirmed complementary data

| New source | Machine-readable location | Suitable use | Caveat |
| --- | --- | --- | --- |
| **MegaMek mm-data, forcegenerator** | [data/forcegenerator](https://github.com/MegaMek/mm-data/tree/main/data/forcegenerator) | Chassis **and model** rarity weights (0–10; 0 none, 10 ubiquitous, non-linear scale), keyed by faction, year and sub-command; supports weighted force composition | Community interpretation, **not** proof of official entitlement; weights can be inherited, overridden or missing |
| **MegaMek mm-data, faction definitions** | [factions.xml](https://github.com/MegaMek/mm-data/blob/main/data/forcegenerator/factions.xml) | Faction code aliases, naming, active date ranges and faction hierarchy/cross-faction mappings | Codes differ from MUL; don't auto-match by display name |
| **MegaMek mm-data, 39 historical year slices** | [3049.xml](https://github.com/MegaMek/mm-data/blob/main/data/forcegenerator/3049.xml) and [3150.xml](https://github.com/MegaMek/mm-data/blob/main/data/forcegenerator/3150.xml) among others | Interpolate or select explicit **year-specific rarity snapshots** for force suggestions, separately from legal eligibility | Some slices have scant documented data; interpolation must be recorded as approximate and never written as canonical |
| **MegaMek mm-data, published random assignment tables** | [data/rat](https://github.com/MegaMek/mm-data/tree/main/data/rat) | Independent sourcebook-linked crosschecks for historic compositions (e.g. Field Manuals, era reports) | Tables represent faction/formation distributions, not a complete unit permission matrix |
| **MegaMek RAT generator documentation** | [RAT generator API](https://megamek.org/megamek/megamek/client/ratgenerator/package-summary.html) | Verify generator semantics: faction, era, weight class, role and equipment rating | Generator outputs must retain source/seed for replay and are not BattleTech rules |
| **MegaMek Command Generator (2026-11-21)** | [developer overview](https://megamek.org/2026/11/21/Feature-Highlight-The-Command-Generator.html) | Explains chassis/model availability 0–10 and known uneven coverage | Explicitly calls data incomplete for underdocumented eras and smaller factions |

**Verified sample:** `data/forcegenerator/3049.xml` contains
`<chassis name='Marauder II' unitType='Mek'>` with chassis and
per-`<model>` `<availability>` entries, and `data/forcegenerator/factions.xml`
uses `<faction key='...'>` and `<years>` metadata. [MegaMek's generator API](https://megamek.org/megamek/megamek/common/units/ForceGeneratorAvailability.html) specifies AV 0 as none and 10 as ubiquitous, with 6 typical and a log-scale frequency relationship; do not interpret differences as linear probabilities. The source header says
**CC BY-NC-SA 4.0**; commercial distribution requires a separate licensing
review. Historical assignment tables are named for particular sourcebooks and
years. Do not call this information official MUL content.

## Suggested integration order

1. Keep the imported MUL matrix and strict/advisory/off modes unchanged.
   Rarity is a **separate, optional** dimension for the force builder.
2. Maintain a versioned mm-data commit SHA, source-year XML name, faction
   code and raw weight for each proposed rarity record.
3. Build a manually-reviewed translation between 71 MUL factions and
   mm-data faction keys/eras. Record one-to-many, name changes and extinct
   factions rather than silently collapsing them.
4. Match exact **unit model** identifiers (e.g. `MAD-4A`, not merely
   Marauder II). Prefer a model-level entry over a chassis-level entry;
   support documented inheritance/faction override rules. Missing weights
   mean *unknown rarity*, never forbidden and never zero weight by default.
5. For the **23 unmatched MUL unit variants**, the MegaMek RAT/faction
   files are worthwhile investigative leads. They must remain unverified
   for **Strict** eligibility until the MUL identity is reconciled.
6. Keep a second provenance record for sourcebook-linked RATs, with
   year/faction/context. Use RAT frequencies for optional suggestions or
   campaign flavor, never as a direct replacement for MUL legality.
7. Add tests for duplicate aliases, pre-introduction years, defunct
   factions, a chassis present without a specific model and explicit
   variant rarity overrides. Preserve deterministic seeded battle replay.

## Constraints and conclusions

- **MUL matrix:** official availability, high confidence, already implemented.
- **mm-data forcegenerator:** second confirmed *quantitative rarity* source.
- **Sourcebook-derived RATs:** useful qualitative or formation-specific
  independent crosschecks; not universally exhaustive.
- **Sarna lore and fan photos:** useful context and visual reference leads,
  not authoritative faction-era permission or 0–10 rarity weights.

This is a **source inventory and integration design**. No change to
`data/forces/availability.json`, game combat rules, roster legality or
random force generation is claimed.
