class_name SpeedDemon
extends RefCounted
## Speed Demon SPA (Campaign Operations p. 80): +1 running MP. A 'Mech
## that spends it (runs further than its normal running MP) can make no
## weapon or physical attacks that turn.

const NO_ATTACK := "Speed Demon: it ran flat out this turn and can't attack"


## Extra MP for `mode` (running only).
static func bonus(u: Unit, mode: int) -> int:
	return 1 if mode == MoveMode.Kind.RUN and Spa.has(u, Spa.SPEED_DEMON) and u.asset == null \
			and u.vehicle == null and u.ba == null else 0


## After a run costing `mp` out of `budget` (bonus included): did it use the extra MP?
static func after_move(u: Unit, mode: int, mp: int, budget: int) -> void:
	if bonus(u, mode) > 0 and mp > budget - bonus(u, mode):
		u.flat_out = true
