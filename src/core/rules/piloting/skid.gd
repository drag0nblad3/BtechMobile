class_name Skid
extends RefCounted
## Skidding: a running 'Mech that turns on pavement must make a piloting roll.
## On a failure it slides on in its old direction, then falls.
## TODO(rules): only the first such turn is rolled; slide = half the hexes
## moved so far (rounded up), stopping at anything solid; verify modifiers.


## First turn on pavement during a run: {index, mod, dir, hexes} or {}.
## `index` is the path position of the turning step.
static func find(map: BattleMap, path: Array[Vector3i], from: Vector3i, mode: int) -> Dictionary:
	if mode != MoveMode.Kind.RUN:
		return {}
	var hexes := 0
	var prev := from
	for i in path.size():
		var k := path[i]
		var c := MoveOptions.coord_of(k)
		if c != MoveOptions.coord_of(prev):
			hexes += 1
		elif k.z != prev.z and hexes > 0:
			var tile := map.get_tile(c)
			if tile != null and tile.terrain.id == "pavement":
				return {"index": i, "mod": modifier(hexes), "dir": prev.z, "hexes": hexes}
		prev = k
	return {}


## Faster 'Mechs skid more easily.
static func modifier(hexes: int) -> int:
	if hexes <= 2:
		return -1
	if hexes <= 4:
		return 0
	if hexes <= 7:
		return 1
	if hexes <= 10:
		return 2
	if hexes <= 17:
		return 4
	return 5 if hexes <= 24 else 6


## Slides `u` up to ceil(hexes / 2) hexes toward `dir`, then it falls.
static func slide(state: GameState, dice: Dice, emit: Callable, u: Unit, dir: int, hexes: int) -> void:
	var want := ceili(hexes / 2.0)
	var moved := 0
	var facing := u.facing
	for i in want:
		var next := state.map.get_tile(Hex.neighbor(u.coord, dir))
		if next != null and next.building != null:
			break
		if not Displacement.push(state, emit, u, dir):
			break
		moved += 1
	u.facing = facing
	emit.call(GameEvent.SKID, {"unit_id": u.id, "hexes": moved, "wanted": want})
	Fall.fall(state, dice, emit, u, 0, "skidded")
