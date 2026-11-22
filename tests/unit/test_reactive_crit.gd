extends TestCase
## Critical hits on reactive armor slots (ReactiveCrit, p. 202).


func _unit(eq: Dictionary) -> Array:
	var d := UnitDef.from_dict({"id": "t", "name": "t", "tonnage": 50, "walk_mp": 4, "armor_type": "reactive",
			"armor": {"CT": 10, "LT": 10, "RT": 10, "LA": 10, "RA": 10, "LL": 10, "RL": 10, "HD": 9},
			"rear_armor": {"CT": 4, "LT": 4, "RT": 4}, "equipment": eq}, weapons())
	var s := GameState.new(open_map(4, 4))
	var u := Unit.new(1, d, 0, Vector2i.ZERO, 0)
	s.add_unit(u)
	return [s, u]


func test_a_two_blows_the_armor_then_the_hit_rerolls() -> void:
	var v := _unit({"LT": ["reactive*2", "heat_sink"]})
	var u: Unit = v[1]
	var hittable: int = u.slots[Location.LT].filter(func(c: CritSlot) -> bool: return c.can_be_hit()).size()
	var dice := LoadedDice.new()
	dice.pick_queue = [hittable, 0]  # first a reactive slot, then the reroll
	dice.queue_2d6(2)
	dice.queue_2d6(4)  # the 1 internal point's own critical check: none
	var s0 := u.structure[Location.LT]
	CriticalHits.apply_one(v[0], dice, func(_t: Variant, _d: Dictionary) -> void: pass, u, Location.LT)
	check_eq(u.armor[Location.LT], 0, "front armor gone")
	check_eq(u.rear_armor[Location.LT], 0, "rear armor gone")
	check_eq(s0 - u.structure[Location.LT], 1, "1 internal damage")
	check(u.slots[Location.LT].any(func(c: CritSlot) -> bool: return c.hit), "the hit is rerolled onto a real slot")


func test_other_rolls_do_nothing() -> void:
	var v := _unit({"LT": ["reactive*2"]})
	var u: Unit = v[1]
	var dice := LoadedDice.new()
	dice.pick_queue = [99, 0]
	dice.queue_2d6(7)
	CriticalHits.apply_one(v[0], dice, func(_t: Variant, _d: Dictionary) -> void: pass, u, Location.LT)
	check_eq(u.armor[Location.LT], 10, "armor stays")
	check_eq(ReactiveCrit.slots(u, Location.RT), 0, "no reactive slots in the right torso")


func test_only_reactive_slots() -> void:
	var v := _unit({"LT": ["reactive*2"]})
	var u: Unit = v[1]
	var dice := LoadedDice.new()
	dice.queue_2d6(7)
	CriticalHits.apply_one(v[0], dice, func(_t: Variant, _d: Dictionary) -> void: pass, u, Location.LT)
	check_eq(u.armor[Location.LT], 10, "not a 2: armor stays")
	check(u.slots[Location.CT].any(func(c: CritSlot) -> bool: return c.hit), "and the hit moves to the center torso")
