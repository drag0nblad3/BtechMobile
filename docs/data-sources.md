# Where the 'Mech data comes from

Tyler's rule: designs and Battle Values are official, never guessed.

- **Loadouts** (armor, equipment, slots, heat sinks, engine) are converted from
  MegaMek's unit files (the `mm-data` repository, `data/mekfiles/meks/**.mtf`).
  Each design's `source.megamek` names its file and `source.mul_id` its Master
  Unit List entry. MegaMek's data is licensed **CC BY-NC-SA 4.0**
  (attribution, non-commercial, share-alike): our converted unit files carry
  the same terms. Keep this in mind before any commercial release.
- **Battle Value** is the number printed on the free official record sheets
  (battletech.com downloads, sheets.flechs.net), recorded as
  `source.bv: "sheet"` with the sheet named in `source.sheet`. For a design
  with no free sheet, the value comes from MegaMek's own BV calculator
  (`source.bv: "megamek"`); it matched 486 of the 491 printed values we
  checked. `source.megamek_bv` keeps MegaMek's number for every design.
- **Role lines** use the Master Unit List role (in MegaMek's files) with our
  own wording, the weapons and the speed.
- **Combat vehicles** (`data/vehicles/`) come from MegaMek's `.blk` files
  (`data/mekfiles/vehicles/**`, same CC BY-NC-SA terms) with the BV printed
  on the official Battlefield Support / Mercenaries record sheets. Clan
  vehicles have no free sheet, so their BV comes from MegaMek's calculator
  (`source.bv: "megamek"`), which matches every sheet BV above.
- **Battle armor** (`data/battle_armor/`) comes from MegaMek's `.blk` files
  (`data/mekfiles/battlearmor/**`) checked against the weapons on the free
  official sheets (Mercenaries ForcePack, ForcePacks Wave One, Aces: Scouring
  Sands), with the BV printed there. Squads without a free sheet use MegaMek's
  BV calculator (`source.bv: "megamek"`), which gives the printed value for
  all seven sheet squads. The `mechanized`, `anti_mech` and `magnets` flags
  come from MegaMek's unit (canDoMechanizedBA, canMakeAntiMekAttacks, magnetic
  claws). Conventional infantry needs its own rules and isn't in the game.
- Record sheet PDFs and their text stay out of the repository (project files
  only). The converter scripts live outside the repo; to rebuild, convert the
  `.mtf` files again and look up the sheet BVs.
- Loadouts that only exist to test one rule (a TSM or supercharger refit)
  are test fixtures in `tests/fixtures/units/`, ids `test_*`, never in the
  game.

## Faction and era availability (official MUL)

The offline historical-selection snapshot is generated from the official
[Master Unit List](https://masterunitlist.battletech.com/) public static search
index and its complete faction/era availability matrix, **not** from MegaMek
file names or inferred technology periods.

Run `python3 tools/import_mul_availability.py` or the repository's
**Import canonical MUL availability** GitHub workflow to refresh
`data/forces/availability.json`. The importer checks exact name/model,
published BV, tonnage and official unit URL, respects the site's crawl delay,
and records public MUL IDs, first introduction year, faction-era cells and
snapshot date. `docs/mul-import-coverage.json` lists every unit variant still
unmatched so these cannot accidentally be treated as canon.

The November 22, 2026 snapshot verifies **674 of 697** game variants and
**41,311** positive faction-era cells for **71** factions and **12** eras.
An absent faction-era cell in a *published* matrix means unavailable;
an unmatched variant means unverified and is blocked only in Strict mode.
See `docs/era-faction-availability.md` for implementation and play rules.
