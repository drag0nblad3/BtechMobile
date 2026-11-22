class_name AreaEffect
extends RefCounted
## Area-effect damage (book p. 181) and artillery scatter (pp. 155, 182).
## An AE blast hits every unit, friend or foe, in a hex of the struck hex's
## level or one higher (a unit in a lower hex only if its LOS level reaches
## those levels), never a fully submerged one; buildings in the hex take the
## damage too. Damage goes in 5-point groups, each its own hit location; the
## ring around the struck hex is hit from the struck hex's direction.
## TODO(rules): which way each scatter-diagram number points is our reading.

const GROUP := 5


## Is `u` caught by a blast whose struck hex is at `base` level?
static func reaches(state: GameState, u: Unit, base: int) -> bool:
	if u.destroyed or EndPhase.submerged(state, u) or u.carrier_id() >= 0:
		return false
	var t := state.map.get_tile(u.coord)
	if t == null:
		return false
	if t.level >= base:
		return t.level <= base + 1
	var top := LineOfSight.los_level(state.map, u)
	return top >= base and top <= base + 1


## `damage` to everything in `c`, hit from `from` (a hex).
static func blast(state: GameState, dice: Dice, emit: Callable, c: Vector2i, from: Vector2i, damage: int,
		base: int, source_id: int, source: String) -> void:
	if damage <= 0 or state.map.get_tile(c) == null:
		return
	for u in state.units.duplicate():
		if u.coord != c or not reaches(state, u, base):
			continue
		var arc_id := FiringArc.arc(u.coord, u.facing, from) if from != c else FiringArc.FRONT
		var left := damage
		while left > 0 and not u.destroyed:
			WeaponFire.hit_with(state, dice, emit, u, arc_id, mini(GROUP, left), source_id, source, {}, Hex.INVALID, ["AE"])
			left -= GROUP
	var tile := state.map.get_tile(c)
	if tile.building != null:
		emit.call(GameEvent.BUILDING, {"kind": "shot", "coord": c, "name": tile.building.type.name,
				"damage": damage, "unit_id": source_id})
		BuildingDamage.add(state, source_id, c, damage)


## Struck hex and the ring around it.
static func strike(state: GameState, dice: Dice, emit: Callable, c: Vector2i, from: Vector2i,
		center: int, ring: int, source_id: int, source: String) -> void:
	var tile := state.map.get_tile(c)
	if tile == null:
		return
	blast(state, dice, emit, c, from, center, tile.level, source_id, source)
	for f in 6:
		blast(state, dice, emit, Hex.neighbor(c, f), c, ring, tile.level, source_id, source)


## Where a missed shot lands: `dist` hexes in the 1D6 direction (1 = on
## past the target, then clockwise), stopping at the last hex `in_arc`
## allows. Returns Hex.INVALID if it leaves the map.
static func scatter(state: GameState, roll: int, from: Vector2i, c: Vector2i, dist: int, in_arc: Callable) -> Vector2i:
	var dir := Hex.rotate(Hex.direction_to(from, c), roll - 1)
	var at := c
	for i in dist:
		var next := Hex.neighbor(at, dir)
		if not in_arc.call(next):
			break
		at = next
		if state.map.get_tile(at) == null:
			return Hex.INVALID
	return at
