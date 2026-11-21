class_name Fire
extends RefCounted
## Fire and its smoke (book pp. 123-124, 136). A burning hex stays on fire
## for the battle (a building's fire goes out when it collapses). Moving
## through one adds 2 heat a hex (not when jumping over), ending the turn
## in one adds 5 in the Heat Phase. A burning hex is also light smoke, two
## levels above the ground (or the roof): +1 to hit a 'Mech in it and 1 point
## of the woods-style line-of-sight count, never past 2 per hex with woods;
## no smoke modifier for a 'Mech inside the burning building. Heat-causing
## hits (flamers) on a 'Mech-scale building start a fire once a phase's total
## reaches its class's fire heat per level x its height.
## Woods are lit the same way (WoodsFire). TODO(rules): smoke from other sources.

const MOVE_HEAT := 2
const STAND_HEAT := 5
const SMOKE_HEIGHT := 2
const SMOKE_CAP := 2


## Heat needed in one phase to light a building hex, or -1 if it can't burn.
static func heat_to_light(tile: MapTile) -> int:
	if WoodsFire.can_light(tile):
		return WoodsFire.HEAT_TO_LIGHT
	if tile == null or tile.building == null or tile.building.type.civilian:
		return -1
	return tile.building.type.fire_heat * tile.building.height


## Heat dealt to a hex this phase (flamer hits on a building or woods).
static func add_heat(state: GameState, c: Vector2i, heat: int) -> void:
	if heat > 0 and heat_to_light(state.map.get_tile(c)) > 0:
		state.fire_heat[c] = int(state.fire_heat.get(c, 0)) + heat


## End of an attack phase: hexes that took enough heat catch fire.
static func end_phase(state: GameState, emit: Callable) -> void:
	for c: Vector2i in state.fire_heat:
		var tile := state.map.get_tile(c)
		var need := heat_to_light(tile)
		if need > 0 and not tile.on_fire and int(state.fire_heat[c]) >= need:
			tile.on_fire = true
			var what := tile.building.type.name if tile.building != null else tile.terrain.name
			emit.call(GameEvent.BUILDING, {"kind": "fire", "coord": c, "name": what,
					"heat": state.fire_heat[c], "need": need})
	state.fire_heat.clear()


## Heat from burning hexes entered on a ground move.
static func move_heat(map: BattleMap, path: Array[Vector3i], from: Vector2i, jumped: bool) -> int:
	if jumped:
		return 0
	var heat := 0
	var last := from
	for k in path:
		var c := MoveOptions.coord_of(k)
		if c != last:
			var tile := map.get_tile(c)
			if tile != null and tile.on_fire:
				heat += MOVE_HEAT
			last = c
	return heat


static func stand_heat(map: BattleMap, u: Unit) -> int:
	var tile := map.get_tile(u.coord)
	return STAND_HEAT if tile != null and tile.on_fire else 0


## Smoke to-hit modifier on a 'Mech in this hex, given its woods value.
static func smoke_mod(map: BattleMap, u: Unit, woods: int) -> int:
	var tile := map.get_tile(u.coord)
	if tile == null or not tile.on_fire or woods >= SMOKE_CAP:
		return 0
	if tile.building != null and not u.on_roof:
		return 0  # inside the burning building
	return 1


## Top of a burning hex's smoke column.
static func smoke_top(tile: MapTile) -> int:
	var b := 0 if tile.building == null else tile.building.height
	return tile.level + b + SMOKE_HEIGHT
