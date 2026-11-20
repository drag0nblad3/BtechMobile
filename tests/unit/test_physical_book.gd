extends TestCase
## Physical attacks checked against the book: different levels, prone
## targets, pushes, charges from next door, death from above misses.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


## Attacker at column 1 row 2 facing north; target right in front, facing south.
func _pair(rows: Array, attacker := "atlas_as7d") -> Array:
	events.clear()
	var s := GameState.new(make_map(rows))
	var a := mech(attacker, 0, hex_at(1, 2), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(1, 1), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _opt(s: GameState, a: Unit, t: Unit, kind: String) -> Dictionary:
	for o in PhysicalOptions.for_target(s, a, t):
		if o["kind"] == kind:
			return o
	return {}


func test_target_one_level_up_or_down() -> void:
	var r := _pair(["c0 c0 c0", "c0 c1 c0", "c0 c0 c0", "c0 c0 c0"])
	var s: GameState = r[0]
	var punch := _opt(s, r[1], r[2], "punch")
	check(punch["to_hit"].possible(), "punch up")
	check_eq(punch["table"], "kick", "punching up hits the legs")
	check(not _opt(s, r[1], r[2], "kick")["to_hit"].possible(), "can't kick up")
	check(not _opt(s, r[1], r[2], "push")["to_hit"].possible(), "push needs the same level")
	var low := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c1 c0", "c0 c0 c0"])
	var kick := _opt(low[0], low[1], low[2], "kick")
	check(kick["to_hit"].possible(), "kick down")
	check_eq(kick["table"], "punch", "kicking down hits the upper body")
	check(not _opt(low[0], low[1], low[2], "punch")["to_hit"].possible(), "can't punch down")


func test_prone_targets() -> void:
	var r := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"])
	var s: GameState = r[0]
	var t: Unit = r[2]
	t.prone = true
	check(not _opt(s, r[1], t, "punch")["to_hit"].possible(), "no punching a prone 'Mech at your level")
	var kick := _opt(s, r[1], t, "kick")
	check_eq(kick["table"], "full", "kicks on a prone 'Mech use the full table")
	check_eq(kick["to_hit"].target(), 2, "5 - 1 kick - 2 prone")
	var low := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c1 c0", "c0 c0 c0"])
	low[2].prone = true
	for o in PhysicalOptions.for_target(low[0], low[1], low[2]):
		check(not o["to_hit"].possible(), "a prone 'Mech below can only be jumped on")


func test_heat_and_sensors_dont_count_but_movement_does() -> void:
	var r := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"])
	var a: Unit = r[1]
	a.heat = 20
	a.sensor_hits = 1
	a.move_mode = MoveMode.Kind.RUN
	r[2].hexes_moved = 5
	check_eq(_opt(r[0], a, r[2], "punch")["to_hit"].target(), 8, "5 - 1 punch + 2 ran + 2 target moved")


func test_push_uses_feet_and_shoulders() -> void:
	var r := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"])
	var a: Unit = r[1]
	a.torso_twist = 1
	check(_opt(r[0], a, r[2], "push")["to_hit"].possible(), "torso twist doesn't matter")
	for sl: CritSlot in a.slots[Location.LA]:
		if sl.kind == CritSlot.Kind.ACTUATOR and sl.name == "shoulder":
			sl.hit = true
	check_eq(_opt(r[0], a, r[2], "push")["to_hit"].target(), 6, "5 - 1 + 2 broken shoulder")


func test_kick_damage_halves_rounding_down() -> void:
	var r := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"], "jenner_jr7d")
	var a: Unit = r[1]
	for sl: CritSlot in a.slots[Location.LL]:
		if sl.kind == CritSlot.Kind.ACTUATOR and sl.name == "lower_leg":
			sl.hit = true
	var kick := _opt(r[0], a, r[2], "kick")
	check_eq(kick["damage"], 3, "35 t / 5 = 7, halved down to 3; applies to the other leg too")
	check_eq(kick["to_hit"].target(), 6, "5 - 1 + 2")


func test_mutual_push_nobody_moves() -> void:
	var r := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"])
	var s: GameState = r[0]
	var a: Unit = r[1]
	var t: Unit = r[2]
	s.declared_physical = PhysicalOptions.declare(s, a, [{"kind": "push", "limb": -1, "target_id": t.id}])
	s.declared_physical.append_array(PhysicalOptions.declare(s, t, [{"kind": "push", "limb": -1, "target_id": a.id}]))
	check_eq(s.declared_physical.size(), 2)
	PhysicalPhase.resolve(s, LoadedDice.new(), _emit)
	check_eq(a.coord, hex_at(1, 2))
	check_eq(t.coord, hex_at(1, 1))
	check(a.psr_pending.size() == 1 and t.psr_pending.size() == 1, "both roll")


func test_charge_from_next_door_and_one_shove_per_target() -> void:
	var r := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"])
	var s: GameState = r[0]
	var a: Unit = r[1]
	a.move_mode = MoveMode.Kind.WALK
	Charge.declare(s, _emit, a, r[2], 3)
	check_eq(s.declared_physical.size(), 1, "charge without moving first")
	check_eq(s.declared_physical[0]["damage"], 20, "100 / 5 x (TMM 0 + 1)")
	var b := mech("hunchback_hbk4g", 0, hex_at(0, 1), 1, 3)
	s.add_unit(b)
	check(not _opt(s, b, r[2], "push")["to_hit"].possible(), "already being charged")


func test_comparative_piloting_vs_immobile() -> void:
	var r := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"])
	var a: Unit = r[1]
	var t: Unit = r[2]
	a.move_mode = MoveMode.Kind.WALK
	t.shutdown = true
	t.pilot.piloting = 2
	# 5 + (5 - 4) + 1 walked - 4 immobile
	check_eq(Charge.option(r[0], a, t, "charge")["to_hit"].target(), 3)


func test_missed_dfa_lands_and_falls_on_its_back() -> void:
	var r := _pair(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0", "c0 c0 c0"], "jenner_jr7d")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var t: Unit = r[2]
	a.move_mode = MoveMode.Kind.JUMP
	a.hexes_moved = 3
	var opt := Charge.option(s, a, t, "dfa")
	opt["attacker_id"] = a.id
	opt["target_id"] = t.id
	var dice := LoadedDice.new()
	dice.queue_2d6(2)  # miss
	var step := ChargeResolve.resolve(s, dice, _emit, opt)
	ChargeResolve.displace(s, dice, _emit, step)
	check_eq(a.coord, hex_at(1, 1), "lands in the target's hex")
	check(t.coord != hex_at(1, 1), "target stepped aside")
	check(a.prone, "attacker fell")
	var falls := events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.FALL)
	check(falls.size() == 1 and falls[0].data["rear"] and falls[0].data["levels"] == 2, "2 levels, onto its back")
