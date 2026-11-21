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


static func generate(t: MapTheme, sheets: Vector2i, seed_value: int) -> Dictionary:
	var g := GenGrid.new(SHEET_COLS * sheets.x, SHEET_ROWS * sheets.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	GenElevation.apply(g, t, seed_value)
	GenRiver.apply(g, t, rng, seed_value)
	GenElevation.relax(g)
	GenTown.streets(g, t, rng)
	GenRoads.apply(g, t, rng)
	GenTown.buildings(g, t, rng)
	GenTown.rubble(g, t, rng)
	GenCover.apply(g, t, seed_value)
	var d := g.to_dict("%s #%d" % [t.name, seed_value])
	d["theme"] = t.id
	d["seed"] = seed_value
	d["sheets"] = [sheets.x, sheets.y]
	return d


static func build(t: MapTheme, sheets: Vector2i, seed_value: int, terrain: TerrainDb) -> BattleMap:
	return MapLoader.from_dict(generate(t, sheets, seed_value), terrain)


static func size_name(sheets: Vector2i) -> String:
	var n := sheets.x * sheets.y
	return "%d mapsheet%s (%d×%d hexes)" % [n, "" if n == 1 else "s",
			SHEET_COLS * sheets.x, SHEET_ROWS * sheets.y]
