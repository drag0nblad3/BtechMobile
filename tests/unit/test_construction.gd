extends TestCase
## XL engines, endo steel, ferro-fibrous armor and inapplicable slots.


func _def(extra: Dictionary) -> UnitDef:
	var d := {"id": "t", "name": "Test", "tonnage": 50, "walk_mp": 5,
			"armor": {"LT": 10, "RT": 10, "CT": 10}}
	d.merge(extra, true)
	return UnitDef.from_dict(d, weapons())


func _count(u: Unit, loc: int, kind: int) -> int:
	return u.slots[loc].filter(func(s: CritSlot) -> bool: return s.kind == kind).size()


func test_xl_layout_and_weight() -> void:
	var std := _def({})
	var xl := _def({"engine_type": "xl"})
	var u := Unit.new(1, xl, 0, Vector2i.ZERO, 0)
	check_eq(_count(u, Location.LT, CritSlot.Kind.ENGINE), 3, "3 engine slots in LT")
	check_eq(_count(u, Location.RT, CritSlot.Kind.ENGINE), 3, "and in RT")
	check_eq(_count(u, Location.CT, CritSlot.Kind.ENGINE), 6, "CT unchanged")
	check_eq(DesignWeight.breakdown(std)["engine"], 12.5, "250 standard")
	check_eq(DesignWeight.breakdown(xl)["engine"], 6.5, "250 XL: half, rounded up")
	check(BattleValue.breakdown(xl)["structure"] < BattleValue.breakdown(std)["structure"], "XL lowers BV")


func test_xl_side_torso_loss_kills() -> void:
	var u := Unit.new(1, _def({"engine_type": "xl"}), 0, Vector2i.ZERO, 0)
	Damage.destroy_location(u, Location.RT)
	check_eq(u.engine_hits, 3)
	check(u.destroyed, "side torso lost: engine gone")
	check(u.destroyed_reason.begins_with("XL engine"), u.destroyed_reason)
	check(u.is_location_destroyed(Location.RA), "arm goes with it")


func test_xl_counts_earlier_engine_hits_once() -> void:
	var u := Unit.new(1, _def({"engine_type": "xl"}), 0, Vector2i.ZERO, 0)
	var s: CritSlot = u.slots[Location.LT][0]
	s.hit = true
	u.engine_hits = 1
	XlEngine.on_torso_lost(u, Location.LT)
	check_eq(u.engine_hits, 3, "the slot already hit isn't counted twice")


func test_standard_engine_side_torso_loss() -> void:
	var u := Unit.new(1, _def({}), 0, Vector2i.ZERO, 0)
	Damage.destroy_location(u, Location.LT)
	check_eq(u.engine_hits, 0)
	check(not u.destroyed)


func test_endo_ferro_slots_and_weight() -> void:
	var eq := {"LT": ["endo_steel*7", "ferro_fibrous*5"], "RT": ["endo_steel*7", "ferro_fibrous*5"],
			"LA": ["ferro_fibrous*4"]}
	var def := _def({"structure_type": "endo_steel", "armor_type": "ferro_fibrous", "equipment": eq})
	var u := Unit.new(1, def, 0, Vector2i.ZERO, 0)
	check_eq(_count(u, Location.LT, CritSlot.Kind.BULK), 12, "item*N repeats")
	check_eq(DesignWeight.breakdown(def)["structure"], 2.5, "endo: half of 5 t")
	var armor_def := _def({"armor": {"CT": 179}})
	var ferro_def := _def({"armor": {"CT": 179}, "armor_type": "ferro_fibrous"})
	check_eq(DesignWeight.breakdown(armor_def)["armor"], 11.5, "179 standard points")
	check_eq(DesignWeight.breakdown(ferro_def)["armor"], 10.0, "ferro: 17.92 per ton")


func test_inapplicable_slots() -> void:
	var eq := {"LA": ["ferro_fibrous*8"], "LT": ["case", "ammo:ac20"]}
	var u := Unit.new(1, _def({"equipment": eq}), 0, Vector2i.ZERO, 0)
	for s: CritSlot in u.slots[Location.LT]:
		if s.kind == CritSlot.Kind.CASE:
			check(not s.can_be_hit(), "CASE can't take a critical")
	var st := GameState.new(open_map(3, 3))
	st.add_unit(u)
	var events := []
	var emit := func(t: Variant, d: Dictionary) -> void: events.append(t)
	# LA: 4 actuators + 8 ferro. Even picking the last slot, every critical
	# lands on an actuator.
	var dice := LoadedDice.new()
	dice.pick_queue.assign([11, 11, 11, 11])
	for i in 4:
		CriticalHits.apply_one(st, dice, emit, u, Location.LA)
	for s: CritSlot in u.slots[Location.LA]:
		check_eq(s.hit, s.kind == CritSlot.Kind.ACTUATOR, s.name)
