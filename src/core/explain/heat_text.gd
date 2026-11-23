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
			if d.get("inferno", false):
				return "%s's inferno ammo cooks off: heat %d -> %d, at once." % [who, d["before"], d["heat"]]
			var t := "%s heat %d -> %d" % [who, d["before"], d["heat"]]
			if level != ExplainLevel.OFF:
				var outside: int = d.get("outside", 0)
				var from_out := (", %d of it from fire and flamers" % outside) if outside > 0 else ""
				if d.get("stealth", 0) > 0:
					from_out += ", %d from stealth armor" % d["stealth"]
				t += " (+%d built%s, -%d sinks%s)" % [d["gained"], from_out, d["sinks"],
						ConditionsText.heat_note(d.get("weather", 0))]
			if d["heat"] > 0:
				t += ": " + d["effects"]
			if level == ExplainLevel.FULL and d["gained"] > d["sinks"] and d["heat"] >= 5:
				t += ". It built more heat than its sinks remove; holding a weapon or walking instead of running would help"
			return t + "."
		GameEvent.HEAT_ROLL:
			var what: String = {"ammo": "avoid an ammo explosion", "shutdown": "avoid shutting down",
					"restart": "restart", "inferno": "keep its inferno ammo from exploding"}[d["kind"]]
			if level == ExplainLevel.OFF:
				return "" if d["ok"] or d["kind"] == "restart" else "%s fails to %s." % [who, what]
			if d["need"] >= 99:
				return "%s can't %s at this heat in these temperatures." % [who, what]
			return "%s rolls to %s: %d vs %d+: %s." % [who, what, d["roll"], d["need"],
					"made it" if d["ok"] else "failed"]
		GameEvent.HEAT_SINKS_SWITCHED:
			var u := s.unit_by_id(d["unit_id"])
			var h := "%s now has %d heat sink%s switched off." % [who, d["off"], "" if d["off"] == 1 else "s"] if d["off"] > 0 \
					else "%s switches all its heat sinks back on." % who
			if level == ExplainLevel.FULL and d["off"] > 0:
				h += " They shed no heat from next turn" + (", so it can run hot enough (heat %d+) to wake its triple-strength myomer." % Tsm.HEAT if Tsm.has(u.def) else ".")
			return h
		GameEvent.STEALTH:
			var st := "%s switches its stealth armor %s." % [who, "on" if d["on"] else "off"]
			if level == ExplainLevel.FULL:
				st += (" Shots from medium and long range get harder, but it builds 10 heat a turn and its ECM and C3 stop working."
						if d["on"] else " No more 10 heat a turn, and its ECM works again, but it is easier to hit from range.")
			return st
		GameEvent.SHUTDOWN:
			if d.get("voluntary", false):
				if not d["shutdown"]:
					return "%s powers back up." % who
				var v := "%s shuts down on purpose." % who
				if level == ExplainLevel.FULL:
					v += " It sheds heat but can't move or fire, is easy to hit (-4) and open to aimed shots, and stays down until you restart it in a later Heat Phase."
				return v
			if d["shutdown"]:
				var t := "%s SHUTS DOWN." % who
				if level == ExplainLevel.FULL:
					t += " A shut-down 'Mech can't move or fire, fails any piloting roll and is easy to hit (-4). It restarts by itself below 14 heat."
				return t
			return "%s restarts." % who
	return ""
