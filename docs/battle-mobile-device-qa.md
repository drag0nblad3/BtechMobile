# Battle visual follow-up — Android acceptance and measurement

## Scope and verification status

This change adds authored placeholder-chassis muzzle markers, airborne jump-jet
movement with four low-cost exhaust meshes per jumping unit, real launch/landing
bursts, and an **optional** in-battle FPS/CPU/effects overlay.

**Important:** GitHub Actions uses headless Godot and Linux's Compatibility
renderer; neither measures Android framerate, touch latency, GPU-driver
behavior, battery drain, or thermal throttling. No Android hardware is
connected to CI, and no APK should be built without explicit instruction.
The review captures below are computer renders, not device tests.

## Review on actual Android hardware (not yet performed)

1. Launch the game on a low/mid/high representative Android phone or tablet.
   Note device model, SOC/GPU, Android version, screen resolution/refresh rate,
   rendering backend, and power/thermal mode.
2. In a battle, open **More → Performance overlay**. Measure FPS and CPU
   frame processing time (milliseconds), with shot and jet effect counts.
   Note any serious stutter during attacks, dust bursts, or model changes.
3. Check the following mounted weapons in both 3/4 and top views:
   Atlas AS7-D (right torso AC/20, rear center torso lasers);
   Catapult CPLT-C1 (left/right LRM pods);
   Jenner JR7-D (two lasers on each arm and central SRM);
   Wolverine WVR-6R (right arm autocannon);
   Warhammer WHM-6R (left/right PPCs);
   Hunchback HBK-4G (right shoulder AC/20).
   These sockets are hand-positioned on the *currently displayed proxy models*,
   not claimed final positions on future high-fidelity chassis. New models
   can supply `muzzle_0`, `muzzle_1`, etc. to override fallback behavior.
4. Make a legal jump in a Jenner, Griffin or Catapult. Verify the model rises
   above the battlefield, the pair of exhausts remains behind the unit while
   moving, the landing aligns with the destination, and exhaust disappears.
   Test jumping from/to elevation, dry ground, water and a roof.
5. Look for the distinct small launch/landing dust versus water splash and
   verify normal walking/running remain ground level. Check that no effect
   blocks taps, damage changes, or saved replay determinism.
6. Open **Voxel Mech Lab**, start the **20-model** stress test, let it load and
   sample FPS for at least 60 seconds. Repeat at **60 models** for at least
   60 seconds; watch for progressive slowdown, overheating, memory pressure
   and app responsiveness during damage. STOP must work even while spawning.
7. Repeat battle capture in high-contrast terrain, water and urban conditions,
   with the HUD log and record sheet expanded, landscape safe areas and device
   cutouts. Check 1280×720-equivalent and native-res orientations.

For each test record median and minimum sustained FPS (after load), CPU
process time, effect counts, resolution, temperature/thermal flags if
available, unexpected visual defects, and exact repro actions. Do not infer
Android performance from CI's software-rendered frame rates.

## CI checks and visuals

- Headless unit tests validate socket coverage, left/right and rear mounting,
  repeated barrels, jump arc bounds, and mobile effect budgets.
- Scene smoke asserts the optional telemetry overlay and that airborne
  jumps actually rise and clean up exhaust nodes.
- A pull-request-only 1280×720 Godot Compatibility capture produces
  `weapons.png` and `jump.png` for before/device comparison. Both are
  deterministic **visual demonstrations**, not a playthrough.
- On-device validation is still an outstanding acceptance condition.
