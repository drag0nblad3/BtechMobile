extends TestCase


func test_radio_filters_opponent_and_hidden_units() -> void:
	var s := GameState.new(open_map(8, 8))
	var a := mech("atlas_as7d", 0, hex_at(2, 2))
	var b := mech("wolverine_wvr6r", 1, hex_at(3, 3))
	s.add_unit(a)
	s.add_unit(b)
	check(not BattleAtmosphere.call_for(GameEvent.new(GameEvent.FALL, {"unit_id": a.id}), s, [1]).is_empty())
	check_eq(BattleAtmosphere.call_for(GameEvent.new(GameEvent.FALL, {"unit_id": b.id}), s, [1]), "")
	check_eq(BattleAtmosphere.call_for(GameEvent.new(GameEvent.FALL, {"unit_id": -1}), s, [1]), "")
