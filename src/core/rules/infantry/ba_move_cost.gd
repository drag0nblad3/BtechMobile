class_name BaMoveCost
extends RefCounted
## Where battle armor can go: like a 'Mech on foot (MoveCost), but never into
## water or buildings, and jumping can't land there either.
## TODO(rules): Total Warfare infantry movement costs, buildings, UMUs.


static func may_enter(tile: MapTile) -> bool:
	return tile != null and not tile.is_water() and tile.building == null


static func enter_cost(map: BattleMap, from: Vector2i, to: Vector2i, mode: int) -> int:
	if not may_enter(map.get_tile(to)):
		return MoveCost.PROHIBITED
	return MoveCost.enter_cost(map, from, to, mode)
