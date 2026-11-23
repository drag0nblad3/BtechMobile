extends TestCase
## Roll feed lines: 2d6 result against the number needed, and the outcome.


func test_roll_lines() -> void:
	var s := GameState.new(open_map(6, 6))
	var a := mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(3, 1), 3, 2)
	s.add_unit(a)
	s.add_unit(b)
	var shot := RollText.line(GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": 1,
			"weapon": "AC/20", "roll": 9, "need": 8, "hit": true}), s)
	check(String(shot["text"]).contains("rolled 9, needed 8+") and String(shot["text"]).ends_with("HIT"), "shot line")
	check_eq(shot["tone"], "good", "hit tone")
	var miss := RollText.line(GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": 1,
			"weapon": "AC/20", "roll": 4, "need": 13, "hit": false}), s)
	check(String(miss["text"]).contains("impossible"), "need over 12")
	var dmg := RollText.line(GameEvent.new(GameEvent.DAMAGE, {"unit_id": 2, "amount": 5, "loc": Location.LT}), s)
	check(String(dmg["text"]).contains("5 damage → LT"), "damage location")
	var psr := RollText.line(GameEvent.new(GameEvent.PSR, {"unit_id": 2, "roll": 5, "need": 7, "ok": false}), s)
	check(String(psr["text"]).ends_with("FAILED"), "failed piloting roll")
	check(RollText.line(GameEvent.new(GameEvent.TURN_STARTED, {"turn": 2}), s).is_empty(), "not a roll")
