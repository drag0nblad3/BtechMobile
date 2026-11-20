class_name Explainer
extends RefCounted
## Turns GameEvents into log text at a chosen ExplainLevel. FULL adds the
## reason behind each number; LIGHT gives the numbers; OFF gives outcomes.
## Returns "" for events not worth a line at that level. It remembers what it
## already explained (phase intros once per battle, each modifier's reason
## once per phase) so FULL doesn't repeat itself.

var level: int
var seen := {}


func _init(explain_level: int = ExplainLevel.FULL) -> void:
	level = explain_level


func describe(e: GameEvent, s: GameState) -> String:
	if e.type == GameEvent.PHASE_CHANGED:
		_forget_mods()
	return text(e, s, level, seen)


func _forget_mods() -> void:
	for k: String in seen.keys():
		if k.begins_with("mod:"):
			seen.erase(k)


## Stateless form; `seen` (optional) suppresses repeated reasons.
static func text(e: GameEvent, s: GameState, level: int, seen: Dictionary = {}) -> String:
	var d := e.data
	match e.type:
		GameEvent.TURN_STARTED:
			return "Turn %d" % d["turn"]
		GameEvent.INITIATIVE:
			return _initiative(d, level)
		GameEvent.PHASE_CHANGED:
			var t := "%s Phase" % Phase.name_of(d["phase"])
			var key := "phase:%d" % d["phase"]
			if level == ExplainLevel.FULL and not seen.has(key):
				seen[key] = true
				t += "\n" + RulesText.phase(d["phase"])
			return t
		GameEvent.UNIT_MOVED:
			return _moved(s, d, level)
		GameEvent.FIRE_DECLARED:
			return _declared(s, d, level)
		GameEvent.WEAPON_FIRED:
			return _fired(s, d, level, seen)
		GameEvent.PHYSICAL:
			return _physical(s, d, level, seen)
		GameEvent.DAMAGE:
			return DamageText.damage(s, d, level)
		GameEvent.CRIT_CHECK:
			return DamageText.crit_check(s, d, level)
		GameEvent.CRITICAL:
			return "  Critical hit on %s %s: %s" % [_u(s, d), Location.name_of(d["loc"]), d["effect"]]
		GameEvent.UNIT_DESTROYED:
			return "%s is destroyed (%s)!" % [_u(s, d), d["reason"]]
		GameEvent.AMMO_EXPLOSION:
			return DamageText.ammo(s, d, level)
		GameEvent.HEAT, GameEvent.HEAT_ROLL, GameEvent.SHUTDOWN:
			return HeatText.describe(e, s, level)
		GameEvent.PSR, GameEvent.FALL, GameEvent.STAND, GameEvent.PILOT_HIT, GameEvent.CONSCIOUSNESS:
			return PilotText.describe(e, s, level, seen)
		GameEvent.GAME_OVER:
			return "Battle over: %s wins." % Names.side(d["winner"]) if d["winner"] >= 0 else "Battle over: no survivors."
	return ""


static func _u(s: GameState, d: Dictionary, key: String = "unit_id") -> String:
	return Names.unit(s.unit_by_id(d[key]))


static func _initiative(d: Dictionary, level: int) -> String:
	var parts: Array[String] = []
	for side: int in d["rolls"]:
		parts.append("%s %d" % [Names.side(side), d["rolls"][side]])
	var first: int = d["order"][0]
	var t := "Initiative: %s. %s acts first." % [", ".join(parts), Names.side(first)]
	if level == ExplainLevel.FULL:
		t += " Losing initiative means moving first; the winner sees your moves before making theirs."
	return t


static func _moved(s: GameState, d: Dictionary, level: int) -> String:
	var mode: int = d["mode"]
	var hexes: int = d["hexes"]
	if mode < 0:
		return "%s stands still." % _u(s, d) + (" Its shots get no movement penalty." if level == ExplainLevel.FULL else "")
	var t := "%s %s %d hex%s (%d MP)." % [_u(s, d), "ran" if mode == MoveMode.Kind.RUN else "walked",
			hexes, "" if hexes == 1 else "es", d["mp"]]
	if level == ExplainLevel.OFF:
		return t
	var own := 2 if mode == MoveMode.Kind.RUN else 1
	var tm := ToHitCalc.target_movement_mod(hexes)
	t += " Own shots +%d; enemies +%d to hit it." % [own, tm]
	if level == ExplainLevel.FULL and tm == 0 and hexes > 0:
		t += " Moving 3+ hexes would make it harder to hit."
	return t


static func _declared(s: GameState, d: Dictionary, level: int) -> String:
	if level == ExplainLevel.OFF:
		return ""
	if d["shots"].is_empty():
		return "%s holds fire." % _u(s, d)
	var parts: Array[String] = []
	for sh: Dictionary in d["shots"]:
		parts.append("%s at %s (%d+)" % [sh["weapon"], Names.unit(s.unit_by_id(sh["target_id"])), sh["need"]])
	return "%s fires: %s." % [_u(s, d), ", ".join(parts)]


static func _fired(s: GameState, d: Dictionary, level: int, seen: Dictionary) -> String:
	var who := "%s %s -> %s" % [_u(s, d, "attacker_id"), d["weapon"], _u(s, d, "target_id")]
	if d.get("no_ammo", false):
		return "%s: out of ammo." % who
	var res := "HIT" if d["hit"] else "miss"
	if d["missiles"] > 0:
		res += ", %d missiles" % d["missiles"]
	if level == ExplainLevel.OFF:
		return "%s: %s" % [who, res]
	var t := "%s: rolled %d, needed %d: %s" % [who, d["roll"], d["need"], res]
	if d["roll"] == 2 and d["need"] <= 2:
		t += " (a 2 always misses)"
	return t + ModsText.lines(d["mods"], level, seen)


static func _physical(s: GameState, d: Dictionary, level: int, seen: Dictionary) -> String:
	var limb := Location.name_of(d["limb"]).to_lower()
	var who := "%s %ss %s (%s)" % [_u(s, d, "attacker_id"), d["kind"], _u(s, d, "target_id"), limb]
	var res := "HIT for %d" % d["damage"] if d["hit"] else "miss"
	if level == ExplainLevel.OFF:
		return "%s: %s" % [who, res]
	return "%s: rolled %d, needed %d: %s" % [who, d["roll"], d["need"], res] + ModsText.lines(d["mods"], level, seen)
