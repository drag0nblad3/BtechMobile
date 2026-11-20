class_name FireOptions
extends RefCounted
## What one 'Mech could shoot this phase: a ToHit for each weapon against a
## target. The first target a 'Mech shoots at is its primary target; any
## other target is secondary and costs extra to hit.


## [{index, weapon: MountedWeapon, to_hit: ToHit}] for every weapon.
static func for_target(state: GameState, attacker: Unit, target: Unit,
		secondary: bool = false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in attacker.weapons.size():
		var w := attacker.weapons[i]
		out.append({"index": i, "weapon": w,
				"to_hit": ToHitCalc.weapon(state, attacker, w, target, secondary)})
	return out


## Validates shots [{weapon, target_id}] into stored declarations, dropping
## impossible ones. The first listed target is the primary.
static func declare(state: GameState, attacker: Unit, shots: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var primary := -1
	var used := {}
	for s: Dictionary in shots:
		var wi: int = s["weapon"]
		if used.has(wi) or wi < 0 or wi >= attacker.weapons.size():
			continue
		var target := state.unit_by_id(int(s["target_id"]))
		if target == null or target.side == attacker.side:
			continue
		if primary < 0:
			primary = target.id
		var th := ToHitCalc.weapon(state, attacker, attacker.weapons[wi], target,
				target.id != primary)
		if not th.possible():
			continue
		used[wi] = true
		out.append({"attacker_id": attacker.id, "weapon_index": wi,
				"target_id": target.id, "to_hit": th})
	return out


## Heat this volley would add (weapon heat only).
static func volley_heat(attacker: Unit, weapon_indexes: Array) -> int:
	var h := 0
	for i: int in weapon_indexes:
		h += attacker.weapons[i].def.heat
	return h
