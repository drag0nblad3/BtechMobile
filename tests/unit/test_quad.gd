extends TestCase
## Four-legged 'Mechs (book pp. 238-239).


## A 60-ton quad with a laser in each torso and a leg-mounted small laser.
func _quad_def() -> UnitDef:
	return UnitDef.from_dict({"id": "q", "name": "Quad Test", "tonnage": 60, "walk_mp": 4, "quad": true,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "FLL": 15, "FRL": 15, "RLL": 15, "RRL": 15},
			"equipment": {"LT": ["medium_laser"], "RT": ["medium_laser"], "FRL": ["small_laser"]}}, weapons())


func _quad(at := Vector2i(2, 2), facing := 0) -> Unit:
	return Unit.new(1, _quad_def(), 0, at, facing)


func _hit(u: Unit, loc: int, actuator: String) -> void:
	for s: CritSlot in u.slots[loc]:
		if s.kind == CritSlot.Kind.ACTUATOR and s.name == actuator:
			s.hit = true


func test_locations_structure_and_slots() -> void:
	var u := _quad()
	check_eq(Location.legs(u.def).size(), 4)
	check_eq(Location.code_for(u.def, Location.LA), "FLL")
	check_eq(Location.name_for(u.def, Location.RL), "Right Rear Leg")
	check_eq(u.armor[Location.RA], 15, "FRL armor read into the right arm slot")
	check_eq(u.structure[Location.LA], u.structure[Location.LL], "front legs use the leg column")
	check_eq(u.slots[Location.LA].size(), 6, "legs have six slots")
	check(u.has_working_actuator(Location.RA, "hip"), "front legs carry leg actuators")
	check(not u.has_working_actuator(Location.RA, "shoulder"))


func test_hit_tables() -> void:
	var dice := LoadedDice.new([1])
	check_eq(HitTable.roll_kick(dice, FiringArc.FRONT, true)["loc"], Location.RA, "front kick 1-3: front right leg")
	dice = LoadedDice.new([5])
	check_eq(HitTable.roll_kick(dice, FiringArc.REAR, true)["loc"], Location.LL, "rear kick 4-6: rear left leg")
	dice = LoadedDice.new([5])
	check_eq(HitTable.roll_kick(dice, FiringArc.LEFT, true)["loc"], Location.LL, "left side 4-6: rear left leg")
	dice = LoadedDice.new([5])
	check_eq(HitTable.roll_punch(dice, FiringArc.LEFT, true)["loc"], Location.LL, "punch left 5: rear left leg")
	dice = LoadedDice.new([1])
	check_eq(HitTable.roll_punch(dice, FiringArc.REAR, true)["loc"], Location.RL)


func test_mp_with_lost_legs() -> void:
	var u := _quad()
	check_eq(u.walk_mp(), 4)
	u.structure[Location.LA] = 0
	check_eq(u.walk_mp(), 3, "one leg: -1")
	u.structure[Location.RL] = 0
	check_eq(u.walk_mp(), 2, "two legs: -2")
	u.structure[Location.RA] = 0
	check_eq(u.walk_mp(), 1, "three legs: like a biped on one leg")
	u.structure[Location.LL] = 0
	check_eq(u.walk_mp(), 0)


func test_first_hip_is_free() -> void:
	var u := _quad()
	_hit(u, Location.LL, "hip")
	check_eq(u.walk_mp(), 4, "first hip: no MP loss")
	check_eq(u.hip_hits(), 0)
	_hit(u, Location.RL, "hip")
	check_eq(u.hip_hits(), 1, "the second one counts")
	check_eq(u.walk_mp(), 3)


func test_piloting_mods() -> void:
	var u := _quad()
	check_eq(Psr.standing_mods(u).target(), 3, "four legs: -2")
	u.structure[Location.RL] = 0
	check_eq(Psr.standing_mods(u).target(), 6, "one leg lost: +1, bonus gone")
	u.structure[Location.LL] = 0
	check_eq(Psr.standing_mods(u).target(), 7)


func test_stands_without_a_roll() -> void:
	var s := GameState.new(open_map(5, 5))
	var u := _quad(hex_at(2, 2))
	s.add_unit(u)
	u.prone = true
	var dice := LoadedDice.new()
	dice.queue_2d6(2)
	check(Psr.try_stand(s, dice, func(_t: StringName, _d: Dictionary) -> void: pass, u), "no roll while all four legs stand")
	check(not u.prone)


func test_leg_destroyed_means_a_fall() -> void:
	var u := _quad()
	Damage.destroy_location(u, Location.RL)
	check(u.psr_pending.any(func(p: Dictionary) -> bool: return p.get("auto_fall", false)))


func test_prone_fire() -> void:
	var u := _quad()
	u.prone = true
	var leg_gun: MountedWeapon = u.weapons.filter(func(w: MountedWeapon) -> bool: return w.loc == Location.RA)[0]
	check_eq(ProneFire.blocked(u, leg_gun), "", "an intact quad fires normally while down")
	_hit(u, Location.LL, "hip")
	check(not Quad.fires_standing(u), "a hip hit takes that away (+2 to fire)")
	check(ProneFire.prop_arm(u) != Location.RA, "it props on a leg without a gun")
	check_eq(ProneFire.blocked(u, leg_gun), "", "its other legs still fire")


func test_kicks_and_no_punches() -> void:
	var s := GameState.new(open_map(5, 5))
	var a := _quad(hex_at(2, 2), 0)
	var front := mech("hunchback_hbk4g", 1, Hex.neighbor(a.coord, 0), 3, 2)
	var back := mech("hunchback_hbk4g", 1, Hex.neighbor(a.coord, 3), 0, 3)
	s.add_unit(a)
	s.add_unit(front)
	s.add_unit(back)
	var kinds := PhysicalOptions.for_target(s, a, front).map(func(o: Dictionary) -> String: return o["kind"])
	check(not kinds.has("punch") and not kinds.has("push"), "no arms")
	var fwd := PhysicalOptions.for_target(s, a, front).filter(func(o: Dictionary) -> bool: return o["to_hit"].possible())
	check_eq(fwd.size(), 2, "front kicks with either front leg")
	check_eq(fwd[0]["damage"], 12, "60 t / 5")
	var mule := PhysicalOptions.for_target(s, a, back).filter(func(o: Dictionary) -> bool: return o["to_hit"].possible())
	check_eq(mule.size(), 2, "mule kicks into the rear arc")
	check(Location.is_leg(mule[0]["limb"]), "with the rear legs")
	a.structure[Location.LA] = 0
	check(PhysicalOptions.for_target(s, a, back).all(func(o: Dictionary) -> bool: return not o["to_hit"].possible()),
			"no mule kicks after losing a leg")


func test_no_torso_twist() -> void:
	var s := GameState.new(open_map(5, 5))
	var gc := GameController.new(s)
	var u := _quad(hex_at(2, 2))
	s.add_unit(u)
	s.phase = Phase.Kind.WEAPON_ATTACK
	check(not gc.set_torso_twist(u, 1))


func test_lateral_shift() -> void:
	var s := GameState.new(open_map(6, 6))
	var u := _quad(hex_at(2, 3), 0)
	s.add_unit(u)
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	var side := MoveOptions.key(Hex.neighbor(u.coord, 1), 0)
	check_eq(opts.cost.get(side, -1), 2, "ahead-right, still facing north: 1 MP + 1")
	var back := MoveOptions.key(Hex.neighbor(u.coord, 4), 0)
	check_eq(opts.cost.get(back, -1), 2, "behind-left while walking")
	check(LateralShift.is_backward(u.coord, Hex.neighbor(u.coord, 4), 0))
	var run := MovePlanner.plan(s, u, MoveMode.Kind.RUN)
	check(run.prev.get(back) != MoveOptions.key(u.coord, 0), "no backward shifts when running")
	check_eq(run.cost.get(side, -1), 2)
	u.structure[Location.RL] = 0
	check(MovePlanner.plan(s, u, MoveMode.Kind.WALK).cost.get(side, -1) > 2, "a lost leg ends sideways steps")


func test_quad_designs_load() -> void:
	for id in ["goliath_gol1h", "scorpion_scp1n", "tarantula_zph1a"]:
		var u := mech(id, 0, hex_at(1, 1))
		check(u.def.quad, id)
		check_eq(Location.legs(u.def).size(), 4)
