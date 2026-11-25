# Tactical map generation and reference benchmark

The generator keeps its original terrain pipeline and seed identity. It now
screens each raw layout for gross mobility problems using the existing
`MoveCost` rules. Both possible deployment axes are assessed. A good first
candidate is retained unchanged. Otherwise it may try a local shallow-ford
repair, then a deterministic alternative seed; it keeps the lowest-penalty
candidate of at most three layouts. This is a preference, not a guarantee
that every route is viable. Nothing in the battle rules or RNG is changed.

## What is measured

- Two-row deployment capacity, shared reachable usable ground, shortest
  crossing MP, center-area access and side-to-side center cost ratio.
- Independent approach bands: each of three non-overlapping longitudinal
  thirds must contain a reciprocal ground route. A count of three is a
  conservative indicator, not the maximum number of possible routes.
- Detailed reports additionally measure 3-MP movement accessibility
  (4-MP is the normal screening limit) and use the existing LOS resolver
  for representative standing positions 3–6, 7–12 and 13–20 hexes apart.
  Cover is measured among visible lines. Both directions are sampled.
- Paths ignore turning, occupancy, jumping, damage, pilot rolls, building
  entry and deep-water movement. Bridge load limits are not modeled.
  Central access is measured within radius 2, not a mission-specific
  objective placement. These are geometry indicators, not win rates.
- Open Plains, Heavy Forest and Desert Hills extend the existing biome
  range without removing Woodland, Grassland or Badlands.

## Published references

`map-reference-baseline.json` records aggregate terrain counts and source
blob IDs for 16 named published mapsheet transcriptions from
[MegaMek/mm-data](https://github.com/MegaMek/mm-data/tree/main/data/boards).
The data is attributed to the MegaMek team (CC BY-NC-SA 4.0; see upstream
license and board notices). No map layout, art, or board files are bundled.
The report can read external files from a local checkout of those boards.
The selected corpus is small and deliberately covers different styles;
it is not a representative random sample of all published maps.

The raw count fields can overlap (modern city buildings often sit on
pavement). For movement/LOS the importer supports the terrain types in
these boards and maps roads to pavement, building classes and heights
to the game's equivalents; it rejects unsupported features. Multi-hex
building connectivity, construction factors, directional road exits
and decorative overlays are not reproduced. Published sheets here use
16×17 coordinates; the game currently uses 15×17 generated sheets, so
compare proportions and range bins, not unnormalized absolute distances.

Examples from the actual aggregate reference counts:

| Reference | Woods | Raised dry ground | Other |
| --- | ---: | ---: | --- |
| Grasslands Open Terrain 2/3 | 9–10% | 14–20% | 0–1.5% water |
| Heavy Forest 1/2 | 79–81% | 20–23% | 35–36% heavy woods |
| Rolling Hills 1/2 | 15–19% | 51–52% | no rough |
| River Valley / Streams | 5–18% | 9–33% | 10–27% water |
| Lakes / Large Lakes 1 | 8–11% | 21–28% | 16–50% water |
| Desert Hills / Desert Mountain 1 | 0% | 41–48% | 4–6% rough |
| Business / Shopping District | 0–2% | 0–1% | 25–33% building |

## Reproduce the comparison

```sh
godot --headless --import
godot --headless -s tests/run_tests.gd -- map_tactics
godot --headless -s tools/map_quality_report.gd -- 10 /path/to/mm-data/data/boards
```

The report emits JSON lines beginning with MAP_QUALITY, for raw and
screened layouts and available reference boards. Timings measure generation
without the detailed reporting pass. The path-filtered GitHub Actions
benchmark uses three seeds per theme, downloads the external reference
boards from a pinned revision and verifies their Git blob IDs. Reference
downloads are optional; their absence is visible and is not a gameplay
failure. No downloaded layouts are uploaded as artifacts. Full integration
CI still runs the normal map and battle tests.

Further calibration should compare distributions by theme and size, then
run paired side-swapped battles with multiple force compositions and
missions. A lower mobility penalty alone does not establish parity with
official maps. LOS and actual game outcomes need to inform a future
calibration pass; tactical screening deliberately does not optimize for
one particular engagement range.
