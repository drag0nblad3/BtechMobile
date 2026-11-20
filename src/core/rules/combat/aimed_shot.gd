class_name AimedShot
extends RefCounted
## Aimed shots (p. 70): against an immobile target, a shot may aim at one
## location. The -4 immobile modifier stays, except at the head: no -4 and
## +3 instead. On a hit, 1D6 4+ strikes the chosen location; otherwise the
## hit location is rolled as usual. Not for indirect fire, double-firing
## Ultras, or cluster weapons (missiles, LB-X cluster rounds). Partial
## cover: legs can't be chosen, the cover modifier is dropped, and rolled
## leg hits are rerolled.

const HEAD_MOD := 3
const NEEDS := 4


## Why `w` can't aim at `loc` on `target` ("" = it can).
static func problem(_state: GameState, w: MountedWeapon, target: Unit, loc: int, th: ToHit) -> String:
	if not ToHitCalc.is_immobile(target):
		return "only an immobile target (shut down, pilot out, or legless) can be aimed at"
	if loc < 0 or loc >= Location.COUNT or target.is_location_destroyed(loc):
		return "that location is gone"
	if th.spotter_id >= 0:
		return "indirect fire can't aim"
	if w.def.is_cluster() or WeaponModes.ammo_kind(w) == WeaponModes.CLUSTER:
		return "cluster weapons can't aim"
	if WeaponModes.shots(w) > 1:
		return "an Ultra firing twice can't aim"
	if th.legs_only:
		return "under water only the legs can be hit"
	if Location.is_leg(loc) and _covered(th):
		return "the legs are behind cover"
	return ""


## Turns a normal to-hit number into the aimed one.
static func adjust(th: ToHit, loc: int) -> void:
	th.aim_loc = loc
	th.aim_covered = _covered(th)
	_drop(th, "partial cover")
	th.cover_hex = Hex.INVALID
	if loc == Location.HEAD:
		_drop(th, "target immobile")
		th.add("aimed at the head", HEAD_MOD, "Picking out the cockpit is hard: no -4 for an immobile target, +3 instead.")
	else:
		th.add("aimed at the %s" % Location.name_of(loc).to_lower(), 0,
				"Aiming doesn't change the number; a hit rolls 1D6, and 4+ lands where you aimed.")


## Hit location for an aimed hit: {loc, rear, tac, roll, aim_roll, aimed}.
static func location(dice: Dice, th: ToHit, arc_id: int) -> Dictionary:
	var covered := th.aim_covered
	var r := dice.d6()
	if r >= NEEDS:
		return {"loc": th.aim_loc, "rear": arc_id == FiringArc.REAR, "tac": false, "roll": 0,
				"aim_roll": r, "aimed": true, "no_cover": true}
	var hl := HitTable.roll(dice, arc_id)
	while covered and Location.is_leg(hl["loc"]):
		hl = HitTable.roll(dice, arc_id)
	hl["aim_roll"] = r
	hl["aimed"] = false
	hl["no_cover"] = covered
	return hl


static func _covered(th: ToHit) -> bool:
	for m in th.mods:
		if m["label"] == "partial cover":
			return true
	return false


static func _drop(th: ToHit, label: String) -> void:
	for i in range(th.mods.size() - 1, -1, -1):
		if th.mods[i]["label"] == label:
			th.mods.remove_at(i)
