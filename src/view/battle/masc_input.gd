class_name MascInput
extends RefCounted
## The movement bar's MASC button: its label and what tapping it does.


## Button text, or "" to hide it.
static func label(u: Unit) -> String:
	if u == null or u.def.masc_loc < 0 or u.has_moved:
		return ""
	if u.masc_active:
		return "MASC on"
	if u.masc_failed:
		return "MASC failed"
	return "MASC (%d+)" % Masc.need(u) if Masc.problem(u) == "" else ""


## Engages MASC for `u`; returns a tip for the result.
static func engage(controller: GameController, u: Unit) -> String:
	if Masc.problem(u) != "":
		return "Can't engage MASC: %s." % Masc.problem(u)
	if controller.engage_masc(u):
		return "MASC works: run at up to %d MP this turn." % u.run_mp()
	return "MASC failed: normal speed, and one leg takes a critical check after the move."
