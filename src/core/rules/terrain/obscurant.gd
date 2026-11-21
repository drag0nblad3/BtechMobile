class_name Obscurant
extends RefCounted
## Smoke and fog in a hex (book p. 124). Light smoke/fog acts as light woods
## for line of sight and to-hit, heavy as heavy woods, two levels above the
## ground (a burning building's smoke reaches 2 above its roof). They only
## partly stack: with woods and each other a hex never passes +2 to hit or
## 2 line-of-sight points. A burning hex is light smoke. Map data marks fog
## hexes ("fog": {"light": [...], "heavy": [...]}). Wind blows all of it away.

const CAP := 2
const HEIGHT := 2


## Smoke/fog points in a hex (0-2), ignoring woods.
static func value(map: BattleMap, tile: MapTile, smoke := true) -> int:
	if tile == null or map.windy:
		return 0
	return mini(CAP, tile.fog + (1 if smoke and tile.on_fire else 0))


## Extra to-hit on a 'Mech in this hex on top of its woods value.
static func to_hit_mod(map: BattleMap, u: Unit, woods: int) -> int:
	var tile := map.get_tile(u.coord)
	var inside_fire := tile != null and tile.building != null and not u.on_roof
	var v := value(map, tile, not inside_fire)
	return maxi(0, mini(CAP, woods + v) - woods) if v > 0 else 0


## Name for logs: "fog" when fog is present, else "smoke".
static func name_of(tile: MapTile) -> String:
	return "fog" if tile != null and tile.fog > 0 else "smoke"
