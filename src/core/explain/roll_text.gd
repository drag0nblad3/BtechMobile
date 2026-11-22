class_name RollText
extends RefCounted
## One short line per dice roll for the on-screen roll feed:
## who rolled, what for, the 2d6 result against the number needed, and the
## outcome. Returns {} for events that are not rolls worth showing.


static func line(e: GameEvent, s: GameState) -> Dictionary:
	var d := e.data
	match e.type:
		GameEvent.WEAPON_FIRED:
			var who := _who(s, d.get("attacker_id", -1))
			var what := "%s%s" % [who, String(d.get("weapon", "Weapon"))]
			if d.get("no_ammo", false):
				return {"text": what + "  ·  out of ammo", "tone": "warn"}
			var hit: bool = d.get("hit", false)
			var tail := "HIT" if hit else ("NO LOCK" if d.get("streak_held", false) else "MISS")
			return {"text": _roll(what, d) + tail, "tone": "good" if hit else "bad"}
		GameEvent.PHYSICAL:
			if int(d.get("roll", 0)) == 0:
				return {}
			var what := _who(s, d.get("attacker_id", -1)) + String(d.get("kind", "attack")).capitalize()
			var hit: bool = d.get("hit", false)
			return {"text": _roll(what, d) + ("HIT" if hit else "MISS"), "tone": "good" if hit else "bad"}
		GameEvent.DAMAGE:
			var u := s.unit_by_id(int(d.get("unit_id", -1)))
			var where := ""
			if u != null and u.vehicle == null and u.ba == null and u.asset == null and d.has("loc"):
				where = " → " + Location.code_for(u.def, int(d["loc"])) + (" (rear)" if d.get("rear", false) else "")
			return {"text": "    %s%d damage%s" % [_who(s, d.get("unit_id", -1)), int(d.get("amount", 0)), where], "tone": "info"}
		GameEvent.PSR:
			return _check(s, d, "Piloting roll", "OK", "FAILED")
		GameEvent.HEAT_ROLL:
			var kind := String(d.get("kind", ""))
			var label := "Ammo cook-off" if kind == "ammo" else "Restart" if kind == "restart" else "Avoid shutdown"
			return _check(s, d, label, "OK", "FAILED")
		GameEvent.CONSCIOUSNESS:
			var awake: bool = d.get("conscious", true)
			return {"text": _roll(_who(s, d.get("unit_id", -1)) + "Stay conscious", d) + ("OK" if awake else "KNOCKED OUT"),
					"tone": "good" if awake else "bad"}
		GameEvent.MASC:
			return _check(s, d, "MASC", "OK", "FAILED")
		GameEvent.CRIT_CHECK:
			var n := int(d.get("crits", 0))
			if n <= 0:
				return {}
			return {"text": "    %sCritical roll %d  ·  %d critical hit%s" % [_who(s, d.get("unit_id", -1)),
					int(d.get("roll", 0)), n, "" if n == 1 else "s"], "tone": "bad"}
	return {}


static func _check(s: GameState, d: Dictionary, label: String, ok_text: String, fail_text: String) -> Dictionary:
	var ok: bool = d.get("ok", false)
	return {"text": _roll(_who(s, d.get("unit_id", -1)) + label, d) + (ok_text if ok else fail_text),
			"tone": "good" if ok else "bad"}


static func _roll(what: String, d: Dictionary) -> String:
	var need := int(d.get("need", 0))
	if need > 12:
		return "%s  ·  needed %d (impossible)  ·  " % [what, need]
	return "%s  ·  rolled %d, needed %d+  ·  " % [what, int(d.get("roll", 0)), need]


static func _who(s: GameState, id: Variant) -> String:
	var u := s.unit_by_id(int(id)) if s != null else null
	return (u.def.name + ": ") if u != null else ""
