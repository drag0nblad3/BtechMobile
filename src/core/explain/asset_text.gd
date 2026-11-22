class_name AssetText
extends RefCounted
## Log text for Battlefield Support Assets (vehicles, infantry): damage on
## the card and End Phase Destroy Checks. Our own wording.


static func moved(s: GameState, d: Dictionary, level: int) -> String:
	var u := s.unit_by_id(d["unit_id"])
	var hexes: int = d["hexes"]
	var t := "%s %s." % [Names.unit(u), "stays put" if d["mode"] < 0 else "%s %d hex%s (%d MP)" % [
			"backs up" if d["mode"] == MoveMode.Kind.WALK else ("jumps" if d["mode"] == MoveMode.Kind.JUMP else "moves"),
			hexes, "" if hexes == 1 else "es", d["mp"]]]
	if level == ExplainLevel.FULL and u.asset != null:
		t += " Assets keep the same defence (TMM %+d) moving or not, and their aim never suffers from moving." % u.asset.card.tmm
	return t


static func transport(s: GameState, d: Dictionary, level: int) -> String:
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	var ride := Names.unit(s.unit_by_id(d["carrier_id"]))
	var squad := s.unit_by_id(d["unit_id"]).ba != null
	match String(d["kind"]):
		"swarm":
			return "%s swarms all over %s!" % [who, ride] + (" From now on its weapons hit that 'Mech automatically, all over its body, until it is brushed off or the 'Mech falls." if level == ExplainLevel.FULL else "")
		"swarm_off":
			return "%s drops off the wreck of %s." % [who, ride]
		"brushed":
			return "%s swats %s off its hull." % [ride, who]
		"board" when squad:
			return "%s climbs onto %s." % [who, ride] + (" Troopers riding a 'Mech's torso take hits aimed at their spots, and are set down if it is destroyed." if level == ExplainLevel.FULL else "")
		"deploy" when squad:
			return "%s climbs down from %s." % [who, ride] + (" It can't attack the turn it gets off." if level == ExplainLevel.FULL else "")
		"board":
			return "%s climbs aboard %s." % [who, ride] + (" Riders can't be shot, but die if their transport is destroyed." if level == ExplainLevel.FULL else "")
		"deploy":
			return "%s gets out of %s." % [who, ride] + (" Troops can't fire the turn they get out, and are easy to hit (TMM 0) until next turn." if level == ExplainLevel.FULL else "")
	return "%s jumps clear as %s goes down." % [who, ride]


static func damage(s: GameState, d: Dictionary, level: int) -> String:
	var u := s.unit_by_id(d["unit_id"])
	var t := "  %s takes %d (%d this turn)" % [Names.unit(u), d["amount"], d["turn_total"]]
	if d.get("rear", false):
		t += ", doubled from behind"
	if level == ExplainLevel.FULL and u.asset != null:
		var c := u.asset.card
		if int(d["raw"]) != int(d["amount"]) and not d.get("rear", false):
			t += " (its armor or type changed the %d it was dealt)" % d["raw"]
		t += ". Assets have no hit locations: once a turn's damage reaches %d, a Destroy Check is rolled in the End Phase." % c.threshold
	return t


static func destroy_check(s: GameState, d: Dictionary, level: int) -> String:
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	var roll := "%d" % d["roll"] + (" +%d" % d["bonus"] if d["bonus"] > 0 else "")
	if d["destroyed"]:
		var t := "Destroy Check on %s: %s vs %d+: destroyed!" % [who, roll, d["need"]]
		if d["auto"]:
			t = "Destroy Check on %s: it was worn down to 2 or less, so it fails automatically: destroyed!" % who
		return t
	var t := "Destroy Check on %s: %s vs %d+: it survives, Check drops to %d." % [who, roll, d["need"], d["check"]]
	if level == ExplainLevel.FULL:
		t += " Damage is wiped each turn, but every survived check wears the Asset down"
		t += " (by 2: anti-infantry weapons and fire tear through troops)." if d["degraded"] == 2 else "."
		if d["bonus"] > 0:
			t += " The %d damage added +%d to the roll: every 10 points past 10 helps." % [d["damage"], d["bonus"]]
	return t
