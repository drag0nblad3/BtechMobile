class_name Roofs
extends RefCounted
## Building roofs (book pp. 132-137). A 'Mech gets onto the roof of a
## 'Mech-scale building only by jumping; once there it walks or runs across
## roofs as if on pavement (1 MP a hex), stepping onto a roof at the same
## level or (forward only) one level lower, never up and never off to the
## ground. A 'Mech heavier than the roof's support limit makes the hex take a
## Destroy Check at +2 per weight class over. A roof that comes down drops
## the 'Mech the building's full height.
## TODO(rules): a 'Mech inside and another on the roof of the same hex; being
## shoved onto a roof; sight between roof and inside of nearby buildings.

const ROOF_MP := 1


## Level a 'Mech stands on: the hex floor, or the roof it is on.
static func floor_of(map: BattleMap, u: Unit) -> int:
	var tile := map.get_tile(u.coord)
	if tile == null:
		return 0
	if u.on_roof and has_roof(tile):
		return tile.level + tile.building.height
	return tile.floor_level()


## A 'Mech-scale building whose roof a 'Mech can stand on.
static func has_roof(tile: MapTile) -> bool:
	return tile != null and tile.building != null and not tile.building.type.civilian


## Destroy Check modifier for a 'Mech of `tons` on this roof, or -1 if the
## roof holds it without one.
## A quad counts one class lighter (Quad.support_class).
static func support_mod(b: Building, tons: int, quad := false) -> int:
	var cls := UnitDef.class_index(tons)
	var over := (maxi(0, cls - 1) if quad else cls) - b.type.roof_support
	return over * 2 if over > 0 else -1


## The 'Mech has just come down on the roof of its hex.
static func landed(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var tile := state.map.get_tile(u.coord)
	if not has_roof(tile) or u.destroyed:
		return
	u.on_roof = true
	var mod := support_mod(tile.building, u.def.tonnage, u.def.quad)
	emit.call(GameEvent.BUILDING, {"kind": "roof", "coord": u.coord, "unit_id": u.id,
			"name": tile.building.type.name, "over": mod >= 0})
	if mod >= 0 and BuildingRules.destroy_check(state, dice, emit, u.coord, 0, u.id, mod):
		BuildingRules.collapse(state, dice, emit, tile, u)


## Ground-move steps for a 'Mech on a roof: [[next_key, mp], ...].
static func successors(state: GameState, unit: Unit, k: Vector3i, mode: int) -> Array:
	var c := MoveOptions.coord_of(k)
	var f := k.z
	var out := [
		[MoveOptions.key(c, Hex.rotate(f, -1)), 1],
		[MoveOptions.key(c, Hex.rotate(f, 1)), 1],
	]
	var here := state.map.get_tile(c)
	if not has_roof(here):
		return out
	var top := here.level + here.building.height
	for back in ([false, true] if mode == MoveMode.Kind.WALK else [false]):
		var to := Hex.neighbor(c, f + (3 if back else 0))
		var tile := state.map.get_tile(to)
		if not has_roof(tile):
			continue
		var drop := top - (tile.level + tile.building.height)
		if drop == 0 or (drop == 1 and not back):
			var other := state.unit_at(to)
			if other == null or other == unit or other.side == unit.side:
				out.append([MoveOptions.key(to, f), ROOF_MP])
	return out
