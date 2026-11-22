class_name Bridges
extends RefCounted
## Bridges (book pp. 53, 131, 134-137).
## - A bridge hex has a deck at its own level over water or lower ground.
##   On the deck a paved bridge costs 1 MP like a road (plus any level
##   change), and a 'Mech on it is out of the water.
## - Underneath: a 'Mech may pass under if its top (its LOS level) is no
##   higher than the deck; otherwise the hex is closed to it at ground level.
## - Nobody goes inside a bridge. Its deck holds 'Mechs like a roof of its
##   class; a heavier 'Mech makes the hex take a Destroy Check at +2 per class.
## - It can be shot like a building. A hex that comes down drops a 'Mech on
##   the deck the full height and hits one underneath as a building one
##   level above it. Losing more than half its hexes brings a bridge down.
## - Bridges never block line of sight.
## TODO(rules): which layer a 'Mech takes is decided by where it steps in
## from: onto the deck from dry ground or another deck within its climb
## limit, otherwise underneath. Walking along under a multi-hex bridge is
## not supported. A jump onto a bridge hex lands on the deck. A deck that
## gives way mid-move doesn't stop the move.


## Level a 'Mech stands on in this hex when moving: the deck if there is one.
static func stand_level(t: MapTile) -> int:
	return t.bridge.level if t.bridge != null else t.floor_level()


## Stepping from `src` into `dst`: does the 'Mech go onto the deck?
static func onto_deck(src: MapTile, dst: MapTile) -> bool:
	if dst.bridge == null:
		return false
	if src.bridge != null:
		return true
	return not src.is_water() and absi(dst.bridge.level - src.floor_level()) <= MoveCost.MAX_LEVEL_CHANGE


## Room for a standing 'Mech (2 levels tall) under the deck.
static func fits_under(t: MapTile) -> bool:
	return t.bridge == null or t.floor_level() + 1 <= t.bridge.level


## Is the 'Mech in the water after stepping from `src` into `dst`?
static func wet(src: MapTile, dst: MapTile) -> bool:
	return dst.is_water() and not onto_deck(src, dst)


## Will the 'Mech end this move on the deck of its final hex?
static func ends_on_deck(map: BattleMap, from: Vector2i, path: Array[Vector3i], jumped: bool) -> bool:
	var entered := decks_entered(map, from, path, jumped)
	return not path.is_empty() and not entered.is_empty() \
			and entered[-1] == MoveOptions.coord_of(path[-1])


## Bridge hexes whose deck the move steps onto, in order.
static func decks_entered(map: BattleMap, from: Vector2i, path: Array[Vector3i], jumped: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var last := from
	for i in path.size():
		var c := MoveOptions.coord_of(path[i])
		if c == last or (jumped and i < path.size() - 1):
			continue
		var dst := map.get_tile(c)
		if dst != null and dst.bridge != null and (jumped or onto_deck(map.get_tile(last), dst)):
			out.append(c)
		last = c
	return out


## The 'Mech has stepped onto the deck at `c`: too heavy, and it may give way.
static func check_support(state: GameState, dice: Dice, emit: Callable, u: Unit, c: Vector2i) -> void:
	var tile := state.map.get_tile(c)
	if tile == null or tile.bridge == null or u.destroyed:
		return
	var mod := Roofs.support_mod(tile.bridge, u.def.tonnage, u.def.quad)
	if mod < 0:
		return
	emit.call(GameEvent.BUILDING, {"kind": "bridge_heavy", "coord": c, "unit_id": u.id,
			"name": label(tile.bridge)})
	if BuildingRules.destroy_check(state, dice, emit, c, 0, u.id, mod):
		collapse(state, dice, emit, tile)


## "Medium bridge" for a bridge, the class name for a building.
static func label(b: Building) -> String:
	return b.type.name.replace("building", "bridge") if b is Bridge else b.type.name


## The building or bridge that can be shot at this hex, if any.
static func structure(t: MapTile) -> Building:
	if t == null:
		return null
	return t.building if t.building != null else t.bridge


## The bridge hex comes down, and the rest of the bridge if over half is gone.
static func collapse(state: GameState, dice: Dice, emit: Callable, tile: MapTile) -> void:
	var b := tile.bridge
	if b == null:
		return
	tile.bridge = null
	var u := state.unit_at(tile.coord)
	var dmg := 0
	if u != null and not u.on_bridge:
		@warning_ignore("integer_division")
		dmg = Gravity.scale(b.type.threshold / 2, state.conditions)
	emit.call(GameEvent.BUILDING, {"kind": "bridge_collapsed", "coord": tile.coord, "name": label(b),
			"damage": dmg, "unit_id": u.id if u != null else -1})
	if u != null and not u.destroyed:
		if u.on_bridge:
			u.on_bridge = false
			Fall.fall(state, dice, emit, u, maxi(0, b.level - tile.floor_level()), "the bridge gave way")
		else:
			for p in Damage.clusters(dmg, 5):
				WeaponFire.hit_with(state, dice, emit, u, FiringArc.FRONT, p, u.id, "falling bridge")
	var standing: Array[MapTile] = []
	for c: Vector2i in b.span:
		var t := state.map.get_tile(c)
		if t.bridge != null and is_same(t.bridge.span, b.span):
			standing.append(t)
	if (b.span.size() - standing.size()) * 2 > b.span.size():
		for t in standing:
			collapse(state, dice, emit, t)
