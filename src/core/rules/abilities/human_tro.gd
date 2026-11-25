class_name HumanTro
extends RefCounted
## Human TRO SPA (Campaign Operations p. 76): knowing every design by heart,
## the attacker adds 1 to the roll that decides whether its damage causes
## critical hits. TODO(rules): the book has the pilot pick a unit type; only
## 'Mechs take critical hits here, so it always applies.

const MOD := 1


static func mod(state: GameState, source_id: int) -> int:
	var a := state.unit_by_id(source_id) if source_id >= 0 else null
	return MOD if a != null and Spa.has(a, Spa.HUMAN_TRO) else 0
