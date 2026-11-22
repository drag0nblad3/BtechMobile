class_name VtolFlight
extends RefCounted
## VTOL flight levels (book pp. 142-144). A VTOL is always at least one
## level above the hex it's in or flies through, counting woods and
## buildings, and never lands. Each level climbed or dropped costs 1 MP.
## Its LOS level is its flight level + 1; range ignores level.
## TODO(rules): the player can't pick a higher flight level yet: VTOLs fly
## nap-of-the-earth, at the lowest level each hex allows; bridges ignored.


static func is_vtol(u: Unit) -> bool:
	return u.asset != null and u.asset.card.motive == "v"


## Lowest flight level over this hex.
static func min_level(tile: MapTile) -> int:
	var top := maxi(tile.level, tile.level + tile.terrain.los_height)
	if tile.building != null:
		top = maxi(top, tile.floor_level() + tile.building.height)
	return top + 1


## MP to climb or drop between two hexes' flight levels.
static func climb_mp(src: MapTile, dst: MapTile) -> int:
	return absi(min_level(dst) - min_level(src))


## Flight level now: at least the hex's minimum.
static func level(map: BattleMap, u: Unit) -> int:
	var tile := map.get_tile(u.coord)
	return maxi(u.asset.altitude, min_level(tile)) if tile != null else u.asset.altitude


## After a move: settle at the destination's lowest level.
static func settle(map: BattleMap, u: Unit) -> void:
	var tile := map.get_tile(u.coord)
	if tile != null:
		u.asset.altitude = min_level(tile)
