extends TestCase
## Tactical Academy lessons: likely mistakes from recorded event facts.


func _fact(turn: int, event: StringName, data: Dictionary) -> Dictionary:
	return {"frame": turn, "turn": turn, "event": String(event), "text": "", "data": data}


func test_finds_common_mistakes() -> void:
	var labels := {"1": {"name": "Hunchback HBK-4G", "side": 0}}
	var timeline := [
		_fact(1, GameEvent.UNIT_MOVED, {"unit_id": 1, "mode": MoveMode.Kind.RUN, "hexes": 2}),
		_fact(1, GameEvent.UNIT_MOVED, {"unit_id": 1, "mode": MoveMode.Kind.RUN, "hexes": 5}),
		_fact(2, GameEvent.WEAPON_FIRED, {"attacker_id": 1, "need": 11, "hit": true}),
		_fact(2, GameEvent.WEAPON_FIRED, {"attacker_id": 1, "need": 12, "hit": false}),
		_fact(2, GameEvent.WEAPON_FIRED, {"attacker_id": 1, "need": 8, "hit": false}),
		_fact(2, GameEvent.WEAPON_FIRED, {"attacker_id": 1, "need": 13, "hit": false}),
		_fact(3, GameEvent.HEAT, {"unit_id": 1, "heat": 13}),
		_fact(3, GameEvent.HEAT, {"unit_id": 1, "heat": 19}),
		_fact(4, GameEvent.DAMAGE, {"unit_id": 1, "amount": 5, "rear": true}),
		_fact(4, GameEvent.DAMAGE, {"unit_id": 1, "amount": 5, "rear": false}),
	]
	var out := BattleLessons.find(timeline, labels)
	var titles := out.map(func(l): return l["title"])
	check_eq(titles, ["Ran for nothing", "Long shots", "Overheated", "Rear exposed"], "one of each, in turn order")
	check(String(out[0]["detail"]).begins_with("Red Hunchback"), out[0]["detail"])
	check(String(out[1]["detail"]).contains("2 shots"), "11+ and 12+ counted, 8+ and impossible not: " + out[1]["detail"])
	check(String(out[2]["lesson"]).contains("ammo"), "heat 19 also risks ammo")
	check(BattleLessons.find([], labels).is_empty(), "clean record")
