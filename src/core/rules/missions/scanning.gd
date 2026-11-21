class_name Scanning
extends RefCounted
## Scanning (book p. 233). In the End Phase each 'Mech may scan one target
## within 2 hexes that it can see: a sensor check (piloting, +2 for a sensor
## hit) at +3. What a scan is worth depends on the mission (`Mission.scan`):
## "units" (Sensor Check: enemy 'Mechs, counted per scanning 'Mech) or
## "intel" (Urban Sweep: objective counters in buildings; a scan that finds
## intel on 4+ scores 2 VP, once per side and counter).
## TODO(rules): the scan target is picked automatically (the most useful
## one in range); active probes and stealth armor aren't in the game.

const RANGE := 2
const MOD := 3
const INTEL_ROLL := 4
const INTEL_VP := 2


## Scan target number for `u`.
static func target_number(u: Unit) -> ToHit:
	var th := LowVisibility.sensor_check_target(u)
	if th.possible():
		th.add("scanning", MOD, "Picking out details at range is harder than a quick sensor sweep: +3.")
	return th


## What `u` would scan now: {unit: Unit} or {objective: Objective}, or {}.
static func pick(state: GameState, u: Unit) -> Dictionary:
	var m := state.mission.def
	if m == null or m.scan == "" or u.destroyed or not u.can_act() or state.mission.exited.has(u.id):
		return {}
	if m.scan == "units":
		var best: Unit = null
		for e in state.units:
			if e.side != u.side and not e.destroyed and Hex.distance(u.coord, e.coord) <= RANGE \
					and not LineOfSight.check(state.map, u, e)["blocked"]:
				if best == null or Hex.distance(u.coord, e.coord) < Hex.distance(u.coord, best.coord):
					best = e
		return {"unit": best} if best else {}
	for o in m.objectives:
		if o.kind == "intel" and not o.claimed.has(u.side) and sees(state, u, o.coord):
			return {"objective": o}
	return {}


static func sees(state: GameState, u: Unit, c: Vector2i) -> bool:
	if Hex.distance(u.coord, c) > RANGE:
		return false
	if u.coord == c:
		return true
	var tile := state.map.get_tile(c)
	return not LineOfSight.check_hex(state.map, u, c, LineOfSight.los_level(state.map, u) if tile == null
			else tile.floor_level() + 1)["blocked"]


## End Phase: every 'Mech scans its best target.
static func end_phase(state: GameState, dice: Dice, emit: Callable) -> void:
	var m := state.mission.def
	if m == null or m.scan == "":
		return
	for u in state.units:
		var t := pick(state, u)
		if t.is_empty():
			continue
		var th := target_number(u)
		var roll := dice.roll_2d6()
		var ok := th.possible() and roll >= th.target()
		var data := {"unit_id": u.id, "roll": roll, "need": th.target(), "ok": ok, "mods": th.mods}
		if t.has("unit"):
			data["target_id"] = t["unit"].id
			if ok:
				state.mission.scans[u.id] = int(state.mission.scans.get(u.id, 0)) + 1
				data["count"] = state.mission.scans[u.id]
		else:
			var o: Objective = t["objective"]
			data["hex"] = o.coord
			if ok:
				data["intel_roll"] = dice.d6()
				if data["intel_roll"] >= INTEL_ROLL:
					o.claimed[u.side] = true
					o.found = true
					state.mission.add_vp(u.side, INTEL_VP)
					data["vp"] = INTEL_VP
					data["total"] = state.mission.vp[u.side]
		emit.call(GameEvent.SCAN, data)


## Start of a turn: counters whose intel was found, or whose building came
## down, leave play.
## TODO(rules): the side that brings a building down on a counter loses 2 VP.
static func start_turn(state: GameState) -> void:
	var m := state.mission.def
	if m == null or m.scan != "intel":
		return
	var keep: Array[Objective] = []
	for o in m.objectives:
		var tile := state.map.get_tile(o.coord)
		if not o.found and tile != null and tile.building != null:
			keep.append(o)
	m.objectives = keep
