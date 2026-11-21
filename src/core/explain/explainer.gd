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
		GameEvent.INTENT:
			return "" if level == ExplainLevel.OFF else "%s (computer) %s." % [_u(s, d), d["text"]]
		GameEvent.CHARGE_DECLARED:
			var t := "%s will %s %s (%d+)." % [_u(s, d), "charge" if d["kind"] == "charge" else "jump onto",
					_u(s, d, "target_id"), d["need"]]
			if level == ExplainLevel.FULL:
				t += " It resolves in the Physical Attack Phase; until then it can't fire. Both 'Mechs take damage and must roll to stay up."
			return t
		GameEvent.SKID:
			var t := "%s skids %d hex%s and goes down." % [_u(s, d), d["hexes"], "" if d["hexes"] == 1 else "es"]
			if level == ExplainLevel.FULL:
				t += " Turning on pavement at a run is risky; the faster you were going, the harder the roll. Walk, or turn before reaching the road."
			return t
		GameEvent.DISPLACED:
			return "  %s is shoved into %s." % [_u(s, d), Hex.label(MoveOptions.coord_of(d["path"][0]))]
		GameEvent.DAMAGE:
			return DamageText.damage(s, d, level)
		GameEvent.BUILDING:
			return TerrainText.building_event(s, d, level)
		GameEvent.HULL_BREACH:
			return DamageText.breach(s, d, level)
		GameEvent.CRIT_CHECK:
			return DamageText.crit_check(s, d, level)
		GameEvent.CRITICAL:
			return "  Critical hit on %s %s: %s" % [_u(s, d), Location.name_of(d["loc"]), d["effect"]]
		GameEvent.UNIT_DESTROYED:
			var t := "%s is destroyed (%s)!" % [_u(s, d), d["reason"]]
			if level == ExplainLevel.FULL and String(d["reason"]).begins_with("XL engine"):
				t += " An XL engine saves weight but reaches into both side torsos, so losing either one is fatal."
			return t
		GameEvent.AMMO_EXPLOSION:
			return DamageText.ammo(s, d, level)
		GameEvent.CLUB:
			var t := "%s %s and holds it as a club." % [_u(s, d), "uproots a tree" if d["club"] == "tree" else "pulls a girder from the rubble"]
			if level == ExplainLevel.FULL:
				t += " Next physical phase it can swing it for 1 damage per 5 tons, and the target must make a piloting roll." + (
						" A tree breaks after one hit." if d["club"] == "tree" else "")
			return t
		GameEvent.HEAT, GameEvent.HEAT_ROLL, GameEvent.SHUTDOWN:
			return HeatText.describe(e, s, level)
		GameEvent.PSR, GameEvent.FALL, GameEvent.STAND, GameEvent.WENT_PRONE, GameEvent.PILOT_HIT, GameEvent.CONSCIOUSNESS:
			return PilotText.describe(e, s, level, seen)
		GameEvent.GAME_OVER:
			return "Battle over: %s wins." % Names.side(d["winner"]) if d["winner"] >= 0 else "Battle over: no survivors."
	return ""


static func _u(s: GameState, d: Dictionary, key: String = "unit_id") -> String:
	return Names.unit(s.unit_by_id(d[key]))


## A shot's target: a 'Mech, or a building hex.
static func _target(s: GameState, d: Dictionary) -> String:
	if d.has("target_hex"):
		return "the building at %s" % Hex.label(d["target_hex"])
	return Names.unit(s.unit_by_id(d["target_id"]))


static func _initiative(d: Dictionary, level: int) -> String:
	var parts: Array[String] = []
	for side: int in d["rolls"]:
		var b := int(d.get("bonus", {}).get(side, 0))
		parts.append("%s %d%s" % [Names.side(side), d["rolls"][side], " (+%d Initiative Die)" % b if b > 0 else ""])
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
	var t := "%s %s %d hex%s (%d MP)." % [_u(s, d), MoveMode.verb(mode),
			hexes, "" if hexes == 1 else "es", d["mp"]]
	if level == ExplainLevel.OFF:
		return t
	var own := MoveMode.attacker_mod(mode)
	var tm := ToHitCalc.target_movement_mod(hexes, mode == MoveMode.Kind.JUMP)
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
		var aim := " aimed at the %s" % Location.name_of(sh["aim"]).to_lower() if sh.has("aim") else ""
		parts.append("%s at %s%s (%d+)" % [sh["weapon"], _target(s, sh), aim, sh["need"]])
	return "%s fires: %s." % [_u(s, d), ", ".join(parts)]


static func _fired(s: GameState, d: Dictionary, level: int, seen: Dictionary) -> String:
	var who := "%s %s -> %s" % [_u(s, d, "attacker_id"), d["weapon"], _target(s, d)]
	if d.get("no_ammo", false):
		return "%s: out of ammo." % who
	var res := "HIT" if d["hit"] else "miss"
	if d.get("shots", 1) > 1:
		res += " (%d shots)" % d["shots"]
	if d["missiles"] > 0:
		var unit := "shots" if d.get("mode", "") == WeaponModes.ULTRA else (
				"pellets" if d.get("mode", "") == WeaponModes.CLUSTER else "missiles")
		res += ", %d %s" % [d["missiles"], unit]
		if d.get("cluster_bonus", 0) > 0 and level != ExplainLevel.OFF:
			res += " (Artemis +%d)" % d["cluster_bonus"]
	if d.get("streak_held", false) and level != ExplainLevel.OFF:
		res += "; the Streak never locked on, so it held its missiles (no heat, no ammo used)"
	if d.get("heat_added", 0) > 0:
		res += ", +%d heat to the target" % d["heat_added"]
	if d.has("aim_roll"):
		res += "; aim roll %d: %s" % [d["aim_roll"], ("lands on the " + Location.name_of(d["aim"]).to_lower())
				if d["aim_hit"] else "missed the aim, hit location rolled"]
		if level == ExplainLevel.FULL:
			res += " (aimed shots need 4+ on 1D6)"
	if level == ExplainLevel.OFF:
		return "%s: %s" % [who, res]
	var t := "%s: rolled %d, needed %d: %s" % [who, d["roll"], d["need"], res]
	if d["need"] <= 2:
		t += " (2 or less always hits)"
	return t + ModsText.lines(d["mods"], level, seen)


const PHYS_VERBS := {"punch": "punches", "kick": "kicks", "push": "pushes",
		"charge": "charges", "dfa": "jumps on", "hatchet": "hacks at",
		"sword": "slashes", "club": "clubs"}


static func _physical(s: GameState, d: Dictionary, level: int, seen: Dictionary) -> String:
	var who := "%s %s %s" % [_u(s, d, "attacker_id"), PHYS_VERBS.get(d["kind"], d["kind"]), _target(s, d)]
	if d["limb"] >= 0:
		who += " (%s)" % Location.name_of(d["limb"]).to_lower()
	var res := "HIT for %d" % d["damage"] if d["hit"] else "miss"
	if d.get("why", "") != "":
		var t := "%s: automatic miss, %s" % [who, d["why"]]
		if level == ExplainLevel.FULL:
			t += ". Once declared, a death from above can't be called off, so it lands as a miss."
		return t
	if level == ExplainLevel.OFF or d.has("target_hex"):
		return "%s: %s" % [who, res] + (" (buildings can't dodge)" if level == ExplainLevel.FULL and d.has("target_hex") else "")
	return "%s: rolled %d, needed %d: %s" % [who, d["roll"], d["need"], res] + ModsText.lines(d["mods"], level, seen)
