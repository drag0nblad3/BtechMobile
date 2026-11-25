extends TestCase
## Replay reuse keys must distinguish damage but not unrelated rules changes.


func test_appearance_key_changes_only_for_visual_record() -> void:
	var u := mech("griffin_grf1n", 0, Vector2i.ZERO)
	var initial := ReplayUnitViews.appearance(u)
	u.heat += 5
	u.coord = Vector2i(1, 1)
	check_eq(ReplayUnitViews.appearance(u), initial)
	u.armor[Location.CT] -= 1
	check(ReplayUnitViews.appearance(u) != initial, "damage requires a model update")
	u.armor[Location.CT] += 1
	check_eq(ReplayUnitViews.appearance(u), initial, "rewind restores original key")
	u.destroyed = true
	check(ReplayUnitViews.appearance(u) != initial, "wreck needs new appearance")


func test_incremental_scar_history_equals_full_recovery() -> void:
	var s := GameState.new(open_map(4, 4))
	var u := mech("griffin_grf1n", 0, Vector2i.ZERO)
	s.add_unit(u)
	var r := BattleRecorder.new()
	r.begin(s)
	r.record(GameEvent.new(GameEvent.DAMAGE, {"unit_id": u.id, "amount": 15}), s, "Hit")
	s.turn += 1
	r.record(GameEvent.new(GameEvent.UNIT_DESTROYED, {"unit_id": u.id}), s, "Destroyed")
	var first := BattleScarHistory.recover(r.frames.slice(0, 2))
	var next := BattleScarHistory.recover(r.frames.slice(2), first)
	check_eq(next, BattleScarHistory.recover(r.frames))
	check(first["deaths"].is_empty(), "earlier history remains immutable")
