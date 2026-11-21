class_name BattleMap
extends RefCounted
## A grid of MapTiles keyed by axial coordinate.

var name: String = ""
var width: int = 0   ## Columns (mapsheet XX).
var height: int = 0  ## Rows (mapsheet YY).
var tiles: Dictionary = {}  # Vector2i -> MapTile
var rubble: TerrainType = null  ## What a collapsed building leaves behind.
var ground: TerrainType = null  ## Clear terrain, for water dried out by extreme heat.
var no_fire := false  ## Rain: nothing can be set alight.
var windy := false  ## Wind clears smoke and fog (set from Conditions).


func get_tile(c: Vector2i) -> MapTile:
	return tiles.get(c)


func has(c: Vector2i) -> bool:
	return tiles.has(c)


func coords() -> Array:
	return tiles.keys()


func level_range() -> Vector2i:
	var lo := 0
	var hi := 0
	for t: MapTile in tiles.values():
		lo = mini(lo, t.floor_level())
		hi = maxi(hi, t.level)
	return Vector2i(lo, hi)
