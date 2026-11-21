class_name RotaryAc
extends RefCounted
## Rotary autocannons (book p. 183): fire 1 to 6 shots as one attack
## (heat and ammo per shot, the cluster column = shots fired). Firing more
## than one shot may jam it: the attack roll jams it on 2 (2-3 shots), 3 or
## less (4-5) or 4 or less (6), even if the attack hits. A jammed RAC can't
## fire until cleared: a Gunnery roll +3 at the end of the weapon phase,
## only if the 'Mech stood still or walked this turn.
## TODO(rules): the book declares unjamming in the Movement Phase; here it
## is chosen with the weapon's mode in the weapon phase.

const MODES: Array[String] = ["", "x2", "x3", "x4", "x5", "x6"]
const UNJAM := "unjam"
const UNJAM_MOD := 3


## Shots a mode fires.
static func shots(mode: String) -> int:
	return int(mode.substr(1)) if mode.begins_with("x") else 1


## Highest attack roll that jams it when firing `n` shots (0 = can't jam).
static func jams_on(n: int) -> int:
	if n >= 6:
		return 4
	if n >= 4:
		return 3
	return 2 if n >= 2 else 0


static func modes(w: MountedWeapon) -> Array[String]:
	if w.jammed:
		return ["", UNJAM] as Array[String]
	return MODES


## Marks the weapon jammed if this attack roll jams it; true if it did.
static func check_jam(w: MountedWeapon, n: int, roll: int) -> bool:
	if not w.def.rotary or roll > jams_on(n):
		return false
	w.jammed = true
	w.mode = ""
	return true


## Why this 'Mech can't try to clear a jam this turn ("" = it can).
static func unjam_problem(u: Unit) -> String:
	if u.move_mode == MoveMode.Kind.RUN or u.move_mode == MoveMode.Kind.JUMP:
		return "only a 'Mech that stood still or walked can clear a jam"
	return ""


## End of the weapon phase: one clearing roll per RAC set to unjam.
static func resolve_unjams(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		if u.destroyed:
			continue
		for w in u.weapons:
			if not (w.jammed and w.mode == UNJAM):
				continue
			w.mode = ""
			var data := {"unit_id": u.id, "weapon": w.def.name, "roll": 0, "need": 0, "ok": false}
			var why := unjam_problem(u)
			if why != "" or u.shutdown or not u.pilot.conscious:
				data["why"] = why if why != "" else "the MechWarrior can't work on it"
			else:
				data["need"] = u.pilot.gunnery + UNJAM_MOD
				data["roll"] = dice.roll_2d6()
				data["ok"] = data["roll"] >= data["need"]
				w.jammed = not data["ok"]
			emit.call(GameEvent.UNJAM, data)
