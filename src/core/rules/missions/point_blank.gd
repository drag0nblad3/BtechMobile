class_name PointBlank
extends RefCounted
## Point-blank attacks (book p. 231). A hidden 'Mech found by an enemy's move
## may fire at once at the 'Mech that found it, as if from 1 hex, after
## twisting its torso, with no target movement modifier. Damage and piloting
## rolls happen right away. Doing so uses up its whole turn; declining lets
## it act normally from the next phase.
## TODO(rules): the mover's move ends where it was stopped; the book lets it
## carry on with any MP left after the attack.


## Best volley: {twist, shots: [weapon index], expected}. `cool` leaves out
## the hottest weapons until the shooter stays at heat 4 or less.
static func plan(state: GameState, h: Unit, target: Unit, cool := false) -> Dictionary:
	var keep := h.torso_twist
	var best := {"twist": 0, "shots": [], "expected": 0.0}
	for twist in ([0] if h.prone else [0, -1, 1]):
		h.torso_twist = twist
		var shots := []
		var ev := 0.0
		for i in h.weapons.size():
			var th := ToHitCalc.weapon(state, h, h.weapons[i], target, false, true)
			if th.possible():
				shots.append(i)
				ev += Advisor.expected_damage(h.weapons[i], th)
		if ev > best["expected"]:
			best = {"twist": twist, "shots": shots, "expected": ev}
	h.torso_twist = keep
	if cool:
		var shots: Array = best["shots"]
		shots.sort_custom(func(a: int, b: int) -> bool: return h.weapons[a].def.heat < h.weapons[b].def.heat)
		while not shots.is_empty() and Advisor.projected_heat(h, FireOptions.volley_heat(h, shots)) > 4:
			shots.pop_back()
	return best


## Fires the volley now. Empty `shots` declines (the unit acts normally later).
static func resolve(state: GameState, dice: Dice, emit: Callable, h: Unit, target: Unit,
		shots: Array, twist: int) -> void:
	emit.call(GameEvent.POINT_BLANK, {"unit_id": h.id, "target_id": target.id, "fired": not shots.is_empty()})
	if shots.is_empty():
		return
	h.has_moved = true
	h.has_fired = true
	h.has_physical = true
	h.torso_twist = 0 if h.prone else clampi(twist, -1, 1)
	for i: int in shots:
		if i < 0 or i >= h.weapons.size() or target.destroyed:
			continue
		var th := ToHitCalc.weapon(state, h, h.weapons[i], target, false, true)
		if th.possible():
			WeaponFire.resolve(state, dice, emit, h, h.weapons[i], target, th)
	h.torso_twist = 0
	Damage.announce(emit, target)
	if not target.destroyed:
		Psr.resolve_pending(state, dice, emit, target)
	target.psr_pending.clear()
	PilotDamage.resolve_owed(state, dice, emit)
