# Fourteen more BattleMechs: shape-first sculpt batch

**Status: draft art prototypes, not production approved.** User emphasis: *no bloated,
stock humanoid chassis*. Work performed November 21, 2026. Commit alongside
fourteen unique pairs `data/voxels/<id>_shape.json` and `data/voxels/<id>.json`.

## Reference comparison and silhouette standards

Referenced modern Catalyst plastic sculpts in multiple views, with canonical
weapons cross-checked against the existing official `data/units` record sheet.
All 14 include handmade profile sections rather than a single proportional
scaled humanoid box. The two resolutions share **exactly the same primary
contour polygons and pivots**; finer grid detail is added only after the
low-resolution shape is defined.

| Chassis | Official record | Shape cells | High projected fine cells | Signature reference geometry |
|---|---|---:|---:|---|
| [Flea FLE-17](https://www.sarna.net/wiki/Flea) | `flea_fle17` | 5,222 | 140,994 | Mercenaries box Flea FLE-17; forward insect cab and backward-kneed skinny legs |
| [Spider SDR-5V](https://www.sarna.net/wiki/Spider) | `spider_sdr5v` | 5,275 | 142,425 | Inner Sphere Support Lance; long legs, narrow chest, two tall jet uprights |
| [Panther PNT-9R](https://www.sarna.net/wiki/Panther) | `panther_pnt9r` | 5,278 | 142,506 | Inner Sphere Striker Lance; boxy helmet, right PPC, CT SRM-4, thin arms |
| [Raven RVN-3L](https://www.sarna.net/wiki/Raven) | `raven_rvn3l` | 5,226 | 141,102 | Inner Sphere Urban Lance; rounded bird cab with sensor outriggers, skinny legs |
| [Crab CRB-27](https://www.sarna.net/wiki/Crab) | `crab_crb27` | 5,259 | 141,993 | ComStar Battle Level II; twin front intakes and large hooked laser claw arms |
| [Bushwacker BSW-X1](https://www.sarna.net/wiki/Bushwacker) | `bushwacker_bswx1` | 5,425 | 146,475 | Inner Sphere Heavy Battle Lance; slanted fighter-type cockpit, asymmetric AC/10 |
| [Orion ON1-K](https://www.sarna.net/wiki/Orion) | `orion_on1k` | 5,336 | 144,072 | Inner Sphere Direct Fire Lance; asym LT launcher and RT AC/10, narrow collar |
| [Longbow LGB-7Q](https://www.sarna.net/wiki/Longbow) | `longbow_lgb7q` | 5,368 | 144,936 | Inner Sphere Fire Lance; small center cab, large separated paired round 20-tube launchers |
| [JagerMech JM6-S](https://www.sarna.net/wiki/JagerMech) | `jagermech_jm6s` | 5,618 | 151,686 | Inner Sphere Security Lance; long paired dual AC cannon sleds and tiny cockpit |
| [Highlander HGN-732](https://www.sarna.net/wiki/Highlander) | `highlander_hgn732` | 5,444 | 146,988 | ComStar Command Level II; inset head, tall legs, RT/RA Gauss and LT LRM-20 |
| [Nova Prime](https://www.sarna.net/wiki/Nova) | `nova_prime` | 5,242 | 141,534 | Clan box mini; prominent oval nose, six ER medium lasers per arm |
| [Summoner Prime](https://www.sarna.net/wiki/Summoner) | `summoner_prime` | 5,214 | 140,778 | Clan Command Star; left side high LRM-15 and paired arm weapons, articulated shins |
| [Mad Dog Prime](https://www.sarna.net/wiki/Mad_Dog) | `mad_dog_prime` | 5,257 | 141,939 | Clan Heavy Striker Star; forward cockpit and paired top-side LRM-20 banks |
| [Shadow Cat Prime](https://www.sarna.net/wiki/Shadow_Cat) | `shadow_cat_prime` | 5,275 | 142,425 | Clan Command Star; long pointed cockpit and asymmetric right Gauss rifle |

## Concrete fixes made during low-resolution review

1. Stopped accepting straight parallel pillar legs as digitigrade knees. The
   Flea, Raven, Nova, Summoner, Mad Dog and Shadow Cat have offset knees,
   articulated hocks and split front-toe geometry with visible open gaps.
2. Corrected a severe preceding script bug: the legacy grid rescaler did not
   apply its coordinate factor to `add` geometry on mirrored components. This
   produced giant floating weapon boxes and sensor towers, even when the primary
   parts were already correct. This batch uniformly transforms both `shapes`
   and `add` before comparing any geometry.
3. Used `loft` cross-sections along the depth (`z`) axis for actual rounded
   Longbow missile faces and shaped Mad Dog/Summoner/Nova weapon casings, rather
   than black cuboids. The loader already supports both `y` and `z` lofts.
4. Applied real vertical proportion corrections to Spider, Panther, Orion,
   JagerMech and Highlander while preserving all pivots and part relationships.
5. Cut coarse launcher-port apertures into the signature Longbow, Mad Dog,
   Summoner, Orion and Nova weapons. The high-detail variant drills fine-grid
   holes, explicitly aligning each port with the firing muzzle coordinates.
6. Avoided painting additional bloat over detached surfaces. Internal `frame`
   structure (not armor) makes minimal one-voxel bridges and trims overlapping
   ownerships; every part must be internally connected and touch its parent.

## Offline geometry audit

**Both** `_shape` and high-detail authoring grids: 0 intersecting components,
0 disconnected voxel islands, 0 missing parent contacts, all 8 official
hit locations present. Coarse voxel bounds and fine-grid projections are in
this table above and the machine-readable audit JSON. The detailed versions
use `subdivide: 3` with projected **~139–152k voxels before bevel processing**.
These are not Godot-measured final counts: bevels can erase cells, vents and
bores delete surface cells, and additional fine detail may add new cells.

### Review requirements — not optional production approval

- Compare front/side/back/top/three-quarter views to the current Catalyst
  plastics, not only 3D silhouette intuition. The low front and high isometric
  contact sheets are **offline renders of JSON voxel geometry**, not Godot
  screenshots or generated concept art.
- Pay particular attention to the birds' forward-to-rear depth, clearances
  around the Longbow/Mad Dog racks, the Spider's two jet uprights, the
  correct arm asymmetry of Orion/Highlander/Summoner/Shadow Cat, and thin
  ankles remaining attached during walking animation.
- Run `godot --headless -s tests/run_tests.gd` and specifically
  `tests/unit/test_vx_fourteen_chassis.gd`, followed by
  `scenes/vx_showcase.tscn` and Godot headless smoke tests.
- The earlier batches already have CI failures concerning tiny interpenetrating
  voxel islands. This batch does not claim those failures are resolved or
  retroactively change prior art. Do **not** merge until checks pass.

The official combat data, hit logic and asset authoring system are unchanged.
No Android build or merge is part of this batch.
