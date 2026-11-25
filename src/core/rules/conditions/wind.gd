class_name Wind
extends RefCounted
## Wind (book p. 121). Every piloting roll of a 'Mech not inside a building
## gets +1 (a roof is outside). Jumps work differently: a 'Mech that jumps
## (and isn't making a death from above) rolls at +1 on landing and a
## failure is a 1-level fall; its other jump rolls don't add the wind. After
## a successful death from above the attacker's roll gets the usual +1, and
## if the attacker falls from a DFA, hit or miss, it falls one level more.
## Smoke and fog can't exist in the wind (Obscurant).

const MOD := 1


## Adds the wind to a piloting roll unless the 'Mech is sheltered inside a building.
static func add(th: ToHit, state: GameState, u: Unit) -> void:
	if not applies(state, u):
		return
	EnvSpecialist.add_psr(th, u, EnvSpecialist.WIND, "wind", MOD, "Gale-force wind pushes the 'Mech around: +1 to every piloting roll outside buildings.")


static func applies(state: GameState, u: Unit) -> bool:
	if state == null or not state.conditions.wind:
		return false
	var tile := state.map.get_tile(u.coord)
	return tile == null or tile.building == null or u.on_roof


## The roll for landing a jump in the wind, or {} without wind or for a DFA.
static func landing_roll(c: Conditions, dfa: bool) -> Dictionary:
	if c == null or not c.wind or dfa:
		return {}
	return {"reason": "landing a jump in the wind", "mod": MOD, "jump": true, "fall_levels": 1}


## Extra levels for an attacker falling from a death from above.
static func dfa_fall_levels(state: GameState) -> int:
	return 1 if state != null and state.conditions.wind else 0
