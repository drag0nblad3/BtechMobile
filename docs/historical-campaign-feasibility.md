# Historical campaigns: feasibility and source inventory

Research pass, 2026-11-25. No historical scenario is represented as exact or playable by this change.

| Candidate | Sources | Feasibility |
| --- | --- | --- |
| Galtor III, 3025 | [The Galtor Campaign](https://www.sarna.net/wiki/The_Galtor_Campaign), Historical Turning Points: Galtor | High for a ground-level adaptation; published order of battle and eight scenarios are reported. Obtain the original scenario source before transcribing details. |
| Misery | [Historical Turning Points: Misery](https://www.sarna.net/wiki/Historical_Turning_Points%3A_Misery) | High for a small Chaos Campaign arc; track and roster details still require the actual book. |
| Glengarry, 3056 | [Historical Turning Points: Glengarry](https://www.sarna.net/wiki/Historical_Turning_Points%3A_Glengarry) | High for a defensive regional campaign; obtain tracks and verify dates and participating formations. |
| Tukayyid | [Catalyst campaign book](https://store.catalystgamelabs.com/products/battletech-battle-of-tukayyid), [supplement](https://store.catalystgamelabs.com/products/battletech-battle-of-tukayyid-supplemental), [original scenario pack index](https://www.sarna.net/wiki/Tukayyid_%28scenario_pack%29) | High for sourced tactical tracks; full seven-front strategic simulation is larger and requires Clan force structures and source-specific rules. |

## Sources and evidence levels

- [Official Master Unit List help](https://battletech.com/mul-help/): faction/era eligibility, unit identity and BV; not evidence that an individual machine was present.
- [MegaMek data](https://github.com/MegaMek/mm-data): record-sheet configurations; audit exact variants and licenses, never infer named pilot assignments.
- The published scenario packs are primary sources for dates, actual combatants, deployment, terrain, victory conditions and special rules. Wiki indexes identify books but are not substitutes for the underlying scenario text.
- Separate exact (documented formation, model and deployment) from historically plausible (availability-filtered generated forces) and fictional (original missions in an era). Mark every adaptation and unresolved fact. No copied prose, art, map layout or full scenario data without appropriate permission.

## Proposed import gate

For each track record source edition/page, in-universe date, location, documented factions/formations, variant IDs and pilot evidence, map provenance, objectives, reinforcement schedule, known outcome, unsupported rule list, and fidelity label. Reject missing exact IDs in strict mode. Use existing Mission and ScenarioLoader only where they express the actual objectives; do not silently substitute annihilation. Use original maps clearly labeled approximations until published layouts can legally be used. Treat alternate player outcomes as counterfactual.

First build a small Galtor or Misery pilot after obtaining the source pack; follow with Glengarry and then a tactical Tukayyid arc. The present regional campaign uses four-unit lances, so a full Clan Star/ComStar Level II strategic campaign needs formation and campaign setup work before claiming historical accuracy.
