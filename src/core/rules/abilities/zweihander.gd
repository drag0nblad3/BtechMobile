class_name Zweihander
extends RefCounted
## Zweihander (Campaign Operations p. 82): with working hands on both arms,
## a MechWarrior may punch, or swing a one-handed hatchet or sword, with
## both arms at a target in the front arc. Broken actuators in both arms
## count. A hit adds 1 damage per 10 full tons (2 with active TSM), then
## the attacker rolls for a critical hit on the weapon's arm (both arms if
## unarmed). A miss needs a Piloting roll, as for a missed kick.
## TODO(rules): the attacker's own critical hits take effect at once, not in
## the End Phase; improvised clubs aren't offered.

const KIND := "zweihander"
const BASES := ["punch", "hatchet", "sword"]


## Two-handed versions of the possible punches and swings in `base`.
static func options(state: GameState, a: Unit, t: Unit, base: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not Spa.has(a, Spa.ZWEIHANDER) or a.def.quad or problem(state, a, t) != "":
		return out
	for o in base:
		var kind := String(o["kind"])
		var th: ToHit = o["to_hit"]
		if not BASES.has(kind) or not th.possible() or (kind == "punch" and int(o["limb"]) != Location.LA):
			continue
		var other := Location.RA if int(o["limb"]) == Location.LA else Location.LA
		var two := ToHit.new()
		two.mods = th.mods.duplicate(true)
		var dmg := int(o["damage"])
		for act in ["upper_arm", "lower_arm"]:
			if not a.has_working_actuator(other, act):
				two.add("other arm: no " + act.replace("_", " "), 2, "Both arms swing: a broken actuator in the other arm counts too.")
				@warning_ignore("integer_division")
				dmg = dmg / 2
		var per := 2 if Tsm.active(a) else 1
		@warning_ignore("integer_division")
		dmg += a.def.tonnage / 10 * per
		out.append({"kind": KIND, "limb": -1 if kind == "punch" else int(o["limb"]), "weapon": kind,
				"to_hit": two, "damage": dmg, "table": o["table"], "label": "Two-handed " + kind})
	return out


## Why no two-handed attack is possible, or "".
static func problem(state: GameState, a: Unit, t: Unit) -> String:
	for arm in [Location.LA, Location.RA]:
		if a.is_location_out(arm) or not a.has_working_actuator(arm, "hand") \
				or not a.has_working_actuator(arm, "shoulder"):
			return "both arms need a working shoulder and hand"
		if PhysicalMods.limb_fired(a, arm) or a.carry_arm == arm:
			return "both arms must be free"
	if a.arms_flipped or FiringArc.fire_arc(a.coord, a.torso_facing(), t.coord) != FiringArc.FRONT:
		return "the target must be in front"
	return ""


## After a hit: the attacker's own critical hit check on the arm(s) used.
static func strain(state: GameState, dice: Dice, emit: Callable, a: Unit, d: Dictionary) -> void:
	var arms := [Location.LA, Location.RA] if int(d["limb"]) < 0 else [int(d["limb"])]
	for arm: int in arms:
		if not a.destroyed and not a.is_location_destroyed(arm):
			CriticalHits.roll_location(state, dice, emit, a, arm)
