class_name Tutorial
extends RefCounted
## Lessons for a guided scenario, each shown once when its trigger event
## happens. Lessons live in the scenario JSON under "lessons":
##   {"event": "phase_changed", "phase": "Movement", "turn": 1,
##    "unit_side": 0, "title": "...", "text": "..."}
## "event" is a GameEvent type; the other keys are optional filters:
## turn / min_turn, phase, unit_side (the acting or hit unit's side, also
## attacker_id), kind (e.data.kind, e.g. a physical attack), min_heat.

var lessons: Array[Dictionary] = []
var shown: Dictionary = {}  ## Lesson index -> true.


static func from_scenario(path: String) -> Tutorial:
	var t := Tutorial.new()
	var data: Dictionary = JsonFile.read(path)
	for l: Dictionary in data.get("lessons", []):
		t.lessons.append(l)
	return t


## Lessons this event unlocks, in file order. Marks them shown.
func on_event(e: GameEvent, s: GameState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in lessons.size():
		if not shown.has(i) and _matches(lessons[i], e, s):
			shown[i] = true
			out.append(lessons[i])
	return out


static func _matches(l: Dictionary, e: GameEvent, s: GameState) -> bool:
	if String(e.type) != l.get("event", ""):
		return false
	if l.has("turn") and s.turn != int(l["turn"]):
		return false
	if l.has("min_turn") and s.turn < int(l["min_turn"]):
		return false
	if l.has("kind") and String(e.data.get("kind", "")) != l["kind"]:
		return false
	if l.has("phase") and Phase.name_of(int(e.data.get("phase", -1))) != l["phase"]:
		return false
	if l.has("unit_side"):
		var u := s.unit_by_id(int(e.data.get("unit_id", e.data.get("attacker_id", -1))))
		if u == null or u.side != int(l["unit_side"]):
			return false
	if l.has("min_heat") and int(e.data.get("heat", 0)) < int(l["min_heat"]):
		return false
	return true


func done() -> bool:
	return shown.size() == lessons.size()
