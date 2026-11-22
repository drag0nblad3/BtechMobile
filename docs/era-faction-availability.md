# Era and faction availability

Force creation supports **Off**, **Advisory**, and **Strict** restrictions. Both sides share an exact year and choose factions independently. The official MUL lists **71 factions across five allegiances**; all are exposed in the selector with their founded and dissolved years. A faction outside its published active years is unavailable regardless of the chosen unit.

- Off (default) preserves existing unrestricted play.
- Advisory keeps all units selectable but marks unverified or unavailable variants in the catalog, roster, and add feedback.
- Strict blocks unavailable and unverified variants and disables deployment if an existing roster conflicts. Switching era, faction, or policy does **not** erase the roster. Starter formation previews use the same validator.
- A separate **History: Verified Only** catalog toggle filters down to confirmed variants and works in any mode.

`data/forces/availability.json` stores the **exact UnitDef ID**, MUL introduction year, and selected verified faction-by-era cells. Missing variants or factions mean **unverified**, not unavailable. An explicitly recorded faction without the selected era means unavailable. Introduction year is checked within the chosen era, not only against era start.

The initial bundled snapshot deliberately covers only several verified MUL examples (Atlas AS7-D, Locust LCT-1V, Jenner JR7-D, Timber Wolf Prime) and a small group of separately verified introduction years. It is **not** a complete MUL mirror. In Strict, absent records fail closed. Expand the offline snapshot only by checking individual variant pages against the official faction/era matrix. No tech-base, chassis, or manufacturer heuristic is acceptable evidence.

Eras run from Age of War (2398) through the published ilClan timeline (3153). The year control supports individual years, including dates inside each era. Nothing here changes unit performance, Battle Value, weapons, or physical combat rules.

Sources: https://masterunitlist.battletech.com/ , https://masterunitlist.battletech.com/factions , https://battletech.com/mul-help/ , https://battletech.com/how-the-master-unit-list-organizes-its-data/

Regression tests: `tests/unit/test_era_availability.gd`.
