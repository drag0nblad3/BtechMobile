extends TestCase
## Runtime audit: cached forecasts must match individual calculations,
## and field visibility must survive a condition refresh.


func test_cached_weapon_options_match_individual_shots() -> void:
	for terrain_row: String in ["c0 c0 c0", "c0 c3 c0", "c0 c0 c0"]:
		var s := GameState.new(make_map(["c0 c0 c0", "c0 c0 c0", terrain_row, "c0 c0 c0", "c0 c0 c0"]))
		var a := mech("wolverine_wvr6r", 0, hex_at(1, 0), 3, 1)
		var b := mech("griffin_grf1n", 1, hex_at(1, 4), 0, 2)
		s.add_unit(a)
		s.add_unit(b)
		for o: Dictionary in FireOptions.for_target(s, a, b):
			var cached: ToHit = o["to_hit"]
			var direct := ToHitCalc.weapon(s, a, o["weapon"], b)
			check_eq(cached.mods, direct.mods)
			check_eq(cached.impossible, direct.impossible)
			check_eq(cached.cover_hex, direct.cover_hex)
			check_eq(cached.indirect, direct.indirect)
			check_eq(cached.target(), direct.target())


func test_field_visibility_survives_condition_refresh() -> void:
	var v := UnitView.new()
	v.unit = mech("griffin_grf1n", 0, Vector2i.ZERO)
	v.set_field_visible(false)
	v.show_condition()
	check(not v.visible, "off-field unit must stay hidden")
	v.set_field_visible(true)
	v.show_condition()
	check(v.visible, "deployed unit must be visible")
	v.free()
