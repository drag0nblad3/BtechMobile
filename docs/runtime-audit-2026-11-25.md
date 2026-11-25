# Runtime audit — 2026-11-25

Base: 00f76dbce30d815711029351bb2378bbeaf5dc7a. Static review; local Godot and a clone are unavailable in the connector session.
Run the normal CI import, unit suite and UI/campaign smoke tests before merge.
No Android build or rule changes intended.

## Implemented
- Cache direct LOS only for one synchronous attacker/target weapon forecast; reuse the primary hex line.
- Tactical cover/range overlays skip path reconstruction; range profiles are resolved once per enemy weapon.
- Preserve deployment/exit visibility across condition refresh and voxel toggles; include off-field units in nameplate setup and hide plates for invisible views.
- Refresh arrivals after wave placement, not during its pre-placement notification.
- Remove replaced side controls immediately, clear stale movement action flags, initialize replay camera on direct nonzero frame.
- Enforce the shot cap at the spawning boundary and scale trail cylinders instead of remeshing every animation frame.

## Follow-up candidates (not changed)
- BattleRecorder serializes full state at every damage frame; long battles can grow memory and save time substantially. Measure bytes/frame, autosave time and replay seek time before implementing checkpoint/delta storage with versioned compatibility.
- Replay recreates map, units and scars on each frame; profile reuse/incremental playback, with scrubbing and backwards-seek tests.
- VxRenderCache holds recipe/geometry entries for the process lifetime; measure retained memory across varied battles before adding a bounded eviction policy.
- Nameplates re-evaluate forecasts every 250 ms. Event-based invalidation needs explicit handling of mode/twist changes that may not emit events.
- MovePlanner repeatedly scans occupancy; a plan-scoped coordinate index should preserve stacking, swarm, transport and tie ordering. Benchmark first.
- No measured FPS or CPU gains are claimed. Device profiling remains necessary.
