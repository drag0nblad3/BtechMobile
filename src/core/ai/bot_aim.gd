class_name BotAim
extends RefCounted
## Bot aimed shots (AimedShot): for each planned shot that may aim, picks
## the location whose expected value beats an ordinary shot. A hit lands
## where aimed half the time (4+ on 1D6); a location the damage would
## destroy is worth much more, most of all the head, center torso or an XL
## side torso that would take the engine with it, which kill the 'Mech.
## Head hits also hurt the pilot. A Marksman who stood still trades the
## whole volley for one aimed shot when that shot is clearly worth more.

const KILL_VALUE := 40.0  ## Destroying the head, CT or an XL side torso.
const LIMB_VALUE := 12.0  ## Destroying any other location, on top of the damage.
const PILOT_VALUE := 6.0  ## A head hit injures the MechWarrior.
const EXPOSED_MULT := 1.5  ## No armor left: damage goes straight to structure and crits.
const MARGIN := 1.15  ## Aim only if clearly better than a plain shot.


## Adds "aim" to shots where aiming pays; returns a note for the bot's reason ("" if none).
static func choose(state: GameState, u: Unit, shots: Array) -> String:
	var marks := marksman(state, u, shots)
	if marks != "":
		return marks
	var notes: Array[String] = []
	for sh: Dictionary in shots:
		if not sh.has("target_id"):
			continue
		var e := state.unit_by_id(int(sh["target_id"]))
		if e == null or not (ToHitCalc.is_immobile(e) or TargetingComputer.working(u)):
			continue
		var w: MountedWeapon = u.weapons[int(sh["weapon"])]
		var loc := best_location(state, u, w, e)
		if loc >= 0:
			sh["aim"] = loc
			notes.append("%s at the %s" % [w.def.name, Location.name_of(loc).to_lower()])
	if notes.is_empty():
		return ""
	return "aims %s (%s)" % [", ".join(notes),
			"a sitting target" if ToHitCalc.is_immobile(state.unit_by_id(int(shots[0]["target_id"])))
			else "targeting computer"]


## The location worth aiming `w` at on `e`, or -1 for an ordinary shot.
static func best_location(state: GameState, u: Unit, w: MountedWeapon, e: Unit) -> int:
	var plain := ToHitCalc.weapon(state, u, w, e)
	if not plain.possible():
		return -1
	var dmg := WeaponModes.expected_per_hit(w)
	var best := plain.chance() * dmg * MARGIN
	var best_loc := -1
	for loc in Location.COUNT:
		var th := ToHitCalc.weapon(state, u, w, e)
		if AimedShot.problem(state, w, e, loc, th) != "":
			continue
		AimedShot.adjust(th, loc, w)
		if not th.possible():
			continue
		var v := th.chance() * (0.5 * location_value(e, loc, dmg) + 0.5 * dmg)
		if v > best:
			best = v
			best_loc = loc
	return best_loc


## Marksman: keeps one aimed shot instead of the volley when it pays.
static func marksman(state: GameState, u: Unit, shots: Array) -> String:
	if not Marksman.ready(u) or shots.is_empty():
		return ""
	var volley := 0.0
	var best := {}
	var best_v := 0.0
	for sh: Dictionary in shots:
		if not sh.has("target_id"):
			continue
		var e := state.unit_by_id(int(sh["target_id"]))
		var w: MountedWeapon = u.weapons[int(sh["weapon"])]
		var plain := ToHitCalc.weapon(state, u, w, e)
		var dmg := WeaponModes.expected_per_hit(w)
		volley += plain.chance() * dmg
		if ToHitCalc.is_immobile(e):
			continue
		for loc in Location.COUNT:
			var th := ToHitCalc.weapon(state, u, w, e)
			if not th.possible() or AimedShot.problem(state, w, e, loc, th, u) != "":
				continue
			AimedShot.adjust(th, loc, w, u)
			var v := th.chance() * (0.5 * location_value(e, loc, dmg) + 0.5 * dmg) if th.possible() else 0.0
			if v > best_v:
				best_v = v
				best = {"weapon": sh["weapon"], "target_id": sh["target_id"], "aim": loc}
	if best.is_empty() or best_v <= volley * MARGIN:
		return ""
	shots.clear()
	shots.append(best)
	return "Marksman: holds the rest and aims its %s at the %s" % [
			u.weapons[int(best["weapon"])].def.name, Location.name_of(int(best["aim"])).to_lower()]


## What `dmg` landing on `loc` is worth.
static func location_value(e: Unit, loc: int, dmg: float) -> float:
	if dmg >= e.armor[loc] + e.structure[loc]:
		var xl_side := XlEngine.torso_loss_kills(e) and (loc == Location.LT or loc == Location.RT)
		if loc == Location.HEAD or loc == Location.CT or xl_side:
			return KILL_VALUE
		return LIMB_VALUE + dmg
	var v := dmg + (PILOT_VALUE if loc == Location.HEAD else 0.0)
	return v * (EXPOSED_MULT if e.armor[loc] <= 0 else 1.0)
