class_name ScenarioLoader
extends RefCounted
## Builds a GameState from data/scenarios/<id>.json:
##   {"map": "test_valley", "units": [{"def": "atlas_as7d", "side": 0,
##    "hex": "0816", "facing": 0}, ...]}
## "hex" is a mapsheet label (XXYY, 1-based).


static func load_file(path: String, terrain: TerrainDb, units: UnitDb) -> GameState:
	var data: Dictionary = JsonFile.read(path)
	var map_path := "res://data/maps/%s.json" % data["map"]
	var state := GameState.new(MapLoader.load_file(map_path, terrain))
	var next_id := 1
	for u in data["units"]:
		var def := units.get_def(u["def"])
		assert(def != null, "Unknown unit def %s" % u["def"])
		state.add_unit(Unit.new(next_id, def, int(u["side"]),
				parse_label(u["hex"]), int(u.get("facing", 0))))
		next_id += 1
	return state


static func parse_label(lbl: String) -> Vector2i:
	var col := int(lbl.substr(0, 2)) - 1
	var row := int(lbl.substr(2, 2)) - 1
	return Hex.from_offset(Vector2i(col, row))
