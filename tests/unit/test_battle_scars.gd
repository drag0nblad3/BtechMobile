extends TestCase
## Scorches and wreck age come from stored event ledger, not new rule fields.


func test_recover_burn_marks_and_wreck_turns() -> void:
	var coord := Vector2i(3, 4)
	var frame := {"turn": 5, "event": "building",
			"state": {}, "events": [
				{"turn": 5, "event": "building",
					"data": BattleCodec.pack({"kind": "fire", "coord": coord})},
				{"turn": 5, "event": "unit_destroyed",
					"data": BattleCodec.pack({"unit_id": 7})}]}
	var history := BattleScarHistory.recover([frame])
	check_eq(history["scorches"][coord], 5, "burn persists after flames go out")
	check_eq(history["deaths"][7], 5, "smoke age restored from event history")


func test_heavy_hit_location_comes_from_historical_snapshot() -> void:
	var packed := {"properties": {"units": {"items": [
			{"properties": {"id": 9, "coord": {"$": "v2i", "x": 8, "y": 3}}}]}}}
	var frame := {"turn": 4, "event": "damage", "state": packed,
			"events": [{"turn": 4, "event": "damage",
					"data": BattleCodec.pack({"unit_id": 9, "amount": 22})}]}
	var result := BattleScarHistory.recover([frame])
	check_eq(result["scorches"][Vector2i(8, 3)], 4,
			"heavy hit must scar the original impact hex, not the current unit hex")


func test_old_wreck_smoke_goes_out_without_mutating_state() -> void:
	var scars := BattleScars.new()
	var p := GPUParticles3D.new()
	scars._smoke[4] = p
	scars._deaths[4] = 1
	var state := GameState.new(open_map(4, 4))
	state.turn = 5
	scars._state = state
	scars._update_smoke()
	check(not p.emitting, "smoulder must end after three turns")
	p.free()
	scars.free()
