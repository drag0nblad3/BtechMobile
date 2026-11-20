extends TestCase
## MechWarrior hits, consciousness timing, falls, heat effects and critical
## hit transfer (book pp. 87-117).

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _state(u: Unit, rows: Array = []) -> GameState:
	var s := GameState.new(make_map(rows) if not rows.is_empty() else open_map(4, 4))
	s.add_unit(u)
	events.clear()
	return s


func test_head_hit_hurts_pilot_through_armor() -> void:
	var u := mech("atlas_as7d", 1, hex_at(1, 1), 0, 2)
	var s := _state(u)
	var hl := {"loc": Location.HEAD, "rear": false, "tac": false}
	for i in 3:
		WeaponFire.hit_with(s, LoadedDice.new(), _emit, u, FiringArc.FRONT, 2, 1, "SRM", hl)
	check_eq(u.pilot.hits, 3, "three SRMs to the head: three hits")
	check(u.pilot.conscious, "no consciousness roll until the phase ends")
	check(u.pilot.roll_owed, "roll owed")
	var dice := LoadedDice.new()
	dice.queue_2d6(9)  # needs 7+ at three hits
	PilotDamage.resolve_owed(s, dice, _emit)
	check(u.pilot.conscious, "one roll against the current total")
	check(not u.pilot.roll_owed, "settled")


func test_wake_up_only_in_a_later_turn() -> void:
	var u := mech("griffin_grf1n", 0, hex_at(1, 1), 0, 1)
	var s := _state(u)
	s.turn = 3
	PilotDamage.wound(LoadedDice.new(), _emit, u, 2, "test")
	var dice := LoadedDice.new()
	dice.queue_2d6(2)  # fails 5+
	PilotDamage.resolve_owed(s, dice, _emit)
	check(not u.pilot.conscious, "knocked out")
	EndPhase.run(s, LoadedDice.new(), _emit)  # 6s would wake it
	check(not u.pilot.conscious, "no wake-up roll in the same turn")
	s.turn = 4
	EndPhase.run(s, LoadedDice.new(), _emit)
	check(u.pilot.conscious, "wakes in a later End Phase")


func test_fall_keeps_facing_and_water_halves() -> void:
	var u := mech("atlas_as7d", 0, hex_at(1, 0), 2, 1)
	var s := _state(u, ["c0 w0d1 c0"])
	var dice := LoadedDice.new([3])  # not a 1: front
	Fall.fall(s, dice, _emit, u, 0, "test")
	check_eq(u.facing, 2, "facing unchanged")
	var fall_ev: Dictionary = events.filter(func(e: Array) -> bool: return e[0] == GameEvent.FALL)[0][1]
	check_eq(fall_ev["damage"], 5, "10 halved in water")
	check(not fall_ev["rear"], "front")
	check_eq(u.damage_this_phase, 5, "fall damage counts toward the 20-point roll")


func test_seatbelt_check_only_counts_levels() -> void:
	var u := mech("griffin_grf1n", 0, hex_at(1, 1), 0, 1)
	var s := _state(u)
	u.gyro_hits = 1
	var dice := LoadedDice.new([2])  # front
	for i in 4:
		dice.queue_2d6(7)
	dice.queue_2d6(7)  # seatbelt: piloting 5 + 2 levels = 7: passes
	Fall.fall(s, dice, _emit, u, 2, "test")
	check_eq(u.pilot.hits, 0, "gyro damage doesn't affect the seatbelt check")


func test_life_support_and_shutdown() -> void:
	var u := mech("griffin_grf1n", 0, hex_at(1, 1), 0, 1)
	var s := _state(u)
	for sl: CritSlot in u.slots[Location.HEAD]:
		if sl.kind == CritSlot.Kind.LIFE_SUPPORT:
			sl.hit = true
	u.heat = 23  # 11 after 12 sinks
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check_eq(u.pilot.hits, 1, "heat 10-19: 1 hit")
	u.heat = 34  # 22: shutdown check 8+, then 2 hits
	var dice := LoadedDice.new()
	dice.queue_2d6(3)  # shutdown not avoided
	HeatPhase.run(s, dice, _emit)
	check(u.shutdown, "shut down")
	check(not u.prone, "still standing")
	check_eq(u.pilot.hits, 3, "heat 20+: 2 hits")
	u.pilot.conscious = false
	u.heat = 30  # 18 after sinks: restart needs a conscious warrior
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check(u.shutdown, "unconscious warrior can't restart above 13")
	u.heat = 20  # 8: restarts by itself
	HeatPhase.run(s, LoadedDice.new(), _emit)
	check(not u.shutdown, "restarts automatically below 14")


func test_cook_off_bin_by_damage_per_shot() -> void:
	var u := mech("atlas_as7d", 0, hex_at(1, 1), 0, 1)
	check_eq(HeatPhase.worst_bin(u).weapon.id, "lrm20", "LRM 20 and AC/20 both deal 20 a shot; the LRM bin has more shots")


func test_crits_transfer_from_an_empty_location() -> void:
	var u := mech("griffin_grf1n", 0, hex_at(1, 1), 0, 1)
	var s := _state(u)
	s.turn = 2
	s.phase = Phase.Kind.WEAPON_ATTACK
	for sl: CritSlot in u.slots[Location.LA]:
		if sl.kind != CritSlot.Kind.EMPTY:
			sl.hit = true  # hit in an earlier turn
	CriticalHits.apply_one(s, LoadedDice.new(), _emit, u, Location.LA)
	var lt_hit: bool = u.slots[Location.LT].any(func(sl: CritSlot) -> bool: return sl.hit)
	check(lt_hit, "moves inward to the left torso")
	# Slots hit this phase: the extra critical is lost instead.
	for sl: CritSlot in u.slots[Location.RA]:
		if sl.kind != CritSlot.Kind.EMPTY:
			sl.hit = true
			sl.hit_when = s.turn * 10 + s.phase
	CriticalHits.apply_one(s, LoadedDice.new(), _emit, u, Location.RA)
	var rt_hit: bool = u.slots[Location.RT].any(func(sl: CritSlot) -> bool: return sl.hit)
	check(not rt_hit, "lost")
