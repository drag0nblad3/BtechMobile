class_name TerrainDb
extends RefCounted
## All terrain types, keyed by id and by map-file token.

const DEFAULT_PATH := "res://data/terrain.json"

var by_id: Dictionary = {}     # String -> TerrainType
var by_token: Dictionary = {}  # String -> TerrainType


static func load_file(path: String = DEFAULT_PATH) -> TerrainDb:
	var db := TerrainDb.new()
	var data: Variant = JsonFile.read(path)
	for d in data["terrain"]:
		var t := TerrainType.from_dict(d)
		db.by_id[t.id] = t
		db.by_token[t.token] = t
	return db


func get_type(id: String) -> TerrainType:
	return by_id.get(id)
