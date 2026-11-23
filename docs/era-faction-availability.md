# Era and faction availability

The force builder supports **Off**, **Advisory**, and **Strict** historical availability restrictions. Each side chooses a faction; both share a scenario year. These settings affect roster eligibility, not combat statistics or BV.

- **Off (default):** unrestricted force construction.
- **Advisory:** display unavailable/unverified reasons while allowing additions and deployment.
- **Strict:** block unavailable and unverified variants and prevent deployment until already-built forces comply. Switching years, factions, or policies never silently removes units. Starter formation previews use the same validation.
- **History: Verified Only:** a separate catalog filter shows designs the chosen faction may field in the selected era.

## Official MUL snapshot — 2026-11-22

A reproducible import from the official **Master Unit List** static search index and complete availability matrix is included in `data/forces/availability.json`. The source is the public `https://masterunitlist.battletech.com/data/manifest.json` plus its versioned `units`, `availability`, `factions`, and `eras` files. Source units are matched to individual game variants using exact name/model (including uniquely recognized aliases), tonnage, BV, and canonical unit-page URLs. No chassis or technology heuristics are permitted.

The current snapshot contains:

- **697** game variants in the source catalog.
- **674** exact-matched MUL unit variants (**96.7%** coverage), each with verified introduction year and a published faction/era matrix.
- **41,311** positive faction/era cells across those units.
- **71** official factions and **12** eras, and faction founding/dissolution dates.
- **23** unmatched variants, primarily special or unusual named configurations, held out as **unverified** rather than assigned guessed availability. See `docs/mul-import-coverage.json` for a variant-by-variant audit.

A record with `matrix_status: "published"` is a **complete** official matrix. Factions appearing in `factions` have positive era marks; all other valid factions or eras are conclusively **unavailable** for that variant. To keep this Android-friendly, published matrices are stored **sparsely**, omitting negative faction rows. A missing variant or a record whose matrix is not published is **unverified**. The exact `intro_year` prevents a design being fielded before its first year, even inside its introductory era. Unknown factions are unverified, while factions outside known dates are unavailable.

Each imported variant records its game's unit ID, public MUL unit UID, original numerical MUL ID when present, canonical URL, verification date, introduction year, and positive faction/era cells. The rule engine caches this immutable snapshot to avoid decoding the large JSON repeatedly when evaluating starter formations.

## Refresh

Run `python3 tools/import_mul_availability.py` from the repository root in an environment with access to the official site, or dispatch the GitHub Actions workflow `Import canonical MUL availability`. The importer respects the site's `robots.txt` and its **10-second crawl delay**, validates the public index and 71-faction/12-era vocabulary, compares existing page-verified records for contradictions, and fails on insufficient coverage rather than overwriting good data with a partial result. The workflow commits the refreshed data and coverage report to its feature branch. Manually review unmatched variants against canonical record sheets and MUL before adding mappings.

## References and tests

- Official MUL: https://masterunitlist.battletech.com/
- Public manifest: https://masterunitlist.battletech.com/data/manifest.json
- Faction list: https://masterunitlist.battletech.com/factions
- Official MUL help: https://battletech.com/mul-help/
- Regression tests: `tests/unit/test_era_availability.gd`
- Importer and audit: `tools/import_mul_availability.py`, `docs/mul-import-coverage.json`

Eras cover the site's published Age of War through ilClan period. The source's Alpha Strike stats are not used to change Classic BattleTech unit loadouts, BV, or combat behavior.
