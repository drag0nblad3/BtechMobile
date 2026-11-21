class_name FireOptions
extends RefCounted
## What one 'Mech could shoot this phase: a ToHit for each weapon against a
## target. A 'Mech has one primary target per turn; any other target is
## secondary and costs +1 to hit (book p. 64). If any target is in the
## forward arc, the primary must be one of those.


## [{index, weapon: MountedWeapon, to_hit: ToHit}] for every weapon.
static func for_target(state: GameState, attacker: Unit, target: Unit,
		secondary: bool = false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in attacker.weapons.size():
		var w := attacker.weapons[i]
		out.append({"index": i, "weapon": w,
				"to_hit": ToHitCalc.weapon(state, attacker, w, target, secondary)})
	return out


## Validates shots [{weapon, target_id}] (or [{weapon, hex}] for a building)
## into stored declarations, dropping impossible ones.
static func declare(state: GameState, attacker: Unit, shots: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var primary := primary_target(state, attacker, shots)
	var used := {}
	for s: Dictionary in shots:
		var wi: int = s["weapon"]
		if used.has(wi) or wi < 0 or wi >= attacker.weapons.size():
			continue
		if s.has("hex"):  # shooting a building
			var bth := BuildingFire.to_hit(state, attacker, attacker.weapons[wi], s["hex"])
			if bth.possible():
				used[wi] = true
				out.append({"attacker_id": attacker.id, "weapon_index": wi, "target_id": -1,
						"target_hex": s["hex"], "to_hit": bth})
			continue
		var target := state.unit_by_id(int(s["target_id"]))
		if target == null or target.side == attacker.side:
			continue
		var th := ToHitCalc.weapon(state, attacker, attacker.weapons[wi], target,
				target.id != primary)
		var aim := int(s.get("aim", -1))
		if aim >= 0 and th.possible() and AimedShot.problem(state, attacker.weapons[wi], target, aim, th) == "":
			AimedShot.adjust(th, aim, attacker.weapons[wi])
		if not th.possible():
			continue
		used[wi] = true
		out.append({"attacker_id": attacker.id, "weapon_index": wi,
				"target_id": target.id, "to_hit": th})
	return out


## Id of the primary 'Mech target among shots: the first one in the forward
## arc, else the first listed. -1 if no 'Mech is targeted.
static func primary_target(state: GameState, attacker: Unit, shots: Array) -> int:
	var first := -1
	for s: Dictionary in shots:
		if s.has("hex"):
			continue
		var t := state.unit_by_id(int(s["target_id"]))
		if t == null or t.side == attacker.side:
			continue
		if FiringArc.fire_arc(attacker.coord, attacker.torso_facing(), t.coord) == FiringArc.FRONT:
			return t.id
		if first < 0:
			first = t.id
	return first


## Shot list for the FIRE_DECLARED event: [{weapon, target_id, need, target_hex?}].
static func summary(unit: Unit, decl: Array[Dictionary]) -> Array:
	var out := []
	for d in decl:
		var sh := {"weapon": unit.weapons[d["weapon_index"]].def.name,
				"target_id": d["target_id"], "need": d["to_hit"].target()}
		if d.has("target_hex"):
			sh["target_hex"] = d["target_hex"]
		if d["to_hit"].aim_loc >= 0:
			sh["aim"] = d["to_hit"].aim_loc
		out.append(sh)
	return out


## Heat this volley would add (weapon heat only).
static func volley_heat(attacker: Unit, weapon_indexes: Array) -> int:
	var h := 0
	for i: int in weapon_indexes:
		var w := attacker.weapons[i]
		h += w.def.heat * WeaponModes.shots(w)
	return h
