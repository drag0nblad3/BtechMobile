class_name PlateInfo
extends RefCounted
## What a nameplate over a 'Mech shows, seen from the selected 'Mech: its
## name, how much armor and structure it has left, and for an enemy the best
## to-hit number the viewer has against it right now.


## Units whose plates show: the viewer itself and every other active unit it
## has line of sight to.
static func visible_from(state: GameState, viewer: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	if viewer == null:
		return out
	for u in state.units:
		if u.destroyed or state.mission.exited.has(u.id):
			continue
		if u == viewer or not LineOfSight.check(state.map, viewer, u)["blocked"]:
			out.append(u)
	return out


## Armor + internal structure left, 0..1.
static func health(u: Unit) -> float:
	if u.asset != null:  # an Asset wears down through Degradation; 2 or less is the last check
		return clampf((u.asset.check - 2) / maxf(1.0, u.asset.card.check - 2.0), 0.0, 1.0)
	var full := 0.0
	var now := 0.0
	if u.ba != null:  # each trooper: its armor plus one for the trooper
		for a: int in u.ba.troopers:
			full += u.def.battle_armor.armor + 1
			now += 0 if a == BaState.DEAD else a + 1
		return clampf(now / maxf(1.0, full), 0.0, 1.0)
	if u.vehicle != null:  # armor and structure in the armored locations
		for loc: int in VehicleLoc.ARMORED:
			if loc != VehicleLoc.TURRET or u.def.vehicle.turret:
				full += u.def.armor[loc] + VehicleLoc.structure(u.def.tonnage)
				now += u.armor[loc] + u.structure[loc]
		return clampf(now / maxf(1.0, full), 0.0, 1.0)
	for loc in Location.COUNT:
		full += u.def.armor[loc] + u.def.rear_armor[loc] + StructureTable.points(u.def.tonnage, loc, u.def.quad)
		now += u.armor[loc] + u.rear_armor[loc] + u.structure[loc]
	return clampf(now / maxf(1.0, full), 0.0, 1.0)


## {best: lowest possible to-hit or 0, weapons: how many can fire at it,
##  text: "Hit 7+ · 3 weapons" or why not}. Empty text for a friendly unit.
static func attack(state: GameState, viewer: Unit, target: Unit) -> Dictionary:
	var out := {"best": 0, "weapons": 0, "text": ""}
	if viewer == null or target.side == viewer.side:
		return out
	for o in FireOptions.for_target(state, viewer, target):
		var th: ToHit = o["to_hit"]
		if th.possible() and viewer.can_fire(o["weapon"]):
			out["weapons"] += 1
			if out["best"] == 0 or th.target() < out["best"]:
				out["best"] = th.target()
	if out["weapons"] == 0:
		out["text"] = "Out of reach"
	else:
		out["text"] = "Hit %d+ · %d weapon%s" % [out["best"], out["weapons"], "" if out["weapons"] == 1 else "s"]
	return out


## Health as a 10-segment bar, e.g. "■■■■■■■□□□ 72%".
static func bar(fraction: float) -> String:
	var n := clampi(roundi(fraction * 10.0), 0, 10)
	return "■".repeat(n) + "□".repeat(10 - n) + " %d%%" % roundi(fraction * 100.0)


## Extra status words: prone, shut down.
static func status(u: Unit) -> String:
	var bits: Array[String] = []
	if u.prone:
		bits.append("prone")
	if u.shutdown:
		bits.append("shut down")
	return ", ".join(bits)
