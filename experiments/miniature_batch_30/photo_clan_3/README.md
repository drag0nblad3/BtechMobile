# Photographic anatomy pass — Nova, Fire Moth, Timber Wolf

Six photos inspected in image search; hand-estimated region contours and landmarks on the displayed 512px previews, not original-resolution automatic segmentation. URLs and traces in annotations.json. Two images per chassis; Timber Wolf second image is the enlarged 100mm Catalyst product and not assumed to match tabletop sculpt precisely. The two Fire Moth photos depict similar poses. None supplies a true rear view. Camera/pose frozen from control when scoring.

| Chassis | First view control / selected | Second view control / selected |
|---|---|---|
| Nova | 50.87 / 52.85% | 52.99 / 54.50% |
| Fire Moth | 50.40 / 50.84% | 53.09 / 53.34% |
| Timber Wolf | 45.39 / 60.28% | 50.59 / 56.01% |

Nova: selected major hull, arm drums, six-tube banks and toes. Timber Wolf: selected major rounded nose, spaced missile banks, stacked gun apertures and foot/leg changes. Fire Moth: both full reconstructions regress in second view, accepted only revised torso and nose; arm swap and leg swap rejected. Fire Moth weapon assignment on the alternative was based on screen-side identification and is not certified for anatomical left/right or variant. All three selected source specs pass neutral structural audit, 57 parts, 25,378 cells and 64/64 three-cell muzzle samples clear. Sample clearance is not continuous-bore certification. Camera RMS 2.38–5.79 px; joint residuals up to 21.31 px. Scores measure approximate visible-region IoU, not likeness percentage. Prior branch models untouched. No Godot or production testing.

Before/after neutral geometry: [Nova](nova_before_after.svg), [Fire Moth](fire_moth_before_after.svg), [Timber Wolf](timber_wolf_before_after.svg). Full rejected alternatives in *_trials.json.