class_name MapTile
extends RefCounted
## One hex of a battle map.
## `level` is the ground level, or the water surface for water hexes.
## A unit standing in water stands on the bottom: `floor_level()`.

var coord: Vector2i
var terrain: TerrainType
var level: int = 0
var depth: int = 0
var building: Building = null  ## Standing building, if any.
var on_fire := false  ## Burning (Fire).


func _init(c: Vector2i, t: TerrainType, lvl: int, dep: int = 0) -> void:
	coord = c
	terrain = t
	level = lvl
	depth = dep


func floor_level() -> int:
	return level - depth


func is_water() -> bool:
	return terrain.is_water and depth > 0
