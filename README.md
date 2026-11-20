# BtechMobile

A hex-based BattleMech game for Android, built with [Godot 4](https://godotengine.org/).
The world and camera are 3D, and the mechs are 2D sprites that switch between six
hex-facing views and a top-down view as the camera moves.

- `game/` is the Godot project. Open `game/project.godot` in Godot 4.5.
- `docs/PLANNING.md` covers the current state, Android setup and roadmap.
- `docs/graphics/mech-sprite-standard.md` is the mech sprite design standard.

## Get an Android build

Every push and pull request runs the **Android build** GitHub Actions workflow, which
exports a debug APK. Download it from the workflow run's **Artifacts** section and
install it on a phone with USB debugging or by sideloading (allow installs from unknown
sources).

To build locally, see "Building for Android" in [docs/PLANNING.md](docs/PLANNING.md).
