class_name Mission
extends RefCounted
## What a battle is fought for (book pp. 212-233). Without a Mission the
## last side with a 'Mech standing wins. Read from a scenario's "mission":
##   {"name": "Focal Point", "turns": 8, "random_duration": false,
##    "victory": "vp" | "last_standing", "unit_vp": true,
##    "forced_withdrawal": true, "scoring": "each" | "pairs" | "threshold",
##    "objectives": [{"hex": "0809", "radius": 2, "vp": 3}],
##    "home_edges": ["south", "north"], "exit": "home" | "enemy_home",
##    "exit_from_turn": 6, "scan": "" | "units" | "intel"}

var id := ""
var name := ""
var turns: int = 0  ## 0 = no time limit.
var random_duration := false
var victory := "last_standing"
var unit_vp := false
var forced_withdrawal := false
## How controlled objectives score in each End Phase:
## "each": every controlled objective gives its VP; "pairs": 1 VP per pair of
## one friendly and one enemy objective held; "threshold": 1 VP for holding
## two, 2 VP for holding three or more; "steel_rain": from turn 3 the attacker
## scores 1 VP per objective held (2 from turn 8), the defender 1 VP per
## objective held or held by nobody; "": none.
var scoring := ""
var objectives: Array[Objective] = []
var home_edges: Array[String] = ["south", "north"]
## Edge a unit may deliberately leave by to score ("home", "enemy_home"), or "".
var exit := ""
var exit_from_turn: int = 1
var exit_side: int = -1  ## Only this side may leave by the exit (-1 = both).
var attacker: int = -1
var ecm_interference := false  ## ECM Interference complication (EcmInterference).
var waves := false  ## Waves complication: half of each force arrives later (Waves).  ## Attacking side where the mission has one (Steel Rain scoring).
## What units scan in the End Phase (Scanning): "", "units" or "intel".
var scan := ""
var summary := ""  ## Plain-words goal for the player.
var notes: Array = []  ## Setup notes for the briefing (sides, complications).
## This side wins initiative automatically for the first `initiative_turns` turns (Ambush).
var initiative_side: int = -1
var initiative_turns: int = 0


static func from_dict(d: Dictionary) -> Mission:
	var m := Mission.new()
	m.id = d.get("id", "")
	m.name = d.get("name", "Mission")
	m.turns = int(d.get("turns", 0))
	m.random_duration = bool(d.get("random_duration", false))
	m.victory = d.get("victory", "last_standing")
	m.unit_vp = bool(d.get("unit_vp", false))
	m.forced_withdrawal = bool(d.get("forced_withdrawal", false))
	m.scoring = d.get("scoring", "")
	for o: Dictionary in d.get("objectives", []):
		m.objectives.append(Objective.from_dict(o))
	if d.has("home_edges"):
		m.home_edges.assign(d["home_edges"])
	m.exit = d.get("exit", "")
	m.exit_from_turn = int(d.get("exit_from_turn", 1))
	m.scan = d.get("scan", "")
	m.exit_side = int(d.get("exit_side", -1))
	m.attacker = int(d.get("attacker", -1))
	m.summary = d.get("summary", "")
	m.initiative_side = int(d.get("initiative_side", -1))
	m.initiative_turns = int(d.get("initiative_turns", 0))
	return m


func home_edge(side: int) -> String:
	return home_edges[side % home_edges.size()]


func uses_vp() -> bool:
	return victory == "vp"
