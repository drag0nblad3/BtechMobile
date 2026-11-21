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
- Record sheet PDFs and their text stay out of the repository (project files
  only). The converter scripts live outside the repo; to rebuild, convert the
  `.mtf` files again and look up the sheet BVs.
- Loadouts that only exist to test one rule (a TSM or supercharger refit)
  are test fixtures in `tests/fixtures/units/`, ids `test_*`, never in the
  game.
