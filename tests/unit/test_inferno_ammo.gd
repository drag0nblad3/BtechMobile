extends TestCase
## Inferno ammo cooking off (InfernoAmmo, pp. 107, 192).


func test_avoid_numbers() -> void:
	check_eq(InfernoAmmo.avoid(9), 0)
	check_eq(InfernoAmmo.avoid(10), 4)
	check_eq(InfernoAmmo.avoid(19), 8)
	check_eq(InfernoAmmo.avoid(28), 12)


func test_explosion_adds_heat() -> void:
	var def := UnitDef.from_dict({"id": "x", "name": "x", "tonnage": 75, "walk_mp": 4,
			"armor": {"CT": 30, "LT": 20, "RT": 20, "LA": 20, "RA": 20, "LL": 20, "RL": 20, "HD": 9},
			"rear_armor": {"CT": 10, "LT": 8, "RT": 8}, "equipment": {"RA": ["arrow_iv~7"], "LT": ["ammo:arrow_iv:inferno"]}}, weapons())
	var s := GameState.new(open_map(4, 4))
	var u := Unit.new(1, def, 0, hex_at(1, 1), 0)
	s.add_unit(u)
	u.heat = 12
	var dice := LoadedDice.new()
	dice.queue_2d6(3)  # needs 4+ at 12 heat: it blows
	dice.queue_2d6(12)  # shutdown roll at the new heat
	dice.queue_2d6(12)  # inferno roll again: the bin is gone, so none
	InfernoAmmo.check(s, dice, func(_t: Variant, _d: Dictionary) -> void: pass, u)
	check_eq(u.heat, 12 + 2 * 5, "2 heat a missile left: 5 shots")
	check(u.ammo[0].destroyed, "the bin is gone")
