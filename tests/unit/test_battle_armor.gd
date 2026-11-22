extends TestCase
## Battle armor squads: record sheets, squad fire, trooper damage, movement,
## the force builder and saves.


func _squad(def_id: String, side: int, at: Vector2i, facing: int = 0, uid: int = 0) -> Unit:
	var db := UnitDb.new()
	db.weapons = WeaponDb.load_file()
	db.add_battle_armor(UnitDb.BA_DIR)
	return Unit.new(uid if uid > 0 else side * 10 + at.x + 1, db.get_def(def_id), side, at, facing)


func test_sheets_load_as_squads() -> void:
	var db := UnitDb.load_dir()
	check_eq(db.sorted_battle_armor().size(), 72)
	check(not db.by_id.has("elemental_ba_laser"), "not in the 'Mech list")
	var e := _squad("elemental_ba_laser", 0, hex_at(0, 0))
	check_eq(e.def.bv, 447, "sheet BV")
	check(e.def.is_clan() and e.def.is_support(), "Clan support unit")
	check_eq(e.ba.alive(), 5)
	check_eq(gun(e, "ba_small_laser").def.missiles, 5, "a laser shot per trooper")
	check_eq(gun(e, "ba_srm2").def.missiles, 10, "two missiles per trooper")
	check_eq(e.ammo_for(gun(e, "ba_srm2").def), 2, "two SRM volleys")
	check_eq(e.walk_mp(), 1)
	check_eq(e.jump_mp(), 3)


func test_hits_strike_one_trooper_each() -> void:
	var sq := _squad("is_standard_ba_laser", 1, hex_at(0, 0))
	var log: Array = []
	var emit := func(t: StringName, d: Dictionary) -> void: log.append(d)
	var dice := LoadedDice.new([2, 2])
	BaDamage.take(dice, emit, sq, 5, 0, "test")
	check_eq(sq.ba.troopers[1], 4, "5 of 9 armor gone")
	BaDamage.take(dice, emit, sq, 10, 0, "test")
	check_eq(sq.ba.troopers[1], BaState.DEAD, "damage past its armor kills it")
	check_eq(gun(sq, "ba_small_laser").def.missiles, 3, "three troopers fire now")
	dice = LoadedDice.new([2, 6, 1, 3, 4])  # 2 is dead and 6 doesn't exist: rerolled
	BaDamage.take(dice, emit, sq, 20, 0, "test")
	check_eq(sq.ba.troopers[0], BaState.DEAD)
	BaDamage.take(dice, emit, sq, 20, 0, "test")
	BaDamage.take(dice, emit, sq, 20, 0, "test")
	check(sq.destroyed, "last trooper down")


func test_squads_fire_all_round_and_are_hard_to_hit() -> void:
	var s := GameState.new(open_map(6, 6))
	var sq := _squad("elemental_ba_mg", 0, hex_at(2, 2), 0, 1)
	var m := mech("hunchback_hbk4g", 1, hex_at(2, 4), 0, 2)
	s.add_unit(sq)
	s.add_unit(m)
	check(ToHitCalc.weapon(s, sq, gun(sq, "ba_machine_gun"), m).possible(), "fires behind itself")
	var th := ToHitCalc.weapon(s, m, gun(m, "medium_laser"), sq)
	check(th.mods.any(func(x: Dictionary) -> bool: return x.get("label", "") == "battle armor"), "+1 vs battle armor")


func test_no_water_or_buildings() -> void:
	var s := GameState.new(make_map(["c0 w0d1 c0"]))
	var sq := _squad("is_standard_ba_mg", 0, hex_at(0, 0), 1)
	s.add_unit(sq)
	check_eq(BaMoveCost.enter_cost(s.map, hex_at(0, 0), hex_at(1, 0), MoveMode.Kind.WALK), MoveCost.PROHIBITED)
	var jump := MovePlanner.plan(s, sq, MoveMode.Kind.JUMP)
	check(not jump.can_end.get(MoveOptions.key(hex_at(1, 0), 1), false), "can't land in water")
	check(jump.reachable_hexes().has(hex_at(2, 0)), "jumps over it")


func test_bought_deployed_and_saved() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 9000)
	fb.add(0, "atlas_as7d")
	check(fb.add(0, "elemental_ba_ap_gauss"), "buy a squad")
	check_eq(fb.asset_ids(0).size(), 1, "counts as support")
	fb.add(1, "griffin_grf1n")
	var gc := GameController.new(fb.build(MapLoader.load_file("res://data/maps/river_crossing.json", terrain())), 3)
	var sq: Unit = gc.state.units.filter(func(u: Unit) -> bool: return u.ba != null)[0]
	check(BaMoveCost.may_enter(gc.state.map.get_tile(sq.coord)), "deployed on dry ground")
	sq.ba.troopers[2] = BaState.DEAD
	BaDamage.resize_weapons(sq)
	var restored := BattleSave.restore(BattleSave.capture(gc, [], BotSkill.Level.REGULAR, -1, []), UnitDb.load_dir(), terrain())
	var r: Unit = restored["controller"].state.unit_by_id(sq.id)
	check_eq(r.ba.alive(), 4, "troopers saved")
	check_eq(gun(r, "ba_ap_gauss").def.missiles, 4, "squad attack size saved")
	check_eq(r.ammo_for(gun(r, "ba_srm2").def), 2, "ammo still matches its weapon")


func test_leg_attack() -> void:
	var s := GameState.new(open_map(4, 4))
	var sq := _squad("elemental_ba_laser", 0, hex_at(1, 1), 0, 1)
	var m := mech("hunchback_hbk4g", 1, hex_at(1, 2), 0, 2)
	s.add_unit(sq)
	s.add_unit(m)
	var leg := gun(sq, BaLegAttack.ID)
	check(not ToHitCalc.weapon(s, sq, leg, m).possible(), "needs the 'Mech's hex")
	sq.coord = m.coord
	var th := ToHitCalc.weapon(s, sq, leg, m)
	check_eq(th.target(), 5, "anti-'Mech skill 5, five troopers")
	sq.ba.troopers[0] = BaState.DEAD
	sq.ba.troopers[1] = BaState.DEAD
	check_eq(ToHitCalc.weapon(s, sq, leg, m).target(), 7, "three troopers: +2")
	var decl := FireOptions.declare(s, sq, [{"weapon": 0, "target_id": 2}, {"weapon": sq.weapons.find(leg), "target_id": 2}])
	check(decl.size() == 1 and BaLegAttack.is_leg_attack(sq.weapons[decl[0]["weapon_index"]]), "the leg attack is the whole attack")
	var dice := LoadedDice.new()
	dice.queue_2d6(9)
	dice.pick_queue.append(1)
	dice.queue_2d6(2)  # critical check
	var before := m.armor[Location.RL]
	BaLegAttack.resolve(s, dice, func(_t: StringName, _d: Dictionary) -> void: pass, sq, leg, m, ToHitCalc.weapon(s, sq, leg, m))
	check_eq(before - m.armor[Location.RL], 4, "4 damage to the right leg")


func test_rides_omnimech() -> void:
	var s := GameState.new(open_map(4, 4))
	var omni := mech("timber_wolf_prime", 0, hex_at(1, 1), 0, 1)
	var sq := _squad("elemental_ba_laser", 0, hex_at(1, 1), 0, 2)
	s.add_unit(omni)
	s.add_unit(sq)
	check_eq(AssetTransport.capacity(mech("griffin_grf1n", 0, hex_at(0, 0)), sq), 0, "only OmniMechs")
	var emit := func(_t: StringName, _d: Dictionary) -> void: pass
	check_eq(AssetTransport.board_problem(s, sq, omni), "")
	AssetTransport.board(s, emit, sq, omni)
	check(not sq.can_act() and s.unit_at(omni.coord) == omni, "rides, not a unit while aboard")
	var before := omni.armor[Location.RT]
	WeaponFire.hit_with(s, LoadedDice.new(), emit, omni, FiringArc.FRONT, 5, 9, "test",
			{"loc": Location.RT, "rear": false, "tac": false})
	check_eq(sq.ba.troopers[0], 5, "trooper 1 on the right torso takes it")
	check_eq(omni.armor[Location.RT], before, "the 'Mech is shielded")
	WeaponFire.hit_with(s, LoadedDice.new(), emit, omni, FiringArc.FRONT, 10, 9, "test",
			{"loc": Location.RT, "rear": false, "tac": false})
	check_eq(omni.armor[Location.RT], before - 4, "damage past the trooper goes on")
	AssetTransport.deploy(s, emit, sq)
	check(ToHitCalc.weapon(s, sq, sq.weapons[0], omni).impossible != "", "no attacks the turn it climbs down")


func test_swarm_attack() -> void:
	var s := GameState.new(open_map(4, 4))
	var sq := _squad("elemental_ba_laser", 0, hex_at(1, 2), 0, 1)
	var m := mech("hunchback_hbk4g", 1, hex_at(1, 2), 0, 2)
	s.add_unit(sq)
	s.add_unit(m)
	var emit := func(_t: StringName, _d: Dictionary) -> void: pass
	var swarm := gun(sq, BaSwarm.ID)
	check_eq(ToHitCalc.weapon(s, sq, swarm, m).target(), 7, "skill 5, five troopers +2")
	var dice := LoadedDice.new()
	dice.queue_2d6(7)
	BaSwarm.resolve(s, dice, emit, sq, swarm, m, ToHitCalc.weapon(s, sq, swarm, m))
	check_eq(BaSwarm.on(sq), m.id, "on the 'Mech")
	check_eq(sq.walk_mp(), 0, "rides it")
	check(ToHitCalc.weapon(s, sq, gun(sq, "ba_small_laser"), m).auto_hit != "", "its guns can't miss")
	m.coord = hex_at(2, 2)
	BaSwarm.update(s, emit)
	check_eq(sq.coord, m.coord, "goes where the 'Mech goes")
	var brush: Array = PhysicalOptions.for_target(s, m, sq)
	check(brush.size() == 2 and brush[0]["kind"] == "brush_off", "the 'Mech can swat at it")
	check_eq(brush[0]["to_hit"].target(), 9, "piloting 5 +4")
	dice = LoadedDice.new([3])
	dice.queue_2d6(9)
	BaBrushOff.resolve(s, dice, emit, {"attacker_id": m.id, "target_id": sq.id, "limb": Location.LA,
			"to_hit": brush[0]["to_hit"], "damage": brush[0]["damage"]})
	check_eq(BaSwarm.on(sq), -1, "knocked off")
	check_eq(sq.ba.troopers[2], 5, "a 50-ton punch: 5 damage to one trooper")


func test_shaking_off_swarmers() -> void:
	var s := GameState.new(open_map(4, 4))
	var sq := _squad("elemental_ba_laser", 0, hex_at(1, 2), 0, 1)
	var m := mech("hunchback_hbk4g", 1, hex_at(1, 2), 0, 2)
	s.add_unit(sq)
	s.add_unit(m)
	var emit := func(_t: StringName, _d: Dictionary) -> void: pass
	var let_go := gun(sq, BaSwarm.LET_GO)
	check(not ToHitCalc.weapon(s, sq, let_go, m).possible(), "nothing to let go of")
	sq.ba.swarming = m.id
	check(ToHitCalc.weapon(s, sq, let_go, m).possible(), "it can let go")
	BaSwarm.let_go(emit, sq, let_go, m)
	check_eq(BaSwarm.on(sq), -1)
	sq.ba.swarming = m.id
	var dice := LoadedDice.new()
	dice.queue_2d6(5)  # 2D6 damage to the squad
	dice.d6_queue.append(2)  # trooper 2
	BaShakeOff.on_fall(s, dice, emit, m)
	check_eq(BaSwarm.on(sq), -1, "a fall throws them off")
	check(sq.ba.alive() == 5 and sq.ba.troopers[1] == 5, "2D6 (5) to one trooper")
	sq.ba.swarming = m.id
	dice = LoadedDice.new()
	dice.queue_2d6(9)  # piloting 5 +4: made
	BaShakeOff.after_jump(s, dice, emit, m, 3)
	check_eq(BaSwarm.on(sq), -1, "a jump shakes them off")
	check_eq(sq.ba.troopers[0], 7, "3 jump MP: 3 to each trooper")
