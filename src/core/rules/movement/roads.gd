class_name Roads
extends RefCounted
## Road movement (book p. 53). A 'Mech moving from one paved hex to another
## pays only the base 1 MP, and a level change between the two costs 1 MP
## less (never below 0). A building hex is not road.
## TODO(rules): roads through prohibited terrain need a road drawn across it;
## our maps only mark whole paved hexes.

const TERRAIN := "pavement"


static func is_road(tile: MapTile) -> bool:
	return tile != null and tile.terrain.id == TERRAIN and tile.building == null and not tile.is_water()


## Travelling on the road: both hexes paved, a bridge deck counting as
## paved for a 'Mech on it (Bridges).
static func road_step(src: MapTile, dst: MapTile) -> bool:
	return (is_road(src) or src.bridge != null) and (is_road(dst) or Bridges.onto_deck(src, dst))


## MP for the level change when stepping between two hexes.
static func climb_cost(src: MapTile, dst: MapTile, change: int) -> int:
	return maxi(0, change - 1) if road_step(src, dst) else change
