class_name HiddenText
extends RefCounted
## Log text for hidden units: coming out of hiding and point-blank ambushes.


static func describe(e: GameEvent, s: GameState, level: int) -> String:
	var d := e.data
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	match e.type:
		GameEvent.UNIT_REVEALED:
			var t := "%s was hiding at %s and is revealed: %s." % [who, Hex.label(s.unit_by_id(d["unit_id"]).coord), d["why"]]
			if level == ExplainLevel.FULL:
				if d["by_enemy"]:
					t += " Caught by surprise, it can't move this phase and gets no movement modifier this turn, but it may fire point-blank at the 'Mech that found it."
				else:
					t += " A hidden unit must show itself at the start of the phase in which it wants to move or shoot."
			return t
		GameEvent.POINT_BLANK:
			var target := Names.unit(s.unit_by_id(d["target_id"]))
			if not d["fired"]:
				return "%s lets %s pass without a point-blank shot." % [who, target] if level != ExplainLevel.OFF else ""
			var t := "%s ambushes %s point-blank!" % [who, target]
			if level == ExplainLevel.FULL:
				t += " Every weapon fires as if from 1 hex and ignores how far the target moved; the price is the ambusher's whole turn."
			return t
	return ""
