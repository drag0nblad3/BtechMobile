class_name SimBot
extends RefCounted
## Plays both sides crudely (close in, fire everything, punch/kick) so tests
## can run whole games and catch runtime errors in the rules.


static func play(gc: GameController, max_turns: int = 40) -> void:
	gc.start_turn()
	var guard := 0
	while not gc.state.game_over and gc.state.turn <= max_turns and guard < 5000:
		guard += 1
		var p := gc.pending_units()
		if p.is_empty():
			break
		var u := p[0]
		match gc.state.phase:
			Phase.Kind.MOVEMENT:
				_move(gc, u)
			Phase.Kind.WEAPON_ATTACK:
				_fire(gc, u)
			Phase.Kind.PHYSICAL_ATTACK:
				_physical(gc, u)


static func _nearest_enemy(s: GameState, u: Unit) -> Unit:
	var best: Unit = null
	for o in s.units:
		if o.side != u.side and not o.destroyed:
			if best == null or Hex.distance(u.coord, o.coord) < Hex.distance(u.coord, best.coord):
				best = o
	return best


static func _move(gc: GameController, u: Unit) -> void:
	var e := _nearest_enemy(gc.state, u)
	var mode := MoveMode.Kind.RUN if u.id % 2 == 0 else MoveMode.Kind.WALK
	var opts := MovePlanner.plan(gc.state, u, mode)
	var best := opts.start_key()
	var best_d := 999
	for k: Vector3i in opts.cost:
		if not opts.can_reach(k):
			continue
		var c := MoveOptions.coord_of(k)
		var d := Hex.distance(c, e.coord) * 10 + (0 if FiringArc.arc(c, k.z, e.coord) == FiringArc.FRONT else 5)
		if d < best_d:
			best_d = d
			best = k
	var ahead := gc.state.unit_at(Hex.neighbor(MoveOptions.coord_of(best), best.z))
	var charge_id := ahead.id if ahead and ahead.side != u.side and u.id % 3 == 0 else -1
	gc.submit_move(u, best, mode, charge_id)


static func _fire(gc: GameController, u: Unit) -> void:
	var e := _nearest_enemy(gc.state, u)
	var shots := []
	for i in u.weapons.size():
		shots.append({"weapon": i, "target_id": e.id})
	gc.declare_fire(u, shots)


static func _physical(gc: GameController, u: Unit) -> void:
	var e := _nearest_enemy(gc.state, u)
	var attacks := []
	for o in PhysicalOptions.for_target(gc.state, u, e):
		if o["to_hit"].possible():
			attacks.append({"kind": o["kind"], "limb": o["limb"], "target_id": e.id})
	gc.declare_physical(u, attacks)
