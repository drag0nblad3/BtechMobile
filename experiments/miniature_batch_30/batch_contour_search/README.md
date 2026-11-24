# Cached component contour search pilot

Four chassis, manually approximated 512px miniature outlines, one view each, no production files. Fixed camera/pose per chassis; generated local profile variants; cache rasterized unchanged parts; preserve each previously clear axial muzzle sample and neutral structural audit. Scores are diagnostic mean visible region IoU, not verified likeness. No Godot validation, exact variant check or secondary views. Source photos not redistributed. Nonmonotonic source lofts skipped. The selected candidates are provisional; no automatic production adoption. Cache hits measure avoided part rasterizations, not total elapsed speedup.

- mad_dog: 32.40 -> 33.10%, 232 changed cells, 0 faults, 522 cached part raster reads / 66 misses; camera RMS 11.9px; axial samples 40/44 -> 40/44.
- hellbringer: 44.01 -> 44.55%, 312 changed cells, 0 faults, 438 cached part raster reads / 66 misses; camera RMS 11.3px; axial samples 8/8 -> 8/8.
- kit_fox: 47.02 -> 47.53%, 152 changed cells, 0 faults, 474 cached part raster reads / 58 misses; camera RMS 2.0px; axial samples 2/2 -> 2/2.
- cougar: 24.93 -> 25.75%, 160 changed cells, 0 faults, 408 cached part raster reads / 54 misses; camera RMS 9.1px; axial samples 22/22 -> 22/22.
