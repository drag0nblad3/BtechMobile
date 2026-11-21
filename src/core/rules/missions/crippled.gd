class_name Crippled
extends RefCounted
## Crippling damage (book p. 228). A 'Mech is crippled by two engine hits,
## two destroyed limbs (at least one a leg), or one destroyed side torso. A
## 'Mech with a standard engine rolls piloting (with its damage modifiers)
## when it first loses a torso: success ignores that torso for the rest of
## the battle, though it still counts as a lost limb and a second torso
## can't be ignored. Failing doesn't make it fall.
## The status only matters for Forced Withdrawal, objective control and Unit VP.


## Checks every unit; crippled ones are recorded in MissionState.
static func update(state: GameState, dice: Dice, emit: Callable) -> void:
	var ms := state.mission
	if ms.def == null or not ms.def.forced_withdrawal:
		return  # the Crippled rules come with Forced Withdrawal
	for u in state.units:
		if u.destroyed or ms.crippled.has(u.id) or ms.exited.has(u.id):
			continue
		var why := reason(state, dice, emit, u)
		if why != "":
			ms.crippled[u.id] = why
			emit.call(GameEvent.CRIPPLED, {"unit_id": u.id, "why": why,
					"withdraw": ms.def.forced_withdrawal})


static func reason(state: GameState, dice: Dice, emit: Callable, u: Unit) -> String:
	if u.engine_hits >= 2:
		return "two engine hits"
	var torsos := int(u.is_location_destroyed(Location.LT)) + int(u.is_location_destroyed(Location.RT))
	var limbs := 0
	var lost_with_torso := 0
	for loc in [Location.LA, Location.RA]:
		var torso := Location.LT if loc == Location.LA else Location.RT
		if u.is_location_destroyed(loc) and not u.is_location_destroyed(torso):
			limbs += 1
		elif u.is_location_destroyed(loc) and u.def.quad:
			lost_with_torso += 1  # TODO(rules): a quad's front leg lost with its torso isn't counted twice
	if u.def.quad:
		limbs = 0  # its front legs count as legs below
	if torsos >= 2:
		return "both side torsos destroyed"
	if torsos == 1:
		if not _saves_torso(state, dice, emit, u):
			return "a side torso destroyed"
		limbs += 1
	var legs := u.legs_destroyed() - lost_with_torso
	if legs >= 1 and limbs + legs >= 2:
		return "two limbs lost, one of them a leg"
	return ""


static func _saves_torso(state: GameState, dice: Dice, emit: Callable, u: Unit) -> bool:
	var ms := state.mission
	if ms.torso_saved.has(u.id):
		return ms.torso_saved[u.id]
	var ok := not u.def.is_xl() and Psr.roll(dice, emit, u, "keeping on after losing a torso", 0)
	ms.torso_saved[u.id] = ok
	return ok
