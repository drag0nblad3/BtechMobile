class_name HeatPhase
extends RefCounted
## Heat Phase (book pp. 102-107): add this turn's heat, dissipate, then
## resolve shutdown (or restart), ammo cook-off, and last the MechWarrior
## hits from damaged life support. Inferno ammo has its own rolls (InfernoAmmo). Extreme temperatures shift all of it (ExtremeTemp).

const ENGINE_HIT_HEAT := 5
## Most heat outside sources (flamers, fire) can add in one turn (book p. 102).
const OUTSIDE_HEAT_CAP := 15
const NO_RESTART_HEAT := 30


static func run(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		if u.destroyed:
			continue
		if u.asset != null:  # no heat scale: outside heat is damage (p. 148)
			AssetDamage.heat(emit, u, u.outside_heat, "fire")
			continue
		if u.vehicle != null or u.ba != null:  # vehicles and battle armor track no heat; TODO(rules) fire and flamer effects
			continue
		var before := u.heat
		var outside := 0 if ArmorTypes.no_outside_heat(u.def) \
				else mini(u.outside_heat + Fire.stand_heat(state.map, u), OUTSIDE_HEAT_CAP)
		var engine := 0 if u.shutdown else ENGINE_HIT_HEAT * u.engine_hits
		var c := state.conditions
		var gained := u.heat_generated + engine + outside + ExtremeTemp.heat_added(c) + Stealth.heat(u)
		var sinks := u.dissipation() + water_cooling(state.map.get_tile(u.coord), u) \
				+ ExtremeTemp.extra_sinks(c) + Surfaces.snow_cooling(state, u)
		u.heat = maxi(0, u.heat + gained - sinks)
		emit.call(GameEvent.HEAT, {"unit_id": u.id, "before": before, "gained": gained,
				"sinks": sinks, "outside": outside, "heat": u.heat, "stealth": Stealth.heat(u),
				"weather": ExtremeTemp.heat_added(c) - ExtremeTemp.extra_sinks(c),
				"effects": HeatScale.effects_text(u.heat, c)})
		VoluntaryShutdown.apply(dice, emit, u)
		if not u.voluntary_shutdown:
			HeatShutdown.check(dice, emit, u, c)
		_ammo_check(state, dice, emit, u)
		InfernoAmmo.check(state, dice, emit, u)
		var ls := ExtremeTemp.life_support_hits(c, u.heat)
		if not u.destroyed and u.has_hit_slot(CritSlot.Kind.LIFE_SUPPORT) and ls > 0:
			PilotDamage.wound(dice, emit, u, ls, "cold with life support damaged" if c.cold > 0
					else "heat with life support damaged")
	PilotDamage.resolve_owed(state, dice, emit)


## Extra heat removed by water (p. 103): each submerged heat sink removes
## its rating again (1 single, 2 double), at most 6 extra. Standing in depth 1 only the leg sinks are under;
## in depth 2+, or prone in depth 1+, all of them are.
static func water_cooling(tile: MapTile, u: Unit = null) -> int:
	if tile == null or not tile.is_water() or tile.depth < 1:
		return 0
	if u == null:
		return 2 if tile.depth == 1 else 6
	var all := tile.depth >= 2 or u.prone
	var under := u.working_heat_sinks() if all else mini(leg_heat_sinks(u), u.working_heat_sinks())
	return mini(under * u.def.heat_per_sink(), 6)


## Working heat sinks mounted in the legs (a double counts once).
static func leg_heat_sinks(u: Unit) -> int:
	var refs := {}
	var dead := {}
	for loc in Location.legs(u.def):
		if u.is_location_out(loc):
			continue
		for s: CritSlot in u.slots[loc]:
			if s.kind == CritSlot.Kind.HEAT_SINK:
				refs[s.ref] = true
				if s.hit:
					dead[s.ref] = true
	return refs.size() - dead.size()


static func _ammo_check(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var need := HotDog.need(u, ExtremeTemp.avoid(HeatScale.ammo_explosion_avoid(u.heat), state.conditions))
	if need == 0 or u.destroyed:
		return
	var bin := worst_bin(u)
	if bin == null:
		return
	var roll := dice.roll_2d6() if need < 99 else 0
	emit.call(GameEvent.HEAT_ROLL, {"unit_id": u.id, "kind": "ammo", "roll": roll,
			"need": need, "ok": roll >= need})
	if roll < need:
		AmmoExplosion.explode(state, dice, emit, u, bin)


## The bin that cooks off (p. 107): most damage per shot, then most shots left.
static func worst_bin(u: Unit) -> AmmoBin:
	var best: AmmoBin = null
	for a in u.ammo:
		if a.explosion_damage() <= 0 or InfernoAmmo.is_inferno(a):
			continue
		if best == null or a.weapon.max_damage() > best.weapon.max_damage() \
				or (a.weapon.max_damage() == best.weapon.max_damage() and a.shots > best.shots):
			best = a
	return best
