class_name BotMove
extends RefCounted
## Bot movement: try every reachable end hex for walk, run and jump, facing
## the nearest enemy, and score it: expected damage it can deal next phase,
## minus expected damage enemies can deal to it, minus heat.

## The weight on damage taken, move jitter and rear-arc bonus come from BotSkill.
const MAX_CANDIDATES := 60


## Returns {key: Vector3i, mode, reason, charge: target id or -1}.
static func plan(state: GameState, u: Unit) -> Dictionary:
	if ForcedWithdrawal.withdrawing(state, u):
		return BotWithdraw.plan(state, u)
	var leave := BotObjectives.exit_plan(state, u)
	if not leave.is_empty():
		return leave
	var best := {"key": MoveOptions.key(u.coord, u.facing), "mode": MoveMode.Kind.WALK,
			"score": -INF, "reason": "stays put", "charge": -1}
	for mode in [MoveMode.Kind.WALK, MoveMode.Kind.RUN, MoveMode.Kind.JUMP]:
		var opts := MovePlanner.plan(state, u, mode)
		for k in _candidates(state, u, opts):
			var s := _score(state, u, mode, k, opts)
			if s["score"] > best["score"]:
				s["key"] = k
				s["mode"] = mode
				best = s
	return best


## Best facing per reachable hex (toward the nearest enemy), closest first.
static func _candidates(state: GameState, u: Unit, opts: MoveOptions) -> Array[Vector3i]:
	var enemy := nearest_enemy(state, u, u.coord)
	var out: Array[Vector3i] = []
	for c: Vector2i in opts.reachable_hexes():
		var keys := opts.end_keys_in(c)
		if keys.is_empty():
			continue
		var pick := keys[0]
		if enemy:
			for k in keys:
				if FiringArc.wedge(c, k.z, enemy.coord) == 0:
					pick = k
					break
		out.append(pick)
	if enemy and out.size() > MAX_CANDIDATES:
		out.sort_custom(func(a, b): return Hex.distance(MoveOptions.coord_of(a), enemy.coord) < Hex.distance(MoveOptions.coord_of(b), enemy.coord))
		out = out.slice(0, MAX_CANDIDATES)
	return out


static func _score(state: GameState, u: Unit, mode: int, k: Vector3i, opts: MoveOptions) -> Dictionary:
	var save := [u.coord, u.facing, u.move_mode, u.hexes_moved, u.heat_generated]
	var moved: bool = opts.cost.get(k, 0) > 0
	var dest := MoveOptions.coord_of(k)
	var hexes := 0
	if moved:
		hexes = Hex.distance(u.coord, dest) if mode == MoveMode.Kind.JUMP \
				else MoveOptions.hexes_entered(opts.path_to(k), u.coord)
	u.coord = dest
	u.facing = k.z
	u.move_mode = mode if moved else -1
	u.hexes_moved = hexes
	u.heat_generated += MoveMode.heat(mode, u.hexes_moved, JumpJets.improved(u.def)) if moved else 0
	var dealt: float = BotFire.plan(state, u)["value"]
	var charge := BotCharge.evaluate(state, u, opts.budget - int(opts.cost.get(k, 0))) if moved and BotSkill.basic_tricks() else {}
	if not charge.is_empty() and charge["value"] <= dealt:
		charge = {}
	if not charge.is_empty():
		dealt = charge["value"]
	var taken := 0.0
	for e in state.units:
		if e.side != u.side and not e.destroyed:
			for o in FireOptions.for_target(state, e, u):
				if o["to_hit"].possible():
					taken += Advisor.expected_damage(o["weapon"], o["to_hit"])
	var heat_cost := maxf(0.0, Advisor.projected_heat(u, 0) - 2) * 0.5
	var score := dealt - BotSkill.taken_weight() * taken - heat_cost + BotSkill.jitter(u, state.turn, k)
	var behind := _rear_of(state, u)
	score += BotSkill.rear_bonus() * behind
	# Close toward the range its weapons like best.
	var enemy := nearest_enemy(state, u, u.coord)
	var gap := 0
	if enemy:
		gap = maxi(0, Hex.distance(u.coord, enemy.coord) - preferred_range(u))
		score -= 0.3 * gap
	else:  # nobody in sight (all hiding): sweep toward the middle of the field
		gap = Hex.distance(u.coord, Deployment.center(state.map))
		score -= 0.3 * gap
	var obj := BotObjectives.bonus(state, u, u.coord)
	score += obj[0]
	var tile := state.map.get_tile(u.coord)
	var where := "stays at %s" % Hex.label(u.coord) if not moved else "%s to %s" % [
			(AssetMove.mode_name(u, mode) if u.vehicle != null else MoveMode.name_of(mode)).to_lower() + "s", Hex.label(u.coord)]
	var reason := "%s: can deal about %.1f next phase, risks %.1f" % [where, dealt, taken]
	if not charge.is_empty():
		reason = "%s and %s" % [where, charge["reason"]]
	elif dealt == 0.0 and gap > 0 and enemy == null:
		reason = "%s to search the field: no enemy in sight" % where
	elif dealt == 0.0 and gap > 0:
		reason = "%s to close in (its weapons work best within %d hexes)" % [where, preferred_range(u)]
	if obj[1] != "":
		reason += ", " + obj[1]
	if behind > 0 and BotSkill.rear_bonus() > 0.0:
		reason += ", behind an enemy for rear shots"
	if tile and LineOfSight.woods_value(tile) > 0:
		reason += ", ends in %s for cover" % tile.terrain.name.to_lower()
	elif tile and tile.building:
		reason += ", inside a %s (+2 to hit it)" % tile.building.type.name.to_lower()
	u.coord = save[0]
	u.facing = save[1]
	u.move_mode = save[2]
	u.hexes_moved = save[3]
	u.heat_generated = save[4]
	return {"score": score, "reason": reason, "charge": charge.get("target_id", -1)}


## Enemies whose rear arc `u` stands in (within 6 hexes).
static func _rear_of(state: GameState, u: Unit) -> int:
	var n := 0
	for e in state.units:
		if e.side != u.side and not e.destroyed and Hex.distance(e.coord, u.coord) <= 6 \
				and FiringArc.arc(e.coord, e.facing, u.coord) == FiringArc.REAR:
			n += 1
	return n


## Medium range of its hardest-hitting weapon: where it wants to fight.
static func preferred_range(u: Unit) -> int:
	var best: WeaponDef = null
	for w in u.weapons:
		if u.can_fire(w) and (best == null or w.def.max_damage() > best.max_damage()):
			best = w.def
	return best.medium_range if best else 1


static func nearest_enemy(state: GameState, u: Unit, from: Vector2i) -> Unit:
	var best: Unit = null
	for e in state.units:
		if e.side != u.side and not e.destroyed:
			if best == null or Hex.distance(from, e.coord) < Hex.distance(from, best.coord):
				best = e
	return best
