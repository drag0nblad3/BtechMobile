class_name Hint
extends RefCounted
## The Hint button: what the computer would do in the player's place, played
## at Elite, with its reasons. It only reads the state (the bot's planners
## put back anything they try and never roll dice), so asking for a hint
## changes nothing; the view pre-fills the suggestion for the player to
## confirm, change or ignore.

const FACINGS := ["north", "northeast", "southeast", "south", "southwest", "northwest"]
const HOW := "The computer scores every hex it can reach by the damage it could deal next phase, minus the damage enemies could deal back, minus heat."


## Movement: {key: Vector3i, mode, charge: target id or -1, text}.
static func move(state: GameState, u: Unit, level: int) -> Dictionary:
	var m := _as_elite(func(): return BotMove.plan(state, u))
	var face: String = FACINGS[(m["key"] as Vector3i).z]
	var t := "Hint: %s, facing %s." % [_cap(m["reason"]), face]
	if level == ExplainLevel.FULL:
		t += " " + HOW
	return {"key": m["key"], "mode": m["mode"], "charge": m.get("charge", -1), "text": t}


## Weapon attacks: {shots: [{weapon, target_id[, aim]}], twist, modes, text}.
static func fire(state: GameState, u: Unit, level: int) -> Dictionary:
	var f := _as_elite(func():
		var p := BotFire.plan(state, u)
		var aim := BotAim.choose(state, u, p["shots"])
		if aim != "":
			p["reason"] += "; " + aim
		return p)
	var t := "Hint: %s." % _cap(f["reason"])
	if f["twist"] == BotFire.FLIP:
		t += " Flip the arms to fire backwards."
	elif f["twist"] != 0:
		t += " Twist the torso %s first." % ("left" if f["twist"] < 0 else "right")
	if level == ExplainLevel.FULL and not f["shots"].is_empty():
		t += " Weapons are picked by damage per point of heat, and the rest are held once heat would slow you down."
	return {"shots": f["shots"], "twist": f["twist"], "modes": f.get("modes", {}), "text": t}


## Physical attacks: {attacks: [{kind, limb, target_id}], text}.
static func physical(state: GameState, u: Unit, level: int) -> Dictionary:
	var p := _as_elite(func(): return BotPhysical.plan(state, u))
	var t := "Hint: no physical attack is worth it here." if p["attacks"].is_empty() \
			else "Hint: %s." % _cap(p["reason"])
	if level == ExplainLevel.FULL and not p["attacks"].is_empty():
		t += " That is the attack with the most expected damage after the risk of falling."
	return {"attacks": p["attacks"], "text": t}


static func _as_elite(plan: Callable) -> Dictionary:
	var before := BotSkill.level
	BotSkill.use(BotSkill.Level.ELITE)
	var out: Dictionary = plan.call()
	BotSkill.use(before)
	return out


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s
