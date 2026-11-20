class_name HeatPhase
extends RefCounted
## Heat Phase: add this turn's heat, dissipate, then roll for ammo explosions
## and shutdown. TODO(rules): restart and water cooling are simplified.

const ENGINE_HIT_HEAT := 5
const LIFE_SUPPORT_HEAT := 15
## Most heat outside sources (flamers, fire) can add in one turn (book p. 102).
const OUTSIDE_HEAT_CAP := 15


static func run(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		if u.destroyed:
			continue
		var before := u.heat
		var outside := mini(u.outside_heat, OUTSIDE_HEAT_CAP)
		var gained := u.heat_generated + ENGINE_HIT_HEAT * u.engine_hits + outside
		var sinks := u.working_heat_sinks() + water_cooling(state.map.get_tile(u.coord), u)
		u.heat = maxi(0, u.heat + gained - sinks)
		emit.call(GameEvent.HEAT, {"unit_id": u.id, "before": before, "gained": gained,
				"sinks": sinks, "outside": outside, "heat": u.heat, "effects": HeatScale.effects_text(u.heat)})
		if u.heat >= LIFE_SUPPORT_HEAT and u.has_hit_slot(CritSlot.Kind.LIFE_SUPPORT):
			PilotDamage.wound(dice, emit, u, 1, "heat with life support damaged")
		_ammo_check(state, dice, emit, u)
		if not u.destroyed:
			_shutdown_check(state, dice, emit, u)


## Extra heat removed by standing in water: depth 1 +2, depth 2+ +4 (max 6).
## TODO(rules): really depends on heat sinks in submerged locations.
static func water_cooling(tile: MapTile, u: Unit = null) -> int:
	if tile == null or not tile.is_water():
		return 0
	var extra := 2 if tile.depth == 1 and (u == null or not u.prone) else 4
	if u != null:
		extra = mini(extra, u.working_heat_sinks())
	return mini(extra, 6)


static func _ammo_check(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var need := HeatScale.ammo_explosion_avoid(u.heat)
	if need == 0:
		return
	var bin := _worst_bin(u)
	if bin == null:
		return
	var roll := dice.roll_2d6()
	emit.call(GameEvent.HEAT_ROLL, {"unit_id": u.id, "kind": "ammo", "roll": roll,
			"need": need, "ok": roll >= need})
	if roll < need:
		AmmoExplosion.explode(state, dice, emit, u, bin)


## TODO(rules): which bin cooks off is assumed to be the most dangerous one.
static func _worst_bin(u: Unit) -> AmmoBin:
	var best: AmmoBin = null
	for a in u.ammo:
		if a.explosion_damage() > 0 and (best == null or a.explosion_damage() > best.explosion_damage()):
			best = a
	return best


static func _shutdown_check(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var need := HeatScale.shutdown_avoid(u.heat)
	if u.shutdown:
		# Restart: automatic once heat is below 14, otherwise roll as for shutdown.
		var ok := need == 0
		if not ok and need < 99:
			var roll := dice.roll_2d6()
			ok = roll >= need
			emit.call(GameEvent.HEAT_ROLL, {"unit_id": u.id, "kind": "restart", "roll": roll,
					"need": need, "ok": ok})
		if ok:
			u.shutdown = false
			emit.call(GameEvent.SHUTDOWN, {"unit_id": u.id, "shutdown": false})
		return
	if need == 0:
		return
	var down := need >= 99
	if not down:
		var roll := dice.roll_2d6()
		down = roll < need
		emit.call(GameEvent.HEAT_ROLL, {"unit_id": u.id, "kind": "shutdown", "roll": roll,
				"need": need, "ok": not down})
	if down:
		u.shutdown = true
		emit.call(GameEvent.SHUTDOWN, {"unit_id": u.id, "shutdown": true})
		Psr.fall_from_shutdown(state, dice, emit, u)
