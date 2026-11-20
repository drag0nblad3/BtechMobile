class_name BotCharge
extends RefCounted
## Bot charges and death from above. While BotMove tries an end position,
## this checks for an enemy straight ahead it could charge (walk/run) or
## jump on (jump) and values it: expected damage plus a bonus for the
## piloting roll the target must make, minus part of the damage it takes
## itself, minus the fall a missed death from above causes. Charging means
## no weapon fire, so BotMove uses it only when it beats shooting.

const PSR_BONUS := 3.0      ## Value of forcing the target to roll or fall.
const SELF_WEIGHT := 0.6    ## Damage taken by our own 'Mech counts a little less.
const DFA_MISS_LEVELS := 2  ## A missed death from above falls 2 levels.


## `u` is already placed at the end hex (coord, facing, move_mode, hexes_moved).
## Returns {} or {target_id, value, reason}.
static func evaluate(state: GameState, u: Unit, mp_left: int) -> Dictionary:
	if u.move_mode < 0:
		return {}
	var e := state.unit_at(Hex.neighbor(u.coord, u.facing))
	if e == null or e.side == u.side or e.destroyed:
		return {}
	if not Charge.has_mp(state, u.coord, e.coord, u.move_mode, mp_left):
		return {}
	var dfa := u.move_mode == MoveMode.Kind.JUMP
	var kind := "dfa" if dfa else "charge"
	u.hexes_moved += 1  # the move into the target's hex counts for charge damage
	var opt := Charge.option(state, u, e, kind)
	u.hexes_moved -= 1
	var th: ToHit = opt["to_hit"]
	if not th.possible():
		return {}
	var p := th.chance()
	var v: float = p * (opt["damage"] + PSR_BONUS) - SELF_WEIGHT * p * opt["self_damage"]
	if dfa:
		v -= (1.0 - p) * Fall.damage_for(u, DFA_MISS_LEVELS)
	var reason := "%s %s (%s to hit, %d damage, %d back to itself)" % [
			"jumps on" if dfa else "charges", Names.unit(e), Names.pct(p), opt["damage"], opt["self_damage"]]
	return {"target_id": e.id, "value": v, "reason": reason}
