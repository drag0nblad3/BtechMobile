class_name VehicleMoveCost
extends RefCounted
## MP for a combat vehicle to enter one hex: 1, + 1 per level changed (one
## level a hex at most), + terrain. Tracked vehicles pay the 'Mech terrain
## costs; wheeled and hover vehicles can't enter woods and pay +2 in rough
## or rubble. Only hovercraft cross water (as clear, on the surface).
## Roads and bridge decks cost the base MP. No vehicle enters buildings.
## TODO(rules): Total Warfare's vehicle terrain table from general
## knowledge; buildings, ice/mud/snow and skidding not modelled.

const PROHIBITED := MoveCost.PROHIBITED


static func enter_cost(map: BattleMap, u: Unit, from: Vector2i, to: Vector2i) -> int:
	var src := map.get_tile(from)
	var dst := map.get_tile(to)
	if src == null or dst == null or not may_enter(u.def.vehicle.motive, dst):
		return PROHIBITED
	var m := u.def.vehicle.motive
	var change := absi(level(m, dst) - level(m, src))
	if Bridges.onto_deck(src, dst):
		change = absi(dst.bridge.level - level(m, src))
	if change > 1:
		return PROHIBITED
	if Bridges.onto_deck(src, dst) or Roads.road_step(src, dst):
		return 1 + change
	if not Bridges.fits_under(dst):
		return PROHIBITED
	var terrain := dst.terrain.move_cost
	if m != "t" and dst.terrain.id in ["rough", "rubble"]:
		terrain = 2
	return 1 + change + (0 if m == "h" and dst.is_water() else terrain)


static func may_enter(motive: String, tile: MapTile) -> bool:
	if tile.building != null:
		return false
	if tile.is_water() and tile.depth >= 1 and motive != "h":
		return false
	if motive != "t" and tile.terrain.id in ["light_woods", "heavy_woods"]:
		return false
	return true


## The level a vehicle drives at: hovercraft ride the water's surface.
static func level(motive: String, tile: MapTile) -> int:
	return tile.level if motive == "h" and tile.is_water() else tile.floor_level()
