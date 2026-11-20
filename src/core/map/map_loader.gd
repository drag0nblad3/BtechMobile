class_name MapLoader
extends RefCounted
## Loads maps from JSON. Format (see docs/data-formats.md):
##   {"name": "...", "rows": ["c0 c1 L2 w0d1 ...", ...]}
## Each row is one mapsheet row (YY), each token one column (XX).
## Token = terrain char + level, optionally "d" + water depth.
## Optional "buildings": [{"hex": "XXYY", "type": "medium", "height": 2}].
## Optional "fires": ["XXYY", ...]: hexes burning from the start.


static func load_file(path: String, terrain: TerrainDb) -> BattleMap:
	var data: Variant = JsonFile.read(path)
	return from_dict(data, terrain)


static func from_dict(data: Dictionary, terrain: TerrainDb) -> BattleMap:
	var m := BattleMap.new()
	m.name = data.get("name", "")
	var rows: Array = data["rows"]
	m.height = rows.size()
	for row in rows.size():
		var tokens: PackedStringArray = String(rows[row]).split(" ", false)
		m.width = maxi(m.width, tokens.size())
		for col in tokens.size():
			var c := Hex.from_offset(Vector2i(col, row))
			m.tiles[c] = parse_token(tokens[col], c, terrain)
	m.rubble = terrain.get_type("rubble")
	for b: Dictionary in data.get("buildings", []):
		var tile := m.get_tile(Hex.from_label(b["hex"]))
		var bt: BuildingType = terrain.buildings.get(b.get("type", "medium"))
		assert(tile != null and bt != null, "Bad building %s" % b)
		tile.building = Building.new(bt, int(b.get("height", 1)))
	for f: String in data.get("fires", []):
		var ft := m.get_tile(Hex.from_label(f))
		assert(ft != null, "Bad fire hex %s" % f)
		ft.on_fire = true
	return m


static func parse_token(tok: String, c: Vector2i, terrain: TerrainDb) -> MapTile:
	var t: TerrainType = terrain.by_token.get(tok[0])
	assert(t != null, "Unknown terrain token '%s'" % tok)
	var rest := tok.substr(1)
	var depth := 0
	var dpos := rest.find("d")
	if dpos >= 0:
		depth = int(rest.substr(dpos + 1))
		rest = rest.substr(0, dpos)
	return MapTile.new(c, t, int(rest), depth)
