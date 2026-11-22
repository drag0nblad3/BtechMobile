# Architecture

```
 input (touch/mouse) ─► TouchGestures ─► battle_scene ─► MovementInput ─┐
                                                                        │ submit_move()
 HUD buttons ───────────────────────────────────────────────────────────┤
                                                                        ▼
                          GameController ──mutates──► GameState (map, units, turn, phase)
                                 │ emits GameEvent
                                 ▼
             battle_scene._on_event ─► UnitsLayer / HUD / (log, sound later)
```

## Why this split
- **Rules are testable without the engine running a scene.** Everything in `src/core` runs
  under `godot --headless -s tests/run_tests.gd` in under a second.
- **AI uses the same controller actions as the UI.** The live save contains an allowlisted snapshot of all rules state and the exact RNG seed **and state**, not just the original scenario seed. Replays are read-only snapshots captured at significant `GameEvent`s; they do not re-run AI or rules. See `battle-save-replay.md`.
- **Campaign layer stays separate.** A future `src/campaign/` will build `GameState` from
  campaign data and read results back from it; the battle code doesn't need to know.

## Turn flow
`start_turn` → Initiative (2d6 per side, ties reroll, loser first) → Movement →
Weapon Attack → Physical Attack (sides alternate unit by unit in each) → Heat → End → next turn.
Attacks are declared in order (`declare_fire`, `declare_physical`) and stored in
`GameState`; the controller resolves them all when the phase ends, so attacks are
simultaneous. Rule helpers in `src/core/rules/` (e.g. `WeaponFire`, `HeatPhase`) do the
work and report through the controller's `_emit` callable; only the controller calls them.

## Movement search
`MovePlanner` runs Dijkstra over states `(hex, facing)`. Steps are turn left/right (1 MP)
or move into the faced hex (`MoveCost`). Result `MoveOptions` gives every legal end state,
its MP cost and the path, so the UI can preview any destination and facing instantly.

## Rendering
- One `MultiMesh` of hex prisms per terrain type (a handful of draw calls for a whole map).
  Prism height is per-instance scale, so elevation costs nothing extra.
- Terrain shader samples a generated noise texture triplanar; no image assets yet.
- Picking intersects the camera ray with each level's plane, top down — no physics bodies.
- Units are placeholder box 'Mechs; `UnitView.set_model()` is the hook for real glTF models.

## Save and replay boundary

`BattleCodec` encodes rule-object graphs (including typed integer hex keys) into JSON-compatible data, and `BattleSave` stores compressed files in `user://`. `BattleRecorder` listens to significant events and captures the authoritative `GameState`; `replay_scene.gd` reconstructs presentation scenes without any `GameController`. Save/load and replay never use voxel counts to determine game mechanics. See `battle-save-replay.md` for the schema, lifecycle and limitations.

## Cinematic camera and Tactical Academy

`CinematicDirector` (src/view/camera) is a presentation-only subscriber to resolved battle events. It changes `CameraRig` goals to follow movement and frame attacks, falls, and destruction. Manual camera gestures interrupt it. `GameSettings` persists the mode; camera poses are not part of any battle save. No camera action delays or changes the rules.

`BattleRecorder` stores a compact event ledger in addition to major full-world replay checkpoints. `BattleForensics` (src/core/explain) analyzes that ledger without reconstructing dice or inferring hypothetical outcomes; `forensics_scene.gd` displays unit performance and decision points linked to nearby replay checkpoints. See `tactical-academy.md`.

## Planned modules (historical order)
1. Backward walking, jumping, prone/standing, minimum movement.
2. Line of sight (`Hex.line` + woods/levels) and to-hit modifiers.
3. Unit data: armor, internal structure, weapons, heat sinks (import from MegaMek MTF/BLK).
4. Weapon attacks, hit locations, damage transfer, criticals, ammo explosions.
5. Physical attacks, heat phase, piloting skill rolls, falls.
6. Bot opponent and battle save/replay (implemented, pending verification); campaign layer later.
