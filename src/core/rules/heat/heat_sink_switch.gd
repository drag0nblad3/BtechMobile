class_name HeatSinkSwitch
extends RefCounted
## Switching heat sinks off and on (book p. 103): in the End Phase a 'Mech
## may deactivate any number of its heat sinks, or turn them back on, even
## while shut down. Since the Heat Phase comes first, the change counts from
## next turn. Switched-off sinks shed no heat. Mostly for running hot enough
## to wake triple-strength myomer (Tsm).
## TODO(rules): the request is made any time and carried out in the End
## Phase; switched-off sinks are taken from the leg ones last for water.


## Why `u` can't ask for `n` sinks off ("" = it can).
static func problem(u: Unit, n: int) -> String:
	if u.destroyed:
		return "destroyed"
	if n < 0 or n > u.def.heat_sinks:
		return "it has %d heat sinks" % u.def.heat_sinks
	return ""


## End Phase: carries out a pending request.
static func apply(emit: Callable, u: Unit) -> void:
	if u.sinks_off_request < 0:
		return
	var n := u.sinks_off_request
	u.sinks_off_request = -1
	if n == u.sinks_off:
		return
	u.sinks_off = n
	emit.call(GameEvent.HEAT_SINKS_SWITCHED, {"unit_id": u.id, "off": n})


## The number of sinks off from next turn (pending request or current).
static func planned(u: Unit) -> int:
	return u.sinks_off_request if u.sinks_off_request >= 0 else u.sinks_off
