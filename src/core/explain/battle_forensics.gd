class_name BattleForensics
extends RefCounted
## Tactical Academy: objective post-battle measurements from the recorded
## GameEvent ledger. Never guesses a counterfactual outcome or rerolls dice.

## Two six-sided dice have 36 equally likely ordered outcomes.
static func chance_to_hit(need: int) -> float:
	var successes := 0
	for a in range(1, 7):
		for b in range(1, 7):
			if a + b >= need:
				successes += 1
	return float(successes) / 36.0


## labels: string unit id -> {name, side}, built from the final saved state.
static func analyze(frames: Array, labels: Dictionary = {}) -> Dictionary:
	var summary := {"attacks": 0, "hits": 0, "expected_hits": 0.0,
			"damage": 0, "kills": 0, "psr_failures": 0, "events": 0}
	var rows := {}
	for k: String in labels:
		_unit(rows, int(k), labels)
	var timeline: Array = []
	var moments: Array = []
	for i in frames.size():
		var frame: Dictionary = frames[i]
		var entries: Array = frame.get("events", [])
		for j in entries.size():
			var e: Dictionary = entries[j]
			var kind := String(e.get("event", ""))
			var d: Dictionary = _scalar_data(e.get("data", {}))
			var id := int(d.get("unit_id", -1))
			var label := String(e.get("text", kind))
			if label == "":
				label = kind.replace("_", " ").capitalize()
			# An unframed event is attached to the previous checkpoint.
			# The following checkpoint shows the closest subsequent state.
			var inspect := i if j == 0 and kind == String(frame.get("event", "")) \
					else mini(i + 1, frames.size() - 1)
			var fact := {"frame": inspect, "turn": int(e.get("turn", frame.get("turn", 0))),
					"event": kind, "text": label, "data": d}
			timeline.append(fact)
			summary["events"] += 1
			match kind:
				GameEvent.WEAPON_FIRED, GameEvent.PHYSICAL:
					if bool(d.get("no_ammo", false)):
						continue
					var attacker := int(d.get("attacker_id", -1))
					var u := _unit(rows, attacker, labels)
					var hit := bool(d.get("hit", false))
					var need := int(d.get("need", 99))
					var roll := int(d.get("roll", -1))
					summary["attacks"] += 1
					u["attacks"] += 1
					if hit:
						summary["hits"] += 1
						u["hits"] += 1
					if roll >= 2 and roll <= 12:
						var probability := chance_to_hit(need)
						summary["expected_hits"] += probability
						u["expected_hits"] += probability
						if hit and need >= 10:
							_moment(moments, fact, "Long-odds hit", label, 7)
						elif not hit and need <= 5:
							_moment(moments, fact, "Favored shot missed", label, 6)
				GameEvent.DAMAGE:
					var amount := maxi(0, int(d.get("amount", 0)))
					if amount > 0:
						var target := _unit(rows, id, labels)
						target["damage_taken"] += amount
						var source := int(d.get("source_id", -1))
						if source >= 0:
							_unit(rows, source, labels)["damage_dealt"] += amount
						summary["damage"] += amount
						if amount >= 15:
							_moment(moments, fact, "Heavy damage", label, 6 + mini(3, int(float(amount) / 15.0)))
				GameEvent.UNIT_DESTROYED:
					summary["kills"] += 1
					_unit(rows, id, labels)["destroyed"] = true
					_moment(moments, fact, "Unit destroyed", label, 10)
				GameEvent.AMMO_EXPLOSION:
					_moment(moments, fact, "Ammo explosion", label, 9)
				GameEvent.FALL:
					_moment(moments, fact, "Fall", label, 7)
				GameEvent.PSR:
					if not bool(d.get("ok", true)):
						summary["psr_failures"] += 1
						_unit(rows, id, labels)["psr_failures"] += 1
						_moment(moments, fact, "Piloting failure", label, 6)
				GameEvent.HEAT:
					var heat := int(d.get("heat", 0))
					var u := _unit(rows, id, labels)
					u["heat_peak"] = maxi(int(u["heat_peak"]), heat)
					if heat >= 14:
						_moment(moments, fact, "Dangerous heat", label, 5)
				GameEvent.CRITICAL:
					_unit(rows, id, labels)["criticals_taken"] += 1
	moments.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["score"]) > int(b["score"]))
	var units: Array = rows.values()
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["side"]) != int(b["side"]):
				return int(a["side"]) < int(b["side"])
			return int(a["id"]) < int(b["id"]))
	return {"summary": summary, "units": units, "timeline": timeline,
			"moments": moments, "frames": frames.size()}


static func _unit(rows: Dictionary, id: int, labels: Dictionary) -> Dictionary:
	var k := str(id)
	if not rows.has(k):
		var meta: Dictionary = labels.get(k, {})
		rows[k] = {"id": id, "name": String(meta.get("name", "Unit #%d" % id)),
				"side": int(meta.get("side", -1)), "attacks": 0, "hits": 0,
				"expected_hits": 0.0, "damage_dealt": 0, "damage_taken": 0,
				"kills": 0, "heat_peak": 0, "psr_failures": 0,
				"criticals_taken": 0, "destroyed": false}
	return rows[k]


static func _moment(moments: Array, fact: Dictionary, title: String,
		detail: String, score: int) -> void:
	moments.append({"title": title, "detail": detail, "frame": fact["frame"],
			"turn": fact["turn"], "score": score})


## The replay codec packs arbitrary event payload dictionaries as pairs.
## For measurements we only need scalar facts, never rebuild rule objects.
static func _scalar_data(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	if String(raw.get("$", "")) != "dictionary":
		return raw
	var result := {}
	for pair: Array in raw.get("items", []):
		if pair.size() == 2 and pair[0] is String and typeof(pair[1]) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING]:
			result[pair[0]] = pair[1]
	return result
