class_name BaFire
extends RefCounted
## Shooting by and at battle armor. A squad fires in any direction; each of
## its weapons is one attack, rolled on the Cluster Hits table with one
## shot per living trooper (BaSpec). Battle armor is small and hard to
## hit: +1. TODO(rules): Total Warfare battle armor fire from general knowledge.

const TARGET_MOD := 1


static func add_target_mod(th: ToHit, target: Unit) -> void:
	if target.ba != null:
		th.add("battle armor", TARGET_MOD, "Armored infantry are small, spread-out targets: +1.")


## Why squad `a` can't attack at all this turn, or "".
static func problem(state: GameState, a: Unit) -> String:
	if a.ba != null and a.ba.deployed_turn == state.turn:
		return "Battle armor can't attack on the turn it climbs down from a 'Mech"
	return ""
