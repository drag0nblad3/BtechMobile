class_name BuildingDamage
extends RefCounted
## Damage to building hexes during an attack phase (book pp. 135-136).
## Each attacker's damage to a hex is added up; once its attacks are done,
## a total at or over the threshold earns a Destroy Check. The damage is then
## forgotten. Destroyed hexes come down at the end of the phase. Any damage
## destroys a civilian building.


static func add(state: GameState, attacker_id: int, c: Vector2i, amount: int) -> void:
	var tile := state.map.get_tile(c)
	var b := Bridges.structure(tile)
	if b == null or amount <= 0:
		return
	if b.type.civilian:
		_doom(state, c)
		return
	var per: Dictionary = state.building_hits.get(attacker_id, {})
	per[c] = int(per.get(c, 0)) + amount
	state.building_hits[attacker_id] = per


## Destroy Checks for one attacker whose attacks are done.
static func check_attacker(state: GameState, dice: Dice, emit: Callable, attacker_id: int) -> void:
	var per: Dictionary = state.building_hits.get(attacker_id, {})
	state.building_hits.erase(attacker_id)
	for c: Vector2i in per:
		var tile := state.map.get_tile(c)
		var b := Bridges.structure(tile)
		if b == null or state.doomed_buildings.has(c):
			continue
		if int(per[c]) >= b.type.threshold \
				and BuildingRules.destroy_check(state, dice, emit, c, int(per[c]), attacker_id):
			_doom(state, c)


## End of an attack phase: remaining checks, then the destroyed hexes fall.
static func end_phase(state: GameState, dice: Dice, emit: Callable) -> void:
	for id: int in state.building_hits.keys():
		check_attacker(state, dice, emit, id)
	for c in state.doomed_buildings:
		var tile := state.map.get_tile(c)
		if tile != null and tile.building != null:
			BuildingRules.collapse(state, dice, emit, tile)
		elif tile != null and tile.bridge != null:
			Bridges.collapse(state, dice, emit, tile)
	state.doomed_buildings.clear()


static func _doom(state: GameState, c: Vector2i) -> void:
	if not state.doomed_buildings.has(c):
		state.doomed_buildings.append(c)
