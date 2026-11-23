# BattleTech Mobile application icon

The icon is original stylized artwork: an angular steel-blue BattleMech with an
amber cockpit visor, cannon and six-cell missile pod, inside a gold hexagonal
battlefield badge. No external logo or Mech illustration is embedded.

- `icon.svg` is the main square icon and Godot project icon.
- `icon_foreground.svg` isolates and scales the 'Mech into the Android
  adaptive-icon safe area; it is transparent outside the 'Mech.
- `icon_background.svg` supplies the sky, mountains, sun and gold badge.
- `assets/branding/icon_{main,foreground,background,monochrome}.png`
  are 512×512 exported launcher images committed to the repository.

To regenerate the PNGs after editing the SVG masters:

```sh
python -m pip install cairosvg pillow
python tools/generate_app_icons.py
```

`export_presets.cfg` points directly at those PNG files for classic Android
launcher icons, adaptive icons and Android 13+ monochrome themed icons.
Keep critical foreground details inside the centered circular safe zone.
This artwork is cosmetic and does not change BattleTech unit designs or rules.
