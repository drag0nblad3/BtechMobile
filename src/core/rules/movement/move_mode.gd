class_name MoveMode
extends RefCounted
## Movement modes and what each costs: MP budget, heat and the penalty to
## the mover's own shots this turn.

enum Kind { WALK, RUN, JUMP }

const NAMES := ["Walk", "Run", "Jump"]
const VERBS := ["walked", "ran", "jumped"]
const VEHICLE_NAMES := ["Cruise", "Flank"]
const VEHICLE_VERBS := ["cruised", "flanked"]


static func name_of(k: int) -> String:
	return NAMES[k] if k >= 0 and k < NAMES.size() else "-"


static func verb(k: int) -> String:
	return VERBS[k] if k >= 0 and k < VERBS.size() else "stood still"


## The verb for this unit: combat vehicles cruise and flank (TODO(rules)).
static func verb_for(u: Unit, k: int) -> String:
	if u != null and u.vehicle != null and k >= 0 and k < VEHICLE_VERBS.size():
		return VEHICLE_VERBS[k]
	return verb(k)


## MP available this turn, after heat and damage. Standing up costs 2 MP.
static func budget(unit: Unit, k: int) -> int:
	if k == Kind.JUMP:
		return 0 if unit.prone else unit.jump_mp()
	var mp := unit.run_mp() if k == Kind.RUN else unit.walk_mp()
	return mp - (2 if unit.prone else 0)


## To-hit penalty on the mover's own attacks (-1 = stood still).
static func attacker_mod(k: int) -> int:
	match k:
		Kind.WALK:
			return 1
		Kind.RUN:
			return 2
		Kind.JUMP:
			return 3
	return 0


## Heat built by moving: walk 1, run 2, jump 1 per hex (minimum 3;
## improved jump jets halve it, JumpJets).
static func heat(k: int, hexes: int, improved_jets := false) -> int:
	match k:
		Kind.WALK:
			return 1
		Kind.RUN:
			return 2
		Kind.JUMP:
			return JumpJets.heat(hexes, improved_jets)
	return 0
