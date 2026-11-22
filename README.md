# BtechMobile

A BattleTech (Total Warfare) simulator for Android phones, built with Godot 4.
Full 3D hex maps with elevation, woods and water; touch camera controls; automated rules.

![Movement preview](docs/screenshot.png)

**Status:** playable tactical battles with full turn sequence, AI opponents, extensive Total Warfare rules, missions and training scenarios. Battle autosaves and state-by-state replays are on the save/replay feature branch, with Godot CI verification; Android device validation is still needed.

## Run it
1. Install [Godot 4.5+](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot`, press Play. The launcher lets you choose **Play Battle Game**
   or **Voxel Mech Lab** (3D walking and destructible voxel prototype).
   - The lab has a **Main Menu** button to return to the mode launcher.
   - Mouse: left-drag pan, right-drag orbit/tilt, wheel zoom, click to select/move.
   - Touch: drag pan, pinch zoom, two-finger twist to orbit, two-finger drag to tilt,
     tap to select/move, double-tap to center the camera.
3. Android: the repo includes an **Android** export preset (`export_presets.cfg`). Set up the
   Android SDK, JDK 17 and a debug keystore in *Editor Settings → Export → Android*, then
   use *Project → Export* or the one-click deploy button with a phone plugged in. To get an
   APK without a local setup, run the **Android APK** workflow by hand from the Actions tab.
   See `docs/PLANNING.md` for details. **Before the first CI APK build, set up
   the persistent debug signing secrets** described in [`docs/android-signing.md`](docs/android-signing.md).
   The builder now refuses to generate an APK if those secrets are missing.

## Battle saves and replays

The battle HUD has **Save** and **Replay** buttons. The force-builder screen offers **Continue saved battle** for a live quick-save and **Watch last replay** for the most recent archived battle. Active battles autosave once per turn and when Android pauses the application. Replays are read-only snapshots of major events, not videos; the viewer has play/pause and step controls. See [battle save and replay notes](docs/battle-save-replay.md).

## Cinematic gameplay and Tactical Academy

Use **Cine: On/Off** in the battle HUD for a saved, opt-in cinematic camera that follows movement and automatically frames weapon fire, close combat and destruction. Touch and mouse camera gestures temporarily take priority. The tactical camera and the underlying battle rules remain unchanged.

**Tactical Academy → Battle Forensics** analyzes the latest recorded battle: observed vs. expected hit results using 2d6 probabilities, unit-level damage, heat, piloting failures, and decisive events. Open it from the force builder, replay viewer, or the game-over screen; tap a finding to inspect the nearest replay checkpoint. See [Tactical Academy notes](docs/tactical-academy.md).

## Tests
```sh
godot --headless --import
godot --headless -s tests/run_tests.gd
```

See `CLAUDE.md` for the file map and `docs/` for architecture, data formats and rules coverage.
