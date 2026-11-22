class_name BuildingRules
extends RefCounted
## 'Mechs and buildings (book pp. 130-137).
## - Entering: any 'Mech flattens a civilian building. A 'Mech-scale one
##   needs a heavy enough 'Mech (MovePlanner) and a piloting roll at +1 per
##   hex; failing doesn't fall but forces a Destroy Check, and a destroyed
##   hex comes down on the 'Mech at once.
## - Inside: shots at a 'Mech take +2 if the building is at least as tall as
##   it (2 standing, 1 prone). A standing 'Mech in a level 1 building is
##   only half inside: partial cover, and hits on its legs (or on the Kick
##   table) strike the building instead.
## - Collapse: rubble; a 'Mech inside takes half the threshold per building
##   level above it, in 5-point groups from the front. No fall.
## - Careful entry: running straight into the building hex ahead as the whole
##   move needs no roll and works for any class (MovePlanner).
## - Displaced into a building: it gets in regardless of class, but the hex
##   takes a Destroy Check at once.
## - Roofs: see Roofs.
## - A 'Mech may smash in on purpose: the entry roll fails and the hex takes a
##   Destroy Check (not with careful entry).


## Building hexes a move enters, in order: ground moves enter each one on
## the path; a jump only its landing hex (civilian buildings).
static func entered(map: BattleMap, from: Vector2i, path: Array[Vector3i], jumped: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var last := from
	for i in path.size():
		var c := MoveOptions.coord_of(path[i])
		if c == last or (jumped and i < path.size() - 1):
			continue
		last = c
		var tile := map.get_tile(c)
		if tile != null and tile.building != null:
			out.append(c)
	return out


## Resolves entering one building hex (call after the move is announced).
## `smash`: deliberately fail the entry roll to force a Destroy Check.
static func enter(state: GameState, dice: Dice, emit: Callable, u: Unit, c: Vector2i,
		careful := false, smash := false) -> void:
	var tile := state.map.get_tile(c)
	if tile == null or tile.building == null or u.destroyed:
		return
	var b := tile.building
	if b.type.civilian:
		emit.call(GameEvent.BUILDING, {"kind": "flattened", "coord": c, "unit_id": u.id, "name": b.type.name})
		collapse(state, dice, emit, tile, null)
		return
	if careful:
		emit.call(GameEvent.BUILDING, {"kind": "careful", "coord": c, "unit_id": u.id, "name": b.type.name})
		return
	if not smash and Psr.roll(dice, emit, u, "forcing its way into a %s" % b.type.name.to_lower(), 1, state):
		return
	emit.call(GameEvent.BUILDING, {"kind": "smash" if smash else "entry_failed", "coord": c,
			"unit_id": u.id, "name": b.type.name})
	if destroy_check(state, dice, emit, c, 0, u.id):
		collapse(state, dice, emit, tile, u)


## A 'Mech shoved into a building hex (p. 132): it gets in, and the hex takes
## a Destroy Check straight away.
static func displaced_into(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var tile := state.map.get_tile(u.coord)
	if tile == null or tile.building == null or u.destroyed:
		return
	if tile.building.type.civilian:
		enter(state, dice, emit, u, u.coord)
		return
	emit.call(GameEvent.BUILDING, {"kind": "shoved_in", "coord": u.coord, "unit_id": u.id, "name": tile.building.type.name})
	if destroy_check(state, dice, emit, u.coord, 0, u.id):
		collapse(state, dice, emit, tile, u)


## Destroy Check: 2D6 plus 1 at 21-30 damage and 1 per further 10, against
## the class's number. Returns true if the hex is destroyed.
static func destroy_check(state: GameState, dice: Dice, emit: Callable, c: Vector2i,
		damage: int, attacker_id: int, extra := 0) -> bool:
	var b := Bridges.structure(state.map.get_tile(c))
	var roll := dice.roll_2d6()
	var mod := destroy_mod(damage) + extra
	var ok := roll + mod >= b.type.destroy_tn
	emit.call(GameEvent.BUILDING, {"kind": "destroy_check", "coord": c, "unit_id": attacker_id,
			"name": Bridges.label(b), "roll": roll, "mod": mod, "need": b.type.destroy_tn,
			"damage": damage, "destroyed": ok})
	return ok


static func destroy_mod(damage: int) -> int:
	if damage < 21:
		return 0
	@warning_ignore("integer_division")
	return 1 + (damage - 21) / 10


## +2 to hit a 'Mech inside a building at least as tall as it.
static func inside_mod(map: BattleMap, u: Unit) -> int:
	var tile := map.get_tile(u.coord)
	if tile == null or tile.building == null or tile.building.type.civilian or u.on_roof:
		return 0
	return 2 if tile.building.height >= (1 if u.prone or u.def.is_support() else 2) else 0


## A standing 'Mech half inside a level 1 'Mech-scale building.
static func half_inside(map: BattleMap, u: Unit) -> bool:
	var tile := map.get_tile(u.coord)
	return tile != null and tile.building != null and not tile.building.type.civilian \
			and tile.building.height == 1 and not u.prone and not u.on_roof and not u.def.is_support()


## The hex comes down: rubble for 'Mech-scale buildings (and civilian ones
## 4+ levels tall); a 'Mech inside takes collapse damage.
static func collapse(state: GameState, dice: Dice, emit: Callable, tile: MapTile,
		inside: Unit = null) -> void:
	var b := tile.building
	if b == null:
		return
	tile.building = null
	tile.on_fire = false  # the fire dies with the building
	if state.map.rubble != null and (not b.type.civilian or b.height >= 4):
		tile.terrain = state.map.rubble
	if inside == null:
		inside = state.unit_at(tile.coord)
	if inside != null and inside.on_roof:
		inside.on_roof = false
		emit.call(GameEvent.BUILDING, {"kind": "collapsed", "coord": tile.coord, "name": b.type.name,
				"height": b.height, "damage": 0, "unit_id": -1})
		if not inside.destroyed:
			Fall.fall(state, dice, emit, inside, b.height, "the roof gave way")
		return
	var dmg := b.collapse_damage(1 if inside != null and inside.prone else 2) if inside != null else 0
	dmg = Gravity.scale(dmg, state.conditions)
	emit.call(GameEvent.BUILDING, {"kind": "collapsed", "coord": tile.coord, "name": b.type.name,
			"height": b.height, "damage": dmg, "unit_id": inside.id if inside != null else -1})
	if inside == null or inside.destroyed:
		return
	for p in Damage.clusters(dmg, 5):
		WeaponFire.hit_with(state, dice, emit, inside, FiringArc.FRONT, p, inside.id, "falling building")
