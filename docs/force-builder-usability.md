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
