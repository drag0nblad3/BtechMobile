# BtechMobile

A BattleTech (Total Warfare) simulator for Android phones, built with Godot 4.
Full 3D hex maps with elevation, woods and water; touch camera controls; automated rules.

![Movement preview](docs/screenshot.png)

**Status:** first playable slice — load a scenario, select a 'Mech, preview walking/running
paths with facing, and move. Sides alternate by initiative. Combat is next.

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
   See `docs/PLANNING.md` for details.

## Tests
```sh
godot --headless --import
godot --headless -s tests/run_tests.gd
```

See `CLAUDE.md` for the file map and `docs/` for architecture, data formats and rules coverage.
