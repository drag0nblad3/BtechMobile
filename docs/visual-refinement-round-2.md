# Battle visual refinement — six ordered systems

This branch implements the six requested visual and UX passes in order without
changing combat rules, dice, save schema, scenarios, BV, or voxel-source files.

## 1. Weapon mounts and impacts

- Shot visual origin is selected from the unit's actual MountedWeapon location
  (head, torso, arms, legs, rear) with named Marker3D sockets where available.
  Placeholder arms now provide explicit muzzle markers. Sprite-based chassis
  and other models use a record-sheet-aware fallback, **not fabricated
  per-chassis weapon hardpoints**.
- DAMAGE events carry the rolled hit location, which drives targeted armor
  spark/debris FX independently of WEAPON_FIRED, preserving multiple-hit
  packets. Cosmetic recoil and muzzle flashes stay short-lived.
- Existing hit rules and voxel destruction behavior are untouched.

## 2. Terrain continuity

- Neighbor-aware blending only at transitions between different non-water
  hexes, retaining individual terrain type patterns and readable grid.
- Per-tile six-bit shoreline masks add foam only along true water-to-land
  edges, not between two adjacent water hexes.
- Batching stays at one MultiMesh per terrain type and one for water.
  No additional texture assets or high-cost CPU particle systems.

## 3. Surface-responsive locomotion

- Footsteps follow each completed hex-to-hex tween, with different dirt,
  rubble, snow and water cues. Large units produce proportionally larger
  puffs. Jumping gets a visual arc, takeoff exhaust and landing burst.
- Only light, transient VxBlast particles (capped at 32 surface effects)
  are created. These are visual animations, not added game physics.

## 4. Tactical overlays

- Movement range opacity varies with MP cost. Planned paths, selected hexes,
  known adjacent enemies, partial cover and rule-derived blocked/clear LOS
  use distinct colors.
- An on-map path-cost plate shows actual MP budget, movement heat from
  MoveMode.heat(), and terrain elevation delta. Hidden enemies are not
  revealed by the proximity overlay.
- LOS tint indicates the full line's computed blocked/clear result, not an
  invented individual obstruction hex.

## 5. Phone battle HUD

- Frequently used controls remain on the top bar. Save, Replay and Explain
  move into a real More popup. Compact buttons, a narrower side panel,
  combat log and tip panel give the map more screen area.
- Attack selection gets live selected-volley total heat and expected damage,
  using current to-hit probabilities and selected weapons.

## 6. Cinematic control

- Major hits, launches, jumps and explosions take priority; trivial shots
  do not constantly reframe the camera.
- Brief missile flight tracking, limited deterministic impact jolt,
  shorter holds, and automatic return to the tactical framing.
- Manual camera input cancels queued shots and suppresses new ones for
  three seconds. It never consumes combat RNG.

## Validation

- Pure unit tests cover mount locations, shore masks, surface types,
  tactical marker semantics and cinematic bounds.
- Existing battle UI, Academy, replay and stress smoke tests continue.
- Scene smoke verifies physical model impact positions, HUD utility menu
  and preview signage; CI captures 1280x720 city combat and movement screenshots.
- Actual device review is still needed for touch ergonomics, terrain
  coloration under hardware renderers, 60-model effects throughput and
  per-chassis muzzle authoring. No APK should be built without instruction.
