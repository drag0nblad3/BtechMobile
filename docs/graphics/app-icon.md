# BattleTech Mobile app icon

The square primary game icon is `assets/icons/icon.png`. Android uses the same art
for its legacy launcher icon plus dedicated adaptive layers,
`adaptive_foreground.png` and `adaptive_background.png`.

The original artwork is a game-specific illustration of an armored walking combat
machine in a gold hexagonal frame. It has no text, so it remains legible at
launcher scale. Keep the cockpit, cannon and shoulder weapons inside the
central Android adaptive icon safe zone when replacing it.

The images are RGB/RGBA PNGs. The project icon is assigned in `project.godot`;
the Android launcher images are assigned in `export_presets.cfg`.
