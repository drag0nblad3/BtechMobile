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
var bridge: Bridge = null  ## Bridge deck over this hex, if any (Bridges).
var on_fire := false  ## Burning (Fire).
var surface := ""  ## Terrain modification: "", "ice", "mud" or "snow" (Surfaces).
var fog := 0  ## Fog in the hex: 0 none, 1 light, 2 heavy (Obscurant).
var smoke := 0  ## Smoke from Smoke Arrow IV: 0 none, 1 light, 2 heavy (ArrowSmoke).
var smoke_turn := -1  ## Turn the smoke reached its current density.


func _init(c: Vector2i, t: TerrainType, lvl: int, dep: int = 0) -> void:
	coord = c
	terrain = t
	level = lvl
	depth = dep


## Ice covers water: 'Mechs walk on the surface.
func floor_level() -> int:
	return level if surface == "ice" else level - depth


func is_water() -> bool:
	return terrain.is_water and depth > 0 and surface != "ice"
