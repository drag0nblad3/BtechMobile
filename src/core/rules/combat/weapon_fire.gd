class_name WeaponFire
extends RefCounted
## Resolves one declared weapon shot: ammo, heat, to-hit roll, cluster roll,
## hit locations and damage. `emit` is GameController._emit (type, data).


## Resolves every shot declared this phase, in declaration order.
## Each attacker's building damage is checked once its shots are done.
static func resolve_declared(state: GameState, dice: Dice, emit: Callable) -> void:
	var prev := -1
	for d in state.declared_fire:
		var a := state.unit_by_id(d["attacker_id"])
		if a.id != prev and prev >= 0:
			BuildingDamage.check_attacker(state, dice, emit, prev)
		prev = a.id
		if d.has("target_hex"):
			BuildingFire.resolve(state, dice, emit, a, a.weapons[d["weapon_index"]], d["target_hex"], d["to_hit"])
			continue
		resolve(state, dice, emit, a, a.weapons[d["weapon_index"]],
				state.unit_by_id(d["target_id"]), d["to_hit"])
	state.declared_fire.clear()
	BuildingDamage.end_phase(state, dice, emit)


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
		var hl := {}
		if th.legs_only:
			hl = HitTable.roll_kick(dice, arc_id)
			hl["no_cover"] = true
		hit_with(state, dice, emit, target, arc_id, p, attacker.id, w.def.name, hl, th.cover_hex)


## Rolls a hit location and applies one packet of damage. `cover` is a hill
## or building hex giving partial cover: leg hits strike it. `hl.no_cover`
## skips water partial cover (kicks on the Kick table, charges). A standing
## 'Mech half inside a level 1 building has its leg hits, and any Kick table
## hit, taken by the building (charges excepted).
static func hit_with(state: GameState, dice: Dice, emit: Callable, target: Unit,
		arc_id: int, amount: int, source_id: int, source: String,
		hl: Dictionary = {}, cover: Vector2i = Hex.INVALID) -> void:
	if hl.is_empty():
		hl = HitTable.roll(dice, arc_id)
	if cover != Hex.INVALID and Location.is_leg(hl["loc"]):
		var ct := state.map.get_tile(cover)
		if ct != null and ct.building != null:
			emit.call(GameEvent.BUILDING, {"kind": "cover_hit", "coord": cover, "unit_id": target.id,
					"name": ct.building.type.name, "damage": amount})
			BuildingDamage.add(state, source_id, cover, amount)
		else:
			emit.call(GameEvent.DAMAGE, {"unit_id": target.id, "source_id": source_id,
					"source": source, "amount": amount, "loc": hl["loc"], "steps": [], "covered": true, "hill": true})
		return
	if BuildingRules.half_inside(state.map, target) and not hl.get("charge", false) \
			and (Location.is_leg(hl["loc"]) or hl.get("kick_table", false)):
		emit.call(GameEvent.BUILDING, {"kind": "cover_hit", "coord": target.coord, "unit_id": target.id,
				"name": state.map.get_tile(target.coord).building.type.name, "damage": amount})
		BuildingDamage.add(state, source_id, target.coord, amount)
		return
	var loc: int = hl["loc"]
	if Location.is_leg(loc) and not hl.get("no_cover", false) and ToHitCalc.in_partial_cover(state.map, target):
		emit.call(GameEvent.DAMAGE, {"unit_id": target.id, "source_id": source_id,
				"source": source, "amount": amount, "loc": loc, "steps": [], "covered": true})
		return
	var steps := Damage.apply(target, loc, amount, hl["rear"])
	emit.call(GameEvent.DAMAGE, {"unit_id": target.id, "source_id": source_id,
			"source": source, "amount": amount, "loc": loc, "rear": hl["rear"],
			"steps": steps, "covered": false, "tac": hl["tac"]})
	Damage.announce(emit, target)
	HeadHit.check(dice, emit, target, steps)
	HullBreach.after_damage(state, dice, emit, target, steps)
	CriticalHits.after_damage(state, dice, emit, target, steps, hl["tac"])
