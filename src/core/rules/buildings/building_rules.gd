class_name BuildingRules
extends RefCounted
## 'Mechs and buildings: pushing in, fighting from inside, bringing one down.
## TODO(rules): simplified. A 'Mech heavier than a building's remaining CF
## brings it down on entering (and stops there); otherwise it makes a piloting
## roll and takes CF/10 damage on a failure. Walls soak CF/10 of each hit on a
## 'Mech inside and take the whole hit. A collapse is a fall from the roof.


## Hexes along a move where the 'Mech enters a building, cut short at the
## first one too weak to hold it. Returns {path, entered: [Vector2i], collapse: bool}.
static func plan_entry(map: BattleMap, u: Unit, path: Array[Vector3i], jumped: bool) -> Dictionary:
	var out_path: Array[Vector3i] = []
	var entered: Array[Vector2i] = []
	var last := u.coord
	for i in path.size():
		var k := path[i]
		out_path.append(k)
		var c := MoveOptions.coord_of(k)
		if c == last or (jumped and i < path.size() - 1):
			continue
		last = c
		var tile := map.get_tile(c)
		if tile == null or tile.building == null:
			continue
		entered.append(c)
		if u.def.tonnage > tile.building.cf:
			return {"path": out_path, "entered": entered, "collapse": true}
	return {"path": out_path, "entered": entered, "collapse": false}


## Resolves entering one building hex (call after the move is announced).
static func enter(state: GameState, dice: Dice, emit: Callable, u: Unit, c: Vector2i) -> void:
	var tile := state.map.get_tile(c)
	if tile == null or tile.building == null or u.destroyed:
		return
	var b := tile.building
	if u.def.tonnage > b.cf:
		emit.call(GameEvent.BUILDING, {"kind": "overweight", "coord": c, "unit_id": u.id,
				"name": b.type.name, "cf": b.cf})
		collapse(state, dice, emit, tile, u)
		return
	if Psr.roll(dice, emit, u, "pushing into a %s" % b.type.name.to_lower(), b.type.psr_mod):
		return
	var dmg := b.absorbs()
	emit.call(GameEvent.BUILDING, {"kind": "scraped", "coord": c, "unit_id": u.id,
			"name": b.type.name, "damage": dmg})
	for p in Damage.clusters(dmg, 5):
		WeaponFire.hit_with(state, dice, emit, u, FiringArc.FRONT, p, u.id, b.type.name, {}, false)


## A hit on a 'Mech inside: the walls take it and soak part of it.
## Returns the damage that still reaches the 'Mech.
static func absorb(state: GameState, dice: Dice, emit: Callable, tile: MapTile, amount: int,
		u: Unit) -> int:
	var b := tile.building
	var soak := mini(amount, b.absorbs())
	b.cf = maxi(0, b.cf - amount)
	emit.call(GameEvent.BUILDING, {"kind": "absorbed", "coord": tile.coord, "unit_id": u.id,
			"name": b.type.name, "damage": amount, "absorbed": soak, "cf": b.cf})
	if b.cf == 0:
		collapse(state, dice, emit, tile, u)
	return amount - soak


## The building comes down: the hex turns to rubble and whoever is inside falls.
static func collapse(state: GameState, dice: Dice, emit: Callable, tile: MapTile,
		inside: Unit = null) -> void:
	var b := tile.building
	tile.building = null
	if state.map.rubble != null:
		tile.terrain = state.map.rubble
	emit.call(GameEvent.BUILDING, {"kind": "collapsed", "coord": tile.coord,
			"name": b.type.name, "height": b.height})
	if inside == null:
		inside = state.unit_at(tile.coord)
	if inside != null and not inside.destroyed:
		Fall.fall(state, dice, emit, inside, b.height, "the building came down")
