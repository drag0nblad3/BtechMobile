extends TestCase
## Derive edges by geometric neighbors, never hardcode hex coordinates.

func test_six_unique_edges_and_reversals() -> void:
	var origin := Vector2i(5, -3)
	var seen := {}
	for direction in 6:
		var next := Hex.neighbor(origin, direction)
		var edge := TerrainEdges.edge_index(origin, next)
		seen[edge] = true
		check_eq(TerrainEdges.edge_index(next, origin), (edge + 3) % 6,
			"neighbor returns the opposing hex edge")
	check_eq(seen.size(), 6, "six neighbors must map to six distinct sides")


func test_masks_cover_only_real_shorelines() -> void:
	var map := BattleMap.new()
	var grass := TerrainType.new()
	grass.id = "clear"
	var water := TerrainType.new()
	water.id = "water"
	water.is_water = true
	var center := MapTile.new(Vector2i.ZERO, water, 0, 1)
	map.tiles[center.coord] = center
	for direction in 6:
		var c := Hex.neighbor(center.coord, direction)
		map.tiles[c] = MapTile.new(c, water, 0, 1)
	check_eq(TerrainEdges.shore_mask(map, center), 0,
		"enclosed water must not produce tile-boundary foam")
	var dry_coord := Hex.neighbor(center.coord, 0)
	map.tiles[dry_coord] = MapTile.new(dry_coord, grass, 0)
	var expected := 1 << TerrainEdges.edge_index(center.coord, dry_coord)
	check_eq(TerrainEdges.shore_mask(map, center), expected,
		"only the actual land bank receives foam")
