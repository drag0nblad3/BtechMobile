class_name Formation
extends RefCounted
## Formation bonus abilities (Campaign Operations pp. 60-66), free and on top
## of a MechWarrior's own. They go in Unit.formation_spas (Spa reads them)
## and last while 3 of the formation's units are still fighting
## (GameState.formations: {side, type, ids, active, luck}).
## Battle Lances share 6 Lucky rerolls (FormationLuck). TODO(rules): the
## book lets the player hand per-turn bonuses (Fire, Direct Fire, Fire
## Support, Assault) to two units each turn, and pick from a list
## (Assault, Recon, Command); the app picks once, at the start, by firepower
## and speed. Assault gets Multi-Tasker (no Demoralizer); Command's two
## picks are Multi-Tasker and Eagle's Eyes; Rangers are Forest Rangers.

const KEEP := 3
const LUCK := 6
const BATTLE := ["battle", "light_battle", "medium_battle", "heavy_battle"]


## The 'Mechs of `side` that can form up (MechWarriors, not support units).
static func members(state: GameState, side: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.units_of_side(side):
		if u.asset == null and u.vehicle == null and u.ba == null and u.pilot != null:
			out.append(u)
	return out


## Forms `side` up as `type` if it qualifies; returns the formation or {}.
static func setup(state: GameState, side: int, type: String) -> Dictionary:
	var us := members(state, side)
	if not FormationTypes.qualifies(type, us):
		return {}
	var ids: Array[int] = []
	for u in us:
		ids.append(u.id)
	var f := {"side": side, "type": type, "ids": ids, "active": true, "luck": LUCK if BATTLE.has(type) else 0}
	state.formations.append(f)
	_grant(type, us)
	return f


## The first type `side` qualifies for, formed up; "" if none.
static func auto(state: GameState, side: int) -> String:
	var types := FormationTypes.qualifying(members(state, side))
	if types.is_empty():
		return ""
	setup(state, side, types[0])
	return types[0]


static func of(state: GameState, u: Unit) -> Dictionary:
	for f: Dictionary in state.formations:
		if f["active"] and (f["ids"] as Array).has(u.id):
			return f
	return {}


## After each phase: a formation down to 2 units loses its bonuses.
static func check(state: GameState, emit: Callable) -> void:
	for f: Dictionary in state.formations:
		if not f["active"]:
			continue
		var left := 0
		for id: int in f["ids"]:
			var u := state.unit_by_id(id)
			if u != null and state.mission.remains(u):
				left += 1
		if left >= KEEP:
			continue
		f["active"] = false
		f["luck"] = 0
		for id: int in f["ids"]:
			var u := state.unit_by_id(id)
			if u != null:
				u.formation_spas.clear()
		emit.call(GameEvent.FORMATION, {"kind": "lost", "side": f["side"], "type": f["type"], "left": left})


static func _grant(type: String, us: Array[Unit]) -> void:
	var n75 := ceili(us.size() * 0.75)
	match type:
		"fire":
			_give(_by(us, func(u: Unit) -> int: return FormationTypes.damage_at(u, 9)), 2, Spa.SNIPER)
		"fire_support":
			var lrm := us.filter(func(u: Unit) -> bool: return u.weapons.any(func(w: MountedWeapon) -> bool: return w.def.indirect))
			_give(_by(lrm, func(u: Unit) -> int: return FormationTypes.damage_at(u, 15)), 2, Spa.OBLIQUE_ATTACKER)
		"direct_fire":
			for u in _take(_by(us, func(u: Unit) -> int: return FormationTypes.damage_at(u, 18)), 2, Spa.WEAPON_SPECIALIST):
				u.formation_spas.append(Spa.WEAPON_SPECIALIST + ":" + _long_gun(u))
		"assault":
			_give(_by(us, func(u: Unit) -> int: return FormationTypes.damage_at(u, 7)), 2, Spa.MULTI_TASKER)
		"striker", "light_striker", "heavy_striker":
			_give(_by(us, func(u: Unit) -> int: return u.def.run_mp()), n75, Spa.SPEED_DEMON)
		"pursuit", "probe", "sweep":
			_give(_by(us, func(u: Unit) -> int: return FormationTypes.damage_at(u, 9)), n75, Spa.BLOOD_STALKER)
		"recon", "light_recon", "heavy_recon":
			var n := us.size() if type == "light_recon" else 2 if type == "heavy_recon" else 3
			_give(_by(us, func(u: Unit) -> int: return u.def.walk_mp), n, Spa.EAGLES_EYES)
			_give(us, us.size(), Spa.FORWARD_OBSERVER)
		"command":
			us[0].formation_spas.append(Spa.TACTICAL_GENIUS)
			_give(us.slice(1, 2), 1, Spa.MULTI_TASKER)
			_give(us.slice(2, 3), 1, Spa.EAGLES_EYES)
		"ranger":
			for u in _take(us, n75, Spa.TERRAIN_MASTER):
				u.formation_spas.append(Spa.TERRAIN_MASTER + ":" + TerrainMaster.FOREST_RANGER)


static func _give(us: Array[Unit], n: int, id: String) -> void:
	for u in _take(us, n, id):
		u.formation_spas.append(id)


## The first `n` units, those whose MechWarrior lacks `id` first.
static func _take(us: Array[Unit], n: int, id: String) -> Array[Unit]:
	var lacking := us.filter(func(u: Unit) -> bool: return not u.pilot.abilities.any(func(a: String) -> bool: return a.begins_with(id)))
	var rest := us.filter(func(u: Unit) -> bool: return not lacking.has(u))
	var out: Array[Unit] = []
	out.assign((lacking + rest).slice(0, n))
	return out


static func _by(us: Array, key: Callable) -> Array[Unit]:
	var out: Array[Unit] = []
	out.assign(us)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return key.call(a) > key.call(b))
	return out


static func _long_gun(u: Unit) -> String:
	var best: MountedWeapon = null
	for w in u.weapons:
		if best == null or w.def.long_range * w.def.damage > best.def.long_range * best.def.damage:
			best = w
	return best.def.id if best != null else ""
