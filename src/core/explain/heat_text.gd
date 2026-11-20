class_name HeatText
extends RefCounted
## Log text for the Heat Phase.


static func describe(e: GameEvent, s: GameState, level: int) -> String:
	var d := e.data
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	match e.type:
		GameEvent.HEAT:
			if d["before"] == d["heat"] and d["heat"] == 0 and level != ExplainLevel.FULL:
				return ""
			var t := "%s heat %d -> %d" % [who, d["before"], d["heat"]]
			if level != ExplainLevel.OFF:
				var outside: int = d.get("outside", 0)
				var from_out := (", %d of it from enemy flamers" % outside) if outside > 0 else ""
				t += " (+%d built%s, -%d sinks)" % [d["gained"], from_out, d["sinks"]]
			if d["heat"] > 0:
				t += ": " + d["effects"]
			if level == ExplainLevel.FULL and d["gained"] > d["sinks"] and d["heat"] >= 5:
				t += ". It built more heat than its sinks remove; holding a weapon or walking instead of running would help"
			return t + "."
		GameEvent.HEAT_ROLL:
			var what: String = {"ammo": "avoid an ammo explosion", "shutdown": "avoid shutting down",
					"restart": "restart"}[d["kind"]]
			if level == ExplainLevel.OFF:
				return "" if d["ok"] or d["kind"] == "restart" else "%s fails to %s." % [who, what]
			return "%s rolls to %s: %d vs %d+: %s." % [who, what, d["roll"], d["need"],
					"made it" if d["ok"] else "failed"]
		GameEvent.SHUTDOWN:
			if d["shutdown"]:
				var t := "%s SHUTS DOWN and falls." % who
				if level == ExplainLevel.FULL:
					t += " A shut-down 'Mech can't move or fire and is easy to hit (-4)."
				return t
			return "%s restarts." % who
	return ""
