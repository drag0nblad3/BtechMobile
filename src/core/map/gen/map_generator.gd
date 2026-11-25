class_name MapGenerator
extends RefCounted
## Builds an original battlefield from a MapTheme and a seed. A mapsheet
## is 15 hexes wide and 17 high (book p. 223); battlefields are made of
## whole sheets, two side by side being the standard size. The same theme,
## size and seed always give the same map.

const SHEET_COLS := 15
const SHEET_ROWS := 17
## Mapsheets across x down. Two side by side is the standard battlefield.
const SIZES: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]


const MAX_CANDIDATES := 3


## Keep good seeds untouched. Retry only gross tactical failures; the
## original requested seed remains the stable identity of the battlefield.
static func generate(t: MapTheme, sheets: Vector2i, seed_value: int, terrain: TerrainDb = null) -> Dictionary:
	if terrain == null:
		terrain = TerrainDb.load_file()
	var best := {}
	var best_penalty := INF
	for attempt in MAX_CANDIDATES:
		var layout_seed := seed_value + attempt * 104729
		var candidate := generate_raw(t, sheets, layout_seed)
		var report := MapTactics.assess(MapLoader.from_dict(candidate, terrain), false)
		var p := MapTactics.penalty(report)
		if p < best_penalty:
			best = candidate
			best_penalty = p
			best["layout_seed"] = layout_seed
		if best_penalty <= 0.0:
			break
	best["name"] = "%s #%d" % [t.name, seed_value]
	best["seed"] = seed_value
	return best


## Unfiltered baseline for regression comparisons and generator tuning.
static func generate_raw(t: MapTheme, sheets: Vector2i, seed_value: int) -> Dictionary:
	var g := GenGrid.new(SHEET_COLS * sheets.x, SHEET_ROWS * sheets.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	GenElevation.apply(g, t, seed_value)
	GenRiver.apply(g, t, rng, seed_value)
	GenElevation.relax(g)
	GenTown.streets(g, t, rng)
	GenRoads.apply(g, t, rng)
	GenBridges.apply(g, t)
	GenTown.buildings(g, t, rng)
	GenTown.rubble(g, t, rng)
	GenCover.apply(g, t, seed_value)
	var d := g.to_dict("%s #%d" % [t.name, seed_value])
	d["theme"] = t.id
	d["seed"] = seed_value
	d["sheets"] = [sheets.x, sheets.y]
	if not t.colors.is_empty():
		d["colors"] = t.colors
	return d


static func build(t: MapTheme, sheets: Vector2i, seed_value: int, terrain: TerrainDb) -> BattleMap:
	return MapLoader.from_dict(generate(t, sheets, seed_value, terrain), terrain)


static func size_name(sheets: Vector2i) -> String:
	var n := sheets.x * sheets.y
	return "%d mapsheet%s (%d×%d hexes)" % [n, "" if n == 1 else "s",
			SHEET_COLS * sheets.x, SHEET_ROWS * sheets.y]
