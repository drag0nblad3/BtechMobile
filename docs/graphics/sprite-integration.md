# Dropping in 'Mech sprites

How finished sprite sets (see `mech-sprite-standard.md`) plug into the game. No art is
committed yet; until a set exists, a 'Mech shows the box placeholder.

## Where files go
```
assets/mechs/<sprite>/manifest.json
assets/mechs/<sprite>/core/facing_000.png ... facing_300.png
assets/mechs/<sprite>/top/top_000.png
```
`<sprite>` is the `sprite` field of the unit's JSON (`data/units/*.json`): `jenner`,
`hunchback`, `wolverine`, `catapult`, `atlas`. Several variants can share one folder.
Open the project in the Godot editor (or run `godot --headless --import`) once after
adding PNGs so they are imported.

## manifest.json
```json
{
  "chassis": "jenner",
  "elevation_deg": 15,
  "pixel_size": 0.01,
  "pivot": [256, 470],
  "views": {"0": "core/facing_000.png", "60": "core/facing_060.png",
            "120": "core/facing_120.png", "180": "core/facing_180.png",
            "240": "core/facing_240.png", "300": "core/facing_300.png"},
  "top": "top/top_000.png"
}
```
- **View angle**: where the camera stands around the 'Mech, measured clockwise seen from
  above, starting at its front. `0` = we see its front, `60` = camera off its front-right
  (the 'Mech's right side), `180` = we see its back, `300` = camera off its front-left.
- **pixel_size**: world units per pixel. One hex is 2 units corner to corner (`HexLayout`),
  so 0.01 makes a 200-pixel-tall 'Mech about one hex tall.
- **pivot**: ground-contact pixel, from the image's top-left, the same in every view. It
  is placed on the hex center.
- **top**: true top-down view with the 'Mech's front pointing to the top of the image.
  The game rotates it with the 'Mech and shows it when the camera looks down steeper
  than 70° (`SpriteMech.TOP_SWITCH_DEG`, e.g. Map View).

## What the game does
`SpriteMech` (`src/view/units/sprite_mech.gd`) is a Y-axis billboard that swaps to the view
nearest the camera angle each frame. `UnitView` falls back to `PlaceholderMech` when a
design has no manifest.

## Not wired yet
Faction recolor (color-zone masks), modular component layers, damage states and the
destroyed/wreck sprite. The manifest can grow fields for these without breaking older sets.
