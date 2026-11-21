# Battle saves and replays

**Status:** implemented on the save/replay feature branch, pending Godot CI and Android device verification.

## User flow

- **Save** in the battle HUD writes a single quick-save slot.
- Every new turn automatically saves once the next active side is ready.
- Android app pause triggers another save. **Continue saved battle** appears on the force-builder screen for a nonfinished save.
- **Replay** in battle writes a separate replay file and opens a read-only tactical timeline.
- A completed battle archives the most recent replay, available from **Watch last replay** in the force builder.
- The viewer supports first/previous/play/pause/next/last, with camera pan, zoom, orbit and tilt. **Exit** returns to the force builder.

Replays show captured battle state at major events (movement, damage, attacks, phase changes and game over). They are a **state-by-state tactical replay**, not video, smooth movie capture or command re-simulation.

## Files

| File | Purpose |
|---|---|
| src/core/state/battle_fields.gd | Explicit allowlist of serializable rule objects and fields |
| src/core/state/battle_codec.gd | Typed Variant conversion: integer hex coordinates and dictionary keys preserved |
| src/core/state/battle_save.gd | Versioned, compressed single-slot persistence and RNG restoration |
| src/core/state/battle_recorder.gd | Significant GameEvent types and state snapshots |
| src/view/battle/replay_scene.gd | Read-only scene showing each recorded state |
| scenes/battle_replay.tscn | Replay scene entry |
| tests/unit/test_battle_save.gd | Record-sheet, map, mission, dice and replay round-trips |

Saves are in the application's private Godot user:// directory:
battle_autosave.zst and last_battle_replay.zst. The replay is independent of the quick-save slot.

## Format and compatibility

The compressed payload contains JSON, schema 1. A live save stores the complete
GameState and nested Unit, MissionState and BattleMap objects, pending declarations,
the controller event history, **both** RandomNumberGenerator.seed and
RandomNumberGenerator.state as decimal strings, bot side assignments and skill,
training index and tutorial path, and replay frames recorded so far.

Static UnitDef, WeaponDef, TerrainType and BuildingType objects are stored as
catalog IDs. Loading requires compatible catalog data; the codec never
instantiates an arbitrary class from the file. Unsupported schema versions
are rejected. Files are written to a temporary path and then renamed.

Replays contain snapshots rather than re-running controller commands, AI
decisions or dice. The replay player never creates a GameController.
Rewinding never changes the live battle and consumes no gameplay randomness.

## Invariants and limitations

1. The authoritative battle remains in src/core and is mutated only by
   GameController and its existing rule helpers. Replay cannot change combat.
2. A save includes pending declared attacks, turn-order cursor, objectives,
   map fire and building state and every record-sheet field—not just armor.
3. Saving at the active-side boundary supports mid-phase continuation. The
   temporary selection and camera angle are not retained on resume.
4. Replay frames cover significant events. Missile trails, debris and
   intermediate animation frames are not stored.
5. Tutorial popup progress is not saved separately; lesson cards may repeat
   after resuming a training battle.
6. One save slot and one replay archive are supported. Snapshots are not
   size capped; long battles may consume significant storage. A future
   optimization is delta snapshots and a configurable storage budget.
7. **Pending verification:** unit tests, headless UI smoke, Android
   pause/resume, and performance on long high-unit-count battles.

## Testing

    godot --headless --import
    godot --headless -s tests/run_tests.gd -- battle_save
    godot --headless -s tests/run_tests.gd
    godot --headless -s tools/ui_smoke.gd

Then start a battle, save during a Weapon Attack phase with declarations
pending, quit and continue. Compare the record sheet and subsequent dice roll
against uninterrupted play. Play the replay backward and forward and verify
that neither changes the live save. On Android, background the app,
terminate it, and confirm that Continue restores the active turn.
