class_name BattleScarHistory
extends RefCounted
## Replays cosmetic marks from the existing packed GameEvent ledger.
## Reads snapshot coordinates directly; no rule reconstruction or rolls.

static func recover(frames: Array) -> Dictionary:
	var fires: Dictionary = {}
	var deaths: Dictionary = {}
	for frame: Dictionary in frames:
		for fact: Dictionary in frame.get("events", []):
			var data: Dictionary = BattleCodec.unpack(fact.get("data", {}), null, null)
			var turn := int(fact.get("turn", frame.get("turn", 0)))
			match String(fact.get("event", "")):
				"building":
					if data.get("kind", "") in ["fire", "inferno", "collapsed", "flattened"]:
						if data.get("coord") is Vector2i:
							fires[data["coord"]] = turn
				"damage":
					if int(data.get("amount", 0)) >= 15:
						var unit_id := int(data.get("unit_id", -1))
						var coord := _frame_coord(frame, unit_id)
						if coord != Hex.INVALID:
							fires[coord] = turn
				"unit_destroyed":
					deaths[int(data.get("unit_id", -1))] = turn
	return {"scorches": fires, "deaths": deaths}


static func _frame_coord(frame: Dictionary, unit_id: int) -> Vector2i:
	var packed: Dictionary = frame.get("state", {})
	var units: Dictionary = packed.get("properties", {}).get("units", {})
	for entry: Dictionary in units.get("items", []):
		var p: Dictionary = entry.get("properties", {})
		if int(p.get("id", -1)) != unit_id:
			continue
		var c: Dictionary = p.get("coord", {})
		if c.get("$", "") == "v2i":
			return Vector2i(int(c["x"]), int(c["y"]))
	return Hex.INVALID
