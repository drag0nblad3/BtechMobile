class_name TrainingPractice
extends RefCounted
## Optional, observable skill checks for a training battle. Checks are fed by
## real GameEvents; they never change rules, rewards, or mission unlocks.
## The battle ledger can rebuild them after loading a saved training game.

var goals: Array[Dictionary] = []
var completed: Dictionary = {}
var _unit_sets: Dictionary = {}


static func from_mission(mission: Dictionary) -> TrainingPractice:
	var practice := TrainingPractice.new()
	for goal: Dictionary in mission.get("practice", []):
		practice.goals.append(goal)
	return practice


func observe(e: GameEvent, state: GameState, player_side: int) -> Array[String]:
	return _record(String(e.type), e.data, state, player_side, state.turn)


func restore(frames: Array, state: GameState, player_side: int) -> void:
	for frame: Dictionary in frames:
		for fact: Dictionary in frame.get("events", []):
			var kind := String(fact.get("event", ""))
			var relevant := false
			for goal: Dictionary in goals:
				if String(goal.get("event", "")) == kind:
					relevant = true
					break
			if not relevant:
				continue
			var data: Variant = BattleCodec.unpack(fact.get("data", {}), null, null)
			if data is Dictionary:
				_record(kind, data, state, player_side, int(fact.get("turn", 0)))


func _record(kind: String, data: Dictionary, state: GameState,
		player_side: int, turn: int) -> Array[String]:
	var fresh: Array[String] = []
	for i in goals.size():
		if completed.has(i):
			continue
		var goal := goals[i]
		if not _matches(goal, kind, data, state, player_side, turn):
			continue
		if goal.has("distinct_units"):
			var unit_id := int(data.get("attacker_id", data.get("unit_id", -1)))
			if unit_id < 0:
				continue
			var seen: Dictionary = _unit_sets.get(i, {})
			seen[unit_id] = true
			_unit_sets[i] = seen
			if seen.size() < int(goal["distinct_units"]):
				continue
		completed[i] = true
		fresh.append(String(goal.get("title", "")))
	return fresh


static func _matches(goal: Dictionary, kind: String, data: Dictionary,
		state: GameState, player_side: int, turn: int) -> bool:
	if kind != String(goal.get("event", "")):
		return false
	if goal.has("min_turn") and turn < int(goal["min_turn"]):
		return false
	if goal.has("side"):
		var id := int(data.get("attacker_id", data.get("unit_id", -1)))
		var unit := state.unit_by_id(id)
		if unit == null:
			return false
		var wanted := player_side if goal["side"] == "player" else 1 - player_side
		if unit.side != wanted:
			return false
	if goal.has("source_side"):
		var source := state.unit_by_id(int(data.get("source_id", -1)))
		var source_wanted := player_side if goal["source_side"] == "player" else 1 - player_side
		if source == null or source.side != source_wanted:
			return false
	if goal.has("hit") and (not data.has("hit") or bool(data["hit"]) != bool(goal["hit"])):
		return false
	if goal.has("kind") and String(data.get("kind", "")) != String(goal["kind"]):
		return false
	if goal.has("max_need") and (not data.has("need") or int(data["need"]) > int(goal["max_need"])):
		return false
	if goal.has("max_heat") and (not data.has("heat") or int(data["heat"]) > int(goal["max_heat"])):
		return false
	if goal.has("min_hexes") and int(data.get("hexes", 0)) < int(goal["min_hexes"]):
		return false
	return true


func completed_count() -> int:
	return completed.size()


func summary() -> String:
	var report := "Practice checks: %d of %d\n" % [completed_count(), goals.size()]
	for i in goals.size():
		report += "%s %s\n" % ["✓" if completed.has(i) else "○", goals[i].get("title", "")]
	return report.strip_edges()
