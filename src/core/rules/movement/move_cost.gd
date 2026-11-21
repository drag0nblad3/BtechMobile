class_name MoveCost
extends RefCounted
## MP cost for a 'Mech to enter one hex (book pp. 46-48, 51).
## Returns PROHIBITED when the move is illegal.
## Water depth works as a level change (a water hex's level is its bottom),
## plus +1 MP for depth 1 and +2 for depth 2+. Running in is allowed but
## costs a piloting roll (MovePsr). Building hexes cost +1; who may force
## their way in is MovePlanner's check (it knows the 'Mech).

const PROHIBITED := -1
const MAX_LEVEL_CHANGE := 2


## max_change: levels allowed per hex (1 with a hip hit or a destroyed leg).
static func enter_cost(map: BattleMap, from: Vector2i, to: Vector2i, _mode: int,
		max_change: int = MAX_LEVEL_CHANGE) -> int:
	var src := map.get_tile(from)
	var dst := map.get_tile(to)
	if src == null or dst == null:
		return PROHIBITED
	var change := level_change(src, dst)
	if change > max_change:
		return PROHIBITED
	if Bridges.onto_deck(src, dst):
		return 1 + change  # a paved deck counts as road (Bridges)
	if not Bridges.fits_under(dst):
		return PROHIBITED
	var cost := 1 + dst.terrain.move_cost + change
	if dst.building != null:
		cost += 1  # every building hex (errata)
	if dst.is_water():
		cost += 1 if dst.depth == 1 else 2
	return cost


## Levels climbed or dropped between two hexes, measured at the ground
## (the bottom of water), or at a bridge deck the 'Mech is on (Bridges).
static func level_change(src: MapTile, dst: MapTile) -> int:
	var to := dst.bridge.level if Bridges.onto_deck(src, dst) else dst.floor_level()
	return absi(to - Bridges.stand_level(src))
