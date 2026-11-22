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
	PpcCapacitor.end_phase(state, emit)
	BuildingDamage.end_phase(state, dice, emit)
	Fire.end_phase(state, emit)
	RotaryAc.resolve_unjams(state, dice, emit)


static func resolve(state: GameState, dice: Dice, emit: Callable, attacker: Unit,
		w: MountedWeapon, target: Unit, th: ToHit) -> void:
	var kind := WeaponModes.ammo_kind(w)
	var shots := take_shots(attacker, w)
	if shots == 0:
		emit.call(GameEvent.WEAPON_FIRED, {"attacker_id": attacker.id, "target_id": target.id,
				"weapon": Atm.profile(w).name, "weapon_id": w.def.id, "roll": 0, "need": th.target(),
				"hit": false, "no_ammo": true, "mods": th.mods, "missiles": 0})
		return
	w.fired = true
	attacker.heat_generated += w.def.heat * shots
	PpcCapacitor.discharge(attacker, w)
	var roll := dice.roll_2d6()
	var need := th.target()
	var hit := roll >= need
	var data := {"attacker_id": attacker.id, "target_id": target.id, "weapon": Atm.profile(w).name,
			"weapon_id": w.def.id, "roll": roll, "need": need, "hit": hit,
			"mods": th.mods, "missiles": 0, "shots": shots, "mode": w.mode}
	if RotaryAc.check_jam(w, shots, roll):
		data["jammed"] = true
	if not hit:
		if w.def.streak:  # no lock: it doesn't launch (p. 187)
			attacker.heat_generated -= w.def.heat
			attacker.refund_ammo(w.def, kind)
			data["streak_held"] = true
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	var arc_id := FiringArc.arc(target.coord, target.facing, attacker.coord)
	var ams := AntiMissile.engaging(target, attacker, w)
	if ams != null and not AntiMissile.engage(target, ams):
		ams = null
	var ams_on := ams != null or AssetSpecials.ams(target, w.def)  # an Asset's AMS Special (p. 148)
	var jam := Ecm.artemis_blocked(state, attacker, target, th) if WeaponModes.has_artemis(w) else ""
	if jam != "":
		data["artemis_blocked"] = jam
	if w.def.artemis_builtin:
		data["builtin_artemis"] = true
	var angel := w.def.streak and Ecm.angel_blocks_streak(state, attacker, target)
	if angel:
		data["angel_streak"] = true
	elif w.def.streak and not ams_on:
		data["streak_lock"] = true
	if w.def.beacon:
		if ams != null:
			data["ams_roll"] = AntiMissile.single_missile_roll(dice)
			if AntiMissile.single_missile_down(data["ams_roll"]):
				data["pod_shot_down"] = true
				emit.call(GameEvent.WEAPON_FIRED, data)
				return
		_attach_pod(state, dice, emit, attacker, target, th, arc_id, data)
		return
	var was_ams := ams_on
	if w.def.large_missile and ams_on and Thunderbolt.shot_down(dice, data):
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	var dist := Hex.distance(attacker.coord, target.coord)
	if w.def.large_missile:
		ams_on = false  # already rolled against for this large missile
	var c := WeaponModes.cluster(w, shots, dice, ams_on, jam != "", th.narc_homing, angel,
			GaussWeapons.cluster_mod(w.def, dist))
	if th.narc_homing:
		data["narc_homing"] = true
	if was_ams:
		data["ams"] = true
	var packets: Array[int] = c["packets"]
	if not w.def.damage_by_range.is_empty():  # variable damage (p. 182)
		var shift := 1 if WaterCombat.shot(state.map, attacker, w, target)["under_range"] else 0
		packets = [w.def.damage_at(dist, shift)] as Array[int]
		data["damage_at_range"] = packets[0]
	if w.cap_released:
		packets[0] += PpcCapacitor.DAMAGE
		data["capacitor"] = true
	if c["n"] > 0 or ams_on:
		data["missiles"] = c["n"]
		data["cluster_roll"] = c["roll"]
		data["cluster_bonus"] = c.get("bonus", 0)
	var aimed := {}
	if th.aim_loc >= 0:
		aimed = AimedShot.location(dice, th, arc_id, target.def.quad)
		data["aim"] = th.aim_loc
		data["aim_roll"] = aimed["aim_roll"]
		data["aim_hit"] = aimed["aimed"]
	if w.def.heat_damage and target.asset == null and target.vehicle == null:  # flamers: heat as well as damage (book pp. 183-184)
		data["heat_added"] = w.def.heat_points
		target.outside_heat += w.def.heat_points
	if w.def.heat_dice > 0:
		Plasma.add_heat(dice, w.def, target, data)
	emit.call(GameEvent.WEAPON_FIRED, data)
	if target.asset != null:  # no hit locations: the total goes on the card (p. 146)
		var total := 0
		for p in packets:
			total += p
		AssetDamage.weapon_hit(emit, attacker, w.def, target, total, arc_id)
		return
	for p in packets:
		if p <= 0:
			continue
		var hl := aimed.duplicate()
		if th.legs_only:
			hl = HitTable.roll_kick(dice, arc_id, target.def.quad)
			hl["no_cover"] = true
		hit_with(state, dice, emit, target, arc_id, p, attacker.id, w.def.name, hl, th.cover_hex)


## Spends ammo for the shots this weapon fires; returns how many (0 = none).
## A Narc beacon hit: the pod sticks where it lands (aimed or rolled), no damage.
static func _attach_pod(state: GameState, dice: Dice, emit: Callable, attacker: Unit, target: Unit,
		th: ToHit, arc_id: int, data: Dictionary) -> void:
	var hl := AimedShot.location(dice, th, arc_id, target.def.quad) if th.aim_loc >= 0 else HitTable.roll(dice, arc_id)
	Narc.attach(state, attacker, target, hl["loc"])
	data["narc_loc"] = hl["loc"]
	emit.call(GameEvent.WEAPON_FIRED, data)


static func take_shots(attacker: Unit, w: MountedWeapon) -> int:
	var want := WeaponModes.shots(w)
	if w.def.one_shot:  # p. 182: once a game
		if w.spent:
			return 0
		w.spent = true
		return 1
	if not w.def.uses_ammo():
		return want
	var kind := WeaponModes.ammo_kind(w)
	var got := 0
	while got < want and attacker.use_ammo(w.def, kind):
		got += 1
	return got


## Rolls a hit location and applies one packet of damage. `cover` is a hill
## or building hex giving partial cover: leg hits strike it. `hl.no_cover`
## skips water partial cover (kicks on the Kick table, charges). A standing
## 'Mech half inside a level 1 building has its leg hits, and any Kick table
## hit, taken by the building (charges excepted).
static func hit_with(state: GameState, dice: Dice, emit: Callable, target: Unit,
		arc_id: int, amount: int, source_id: int, source: String,
		hl: Dictionary = {}, cover: Vector2i = Hex.INVALID) -> void:
	if target.asset != null:
		AssetDamage.take(emit, target, amount, source_id, source, [], arc_id)
		return
	if target.vehicle != null:  # its own hit table and damage (VehicleDamage)
		VehicleDamage.take(dice, emit, target, arc_id, amount, source_id, source)
		return
	if hl.is_empty():
		hl = HitTable.roll(dice, arc_id)
	if cover != Hex.INVALID and Location.is_leg_of(target.def, hl["loc"]):
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
			and (Location.is_leg_of(target.def, hl["loc"]) or hl.get("kick_table", false)):
		emit.call(GameEvent.BUILDING, {"kind": "cover_hit", "coord": target.coord, "unit_id": target.id,
				"name": state.map.get_tile(target.coord).building.type.name, "damage": amount})
		BuildingDamage.add(state, source_id, target.coord, amount)
		return
	var loc: int = hl["loc"]
	if Location.is_leg_of(target.def, loc) and not hl.get("no_cover", false) and ToHitCalc.in_partial_cover(state.map, target):
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
