# Battle visual polish — battlefield, HUD, and combat FX

This visual-only pass preserves the underlying BattleTech rules, camera controls,
scenario data, and unit geometry. It adds no gameplay effects or damage rules.

## Battlefield

- **Elevations:** procedural rock strata and subtle top-lip illumination on
  hex-prism cliffs. Deterministic variation breaks up repetitive ground tiles.
  Shaders retain the terrain-specific rock/soil/rubble patterns.
- **Water:** animated multi-frequency wave highlights, shore shallows and
  depth-aware colors. One MultiMesh with one shared shader, no separate wave
  objects, CPU updates or texture downloads.
- **Lighting:** warmer key light and shadowless cool fill to reveal faceted
  chassis and building detail; no bloom/SSAO or additional shadow maps.
- **Tactical overlays:** darkened transparent reachable fills with brighter
  hex-border rings for selected units, attack targets and movement paths.
  Overlay and border share their tile transforms; they clear together.

## HUD

- Six-segment phase timeline always shows the current phase while preserving
  the existing status and controls.
- Short hit, miss, no-ammo, destruction and collapse callouts fade without
  blocking touch input; new events replace old callouts.
- Combat log color differentiates hits, misses, phase changes and major damage
  without changing the underlying explanation strings.

## Combat effects

- Weapon family colors: PPC blue, laser red, flame orange, missiles amber,
  ballistic pale gold. Brief beams or traveling projectile dots are cosmetic.
- Deterministic near-target miss deviations, small miss dust, and fall dust.
  Projectile trails free themselves in under half a second, with a maximum
  of 28 simultaneously active trails. No persistent particle emitters, lights,
  collision objects, or game-logic dependencies.
- Existing voxel impacts, ammo explosions, destruction and building scar FX
  remain in place.

## Verification and mobile follow-up

- Unit tests cover shot family recognition, deterministic misses, and
  lightweight particles.
- Headless battle visual scene smoke checks the phase strip, indicator,
  event banner, overlay outline, shader-backed water, fill lighting and FX
  lifetime. The full existing launcher/battle UI tests remain enabled.
- Visual acceptance on real Android hardware still needed: 1280×720
  landscape/notch, terrain edge clarity at steep angles, water appearance
  on Compatibility renderer, HUD tap safety, brightness and GPU cost with
  large 20/60-model battles. Do not build an APK unless requested.

- PR CI also captures an actual 1280×720 Compatibility-renderer city scene
  with a temporary PPC tracer and combat HUD callout. Review the screenshot
  artifact **battlefield-polish-visual-review** for final composition QA.

## Screenshot review findings

The first city screenshot revealed a blank contextual-tip panel obscuring terrain
when explanation level was Off. Empty tip and information panels now collapse,
and the shore palette is toned down for less neon-like water. The temporary
PPC tracer in the review screenshot is placed in the visible area of the map;
it remains screenshot-only and never changes combat logic.

- The capture script stages two existing unit views nearer the camera center,
  then displays an intentionally synthetic PPC visual on the last frame.
  It is a rendering example, not a recorded battle turn.
