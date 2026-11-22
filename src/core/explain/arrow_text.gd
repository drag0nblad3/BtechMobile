class_name ArrowText
extends RefCounted
## Log text for Arrow IV munitions: homing missiles and smoke (ArrowHoming, ArrowSmoke).


## What a standard or smoke missile does when it lands on target.
static func hit_text(d: Dictionary, level: int) -> String:
	if String(d.get("kind", "")) == ArrowSmoke.KIND:
		return "; smoke missile: heavy smoke fills the hex and the hexes around it" + (
				" once this phase's shots are done" if level == ExplainLevel.FULL else "")
	return "; %d to everything in the hex, %d to the hexes around it" % [ArrowIv.CENTER, ArrowIv.RING]


static func homing(who: String, d: Dictionary, level: int) -> String:
	if d.get("homing_lost", false):
		var t := "%s: the homing missile finds no TAG beam within %d hexes and is lost" % [who, ArrowHoming.REACH]
		if level == ExplainLevel.FULL:
			t += ". Homing Arrow IV needs a friendly TAG to designate a target that turn; without one it doesn't scatter, it just fails"
		return t + "."
	var t := "%s: homing missile, rolled %d (needs %d, no modifiers): %s" % [who, d["roll"], d["need"],
			"HIT for %d, plus %d to everything else in the hex" % [ArrowHoming.DAMAGE, ArrowHoming.SPLASH] if d["hit"]
			else "it misses the 'Mech but bursts in its hex for %d to everything there" % ArrowHoming.SPLASH]
	if level == ExplainLevel.FULL:
		t += ". It locked onto the TAG designation, so range, movement and terrain don't matter"
	return t + "."


## Smoke filling or thinning (BUILDING events "smoke" and "smoke_thins").
static func smoke(d: Dictionary, level: int) -> String:
	var n: int = (d.get("hexes", []) as Array).size()
	if d["kind"] == "smoke":
		var t := "  Heavy smoke billows over %d hexes around %s." % [n, Hex.label(d["coord"])]
		if level == ExplainLevel.FULL:
			t += " It blocks sight like heavy woods (+2 to hit a 'Mech in it), turns light at the end of next turn and clears a turn later."
		return t
	return "  The Arrow IV smoke thins in %d hex%s." % [n, "" if n == 1 else "es"] if level != ExplainLevel.OFF else ""
