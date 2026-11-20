class_name WeaponFire
extends RefCounted
## Resolves one declared weapon shot: ammo, heat, to-hit roll, cluster roll,
## hit locations and damage. `emit` is GameController._emit (type, data).


## Resolves every shot declared this phase, in declaration order.
static func resolve_declared(state: GameState, dice: Dice, emit: Callable) -> void:
	for d in state.declared_fire:
		var a := state.unit_by_id(d["attacker_id"])
		if d.has("target_hex"):
			BuildingFire.resolve(state, dice, emit, a, a.weapons[d["weapon_index"]], d["target_hex"], d["to_hit"])
			continue
		resolve(state, dice, emit, a, a.weapons[d["weapon_index"]],
				state.unit_by_id(d["target_id"]), d["to_hit"])
	state.declared_fire.clear()


static func resolve(state: GameState, dice: Dice, emit: Callable, attacker: Unit,
		w: MountedWeapon, target: Unit, th: ToHit) -> void:
	if w.def.uses_ammo() and not attacker.use_ammo(w.def):
		emit.call(GameEvent.WEAPON_FIRED, {"attacker_id": attacker.id, "target_id": target.id,
				"weapon": w.def.name, "weapon_id": w.def.id, "roll": 0, "need": th.target(),
				"hit": false, "no_ammo": true, "mods": th.mods, "missiles": 0})
		return
	w.fired = true
	attacker.heat_generated += w.def.heat
	var roll := dice.roll_2d6()
	var need := th.target()
	var hit := roll >= need
	var data := {"attacker_id": attacker.id, "target_id": target.id, "weapon": w.def.name,
			"weapon_id": w.def.id, "roll": roll, "need": need, "hit": hit,
			"mods": th.mods, "missiles": 0}
	if not hit:
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	var arc_id := FiringArc.arc(target.coord, target.facing, attacker.coord)
	var packets: Array[int] = [w.def.damage]
	if w.def.is_cluster():
		var cr := dice.roll_2d6()
		var n := ClusterTable.hits(w.def.missiles, cr)
		data["missiles"] = n
		data["cluster_roll"] = cr
		packets = Damage.clusters(n * w.def.damage, w.def.group * w.def.damage)
	if w.def.heat_damage:  # flamers: the same amount as heat too (book p. 183)
		data["heat_added"] = w.def.damage
		target.outside_heat += w.def.damage
	emit.call(GameEvent.WEAPON_FIRED, data)
	for p in packets:
		hit_with(state, dice, emit, target, arc_id, p, attacker.id, w.def.name)


## Rolls a hit location and applies one packet of damage. Building walls
## around the target soak part of it first.
static func hit_with(state: GameState, dice: Dice, emit: Callable, target: Unit,
		arc_id: int, amount: int, source_id: int, source: String,
		hl: Dictionary = {}, through_walls: bool = true) -> void:
	var tile := state.map.get_tile(target.coord)
	if through_walls and tile != null and tile.building != null:
		amount = BuildingRules.absorb(state, dice, emit, tile, amount, target)
		if amount <= 0 or target.destroyed:
			return
	if hl.is_empty():
		hl = HitTable.roll(dice, arc_id)
	var loc: int = hl["loc"]
	if Location.is_leg(loc) and ToHitCalc.in_partial_cover(state.map, target):
		emit.call(GameEvent.DAMAGE, {"unit_id": target.id, "source_id": source_id,
				"source": source, "amount": amount, "loc": loc, "steps": [], "covered": true})
		return
	var steps := Damage.apply(target, loc, amount, hl["rear"])
	emit.call(GameEvent.DAMAGE, {"unit_id": target.id, "source_id": source_id,
			"source": source, "amount": amount, "loc": loc, "rear": hl["rear"],
			"steps": steps, "covered": false, "tac": hl["tac"]})
	Damage.announce(emit, target)
	HeadHit.check(dice, emit, target, steps)
	CriticalHits.after_damage(state, dice, emit, target, steps, hl["tac"])
