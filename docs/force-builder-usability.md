# Force builder usability pass

**Implementation:** `chatgpt/force-builder-ux-20261122`, based on the
visual polish branch (#197). The game rules and saved battle formats do not change.

## User flow

1. Search by chassis, model, role, weapon or name; switch between 'Mechs,
   vehicles, battle armor and support. The tech filter remains available.
   The list shows twelve entries at a time, with an explicit **Show more**.
2. Choose **Add to Red** or **Add to Blue** above the roster. Each catalog card
   shows the *incremental* BV cost for that side, including skill and any C3
   effects, and disables Add with an explanation when illegal.
3. Watch both rosters, their slots, BV consumption and remaining BV at once.
   Remove buttons are separate from unit names to avoid accidental removal.
4. Set the map, per-side BV cap, mission and player assignment. Open
   **Advanced options** only for pilot skills, environment, withdrawal,
   hidden units, initiative and explanation settings.
5. **Start Battle** remains visible below the scrolling content; it is only
   enabled if both sides contain units and neither exceeds the BV cap.

## Design decisions and guardrails

- No invented refits or new loadouts; catalog entries use the existing UnitDb.
- Underlying ForceBuilder.cant_add, build and BattleValue are authoritative.
- The search uses word matching and category limits; no global giant Control
  tree is constructed on entry. OmniMech configurations can still be cycled.
- Persisted settings and save/replay/training entry points remain accessible.
- Category and search result counts make hidden entries discoverable.
- All changes are in the view layer, aside from CI and documentation.

## Verification

- `godot --headless --import`
- `godot --headless -s tests/run_tests.gd -- force_catalog_query`
- `godot --headless -s tools/force_builder_smoke.gd`
- Full tests and existing launcher and battle UI smoke in CI.
- On Android, verify 1280×720 and notched landscape, tap targets, virtual
  keyboard, fast scrolling, the advanced panel, and Start Battle visibility.
- No APK build unless requested.

## Curated starter formations

Starter formations are optional and loaded from
`data/forces/starter_formations.json`: Recon Patrol, Fast Strike,
Medium Maneuver, Fire Support, Clan Recon Star and Clan Spearhead Star.
Each lists only existing official unit IDs; Clan entries use five
distinct designs, while Inner Sphere lances use four.

Each roster has a **Load Starter Force** menu. Preflight honors pilot
skill, variant-specific BV and `ForceBuilder.cant_add`. Existing units
are replaced *only on that side*. If the required tier is above the
current global BV limit, the confirmation explicitly says both sides'
limit will increase. A failed validation never alters either roster.

## More formations at common game sizes (November 2026)

The curated list now contains **32** formations, organized into the app's
seven BV tiers: **2,000, 3,000, 4,500, 6,000, 8,000, 10,000, 12,000**.
The existing six choices remain. The 26 additions cover reconnaissance,
urban defense, raiding, maneuver, close combat, missile support, and heavy
assault. Clan stars start at 4,500 BV and become the dominant formation type
at 10,000–12,000 BV, where expensive OmniMechs can be fielded.

The roster's **Load Formation** menu has a tier submenu, rather than a long
flat list. Each entry shows its actual cost at the currently selected pilot
skill; the advertised tier is a 4/5 regular-pilot recommendation, not a
locked cost. Selecting a veteran pilot can require raising the BV tier or
make the heaviest star unavailable under the 12,000 BV cap. All preflight
checks preserve rosters on failure. No official unit specification, BV,
model or battle rules were altered apart from expanding the optional
per-side budget selector with 10k and 12k choices.
