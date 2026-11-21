class_name HiddenText
extends RefCounted
## Log text for units that start off the field: hidden units coming out,
## point-blank ambushes, and combat drops.


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
		GameEvent.COMBAT_DROP:
			var t := "%s combat drops toward %s" % [who, Hex.label(d["aim"])]
			if d["margin"] == 0:
				t += " and lands on target."
			elif d.get("off_map", false):
				t += ", misses by %d and scatters off the battlefield!" % d["margin"]
			else:
				t += ", misses by %d and scatters to %s." % [d["margin"], Hex.label(d["hex"])]
			if level == ExplainLevel.FULL:
				t += " A dropping 'Mech rolls piloting to land: failing scatters it 1-3 hexes per point missed and it falls that many levels; missing by 4 or more is fatal. It can't act the turn it lands, and shots at it get +3."
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
