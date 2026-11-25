class_name EndPhase
extends RefCounted
## End Phase (book p. 117): a MechWarrior knocked out in an earlier turn
## tries to wake up; a warrior with damaged life support drowns a little
## when the 'Mech is fully under water. Last, an immobile 'Mech with no
## working ranged weapons is destroyed (Disarmed). Assets that took enough
## damage make their Destroy Checks (DestroyCheck).


static func run(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		HeatSinkSwitch.apply(emit, u)
		Stealth.apply(emit, u)
		if u.destroyed or u.pilot.is_dead():
			continue
		CombatIntuition.apply(state, dice, emit, u)
		if u.has_hit_slot(CritSlot.Kind.LIFE_SUPPORT) and submerged(state, u):
			PilotDamage.wound(dice, emit, u, 1, "under water with life support damaged")
		if not u.pilot.conscious and u.pilot.out_since_turn < state.turn \
				and u.pilot.out_since_turn >= 0:
			PilotDamage.consciousness_roll(dice, emit, u)
	PilotDamage.resolve_owed(state, dice, emit)
	DestroyCheck.run(state, dice, emit)
	ArrowSmoke.end_phase(state, emit)
	ArrowInferno.end_phase(state, emit)
	for u in state.units:
		if Disarmed.check(u):
			Damage.announce(emit, u)


## Fully under water: standing in depth 2+, or prone in depth 1+.
static func submerged(state: GameState, u: Unit) -> bool:
	var tile := state.map.get_tile(u.coord)
	if tile == null or not tile.is_water():
		return false
	return tile.depth >= 2 or (tile.depth >= 1 and u.prone)
