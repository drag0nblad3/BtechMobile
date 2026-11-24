class_name RulesDrill
extends RefCounted
## Rules drills: quick multiple-choice questions whose answers come from the
## real rules code (ToHitCalc, HitTable, ClusterTable, HeatScale, 2d6 odds),
## so a drill can never teach a number the game doesn't use. Each question:
## {kind, prompt, choices: Array[String], answer: index, explain}.

const KINDS := ["to_hit", "location", "cluster", "heat", "odds"]
const ATTACKER := "hunchback_hbk4g"
const WEAPON := "medium_laser"
const RACKS := [2, 4, 5, 6, 10, 15, 20]
const ARC_NAMES := {FiringArc.FRONT: "front", FiringArc.LEFT: "left side", FiringArc.RIGHT: "right side", FiringArc.REAR: "rear"}


## A question of `kind` (one of KINDS, "" = any), drawn from rng.
static func make(rng: RandomNumberGenerator, db: UnitDb, terrain: TerrainDb, kind: String = "") -> Dictionary:
	if kind == "":
		kind = KINDS[rng.randi_range(0, KINDS.size() - 1)]
	match kind:
		"to_hit":
			return _to_hit(rng, db, terrain)
		"location":
			return _location(rng)
		"cluster":
			return _cluster(rng)
		"heat":
			return _heat(rng)
	return _odds(rng)


static func _to_hit(rng: RandomNumberGenerator, db: UnitDb, terrain: TerrainDb) -> Dictionary:
	for _try in 20:
		var dist := rng.randi_range(1, 9)
		var cover: String = ["c", "c", "L", "H"][rng.randi_range(0, 3)]
		var row: Array[String] = []
		for c in 12:
			row.append((cover if c == dist else "c") + "0")
		var state := GameState.new(MapLoader.from_dict({"rows": [" ".join(row)]}, terrain))
		var def := db.get_def(ATTACKER)
		var a := Unit.new(1, def, 0, Hex.from_offset(Vector2i(0, 0)), 0)
		var t := Unit.new(2, def, 1, Hex.from_offset(Vector2i(dist, 0)), 0)
		for f in 6:
			if FiringArc.fire_arc(a.coord, f, t.coord) == FiringArc.FRONT:
				a.facing = f
				break
		a.pilot.gunnery = rng.randi_range(3, 5)
		a.move_mode = rng.randi_range(-1, MoveMode.Kind.JUMP)
		a.hexes_moved = 0 if a.move_mode < 0 else 3
		t.move_mode = rng.randi_range(-1, MoveMode.Kind.RUN)
		t.hexes_moved = 0 if t.move_mode < 0 else rng.randi_range(1, 7)
		state.add_unit(a)
		state.add_unit(t)
		var w: MountedWeapon = null
		for m in a.weapons:
			if m.def.id == WEAPON:
				w = m
				break
		var th := ToHitCalc.weapon(state, a, w, t)
		if not th.possible():
			continue
		var moved := "stood still" if a.move_mode < 0 else "%s 3 hexes" % MoveMode.VERBS[a.move_mode]
		var enemy := "stood still" if t.move_mode < 0 else "%s %d hexes" % [MoveMode.VERBS[t.move_mode], t.hexes_moved]
		var where := "" if cover == "c" else " and stands in %s" % state.map.get_tile(t.coord).terrain.name.to_lower()
		var q := "Your Hunchback (Gunnery %d) %s, then fires a Medium Laser at an enemy %d hexes away that %s%s. What do you need on 2d6?" % [
				a.pilot.gunnery, moved, dist, enemy, where]
		return _numbers("to_hit", q, th.target(), 2, 12, rng,
				"%s. Chance to hit: %s." % [th.summary(), Names.pct(th.chance())])
	return _odds(rng)


static func _location(rng: RandomNumberGenerator) -> Dictionary:
	var arc: int = [FiringArc.FRONT, FiringArc.LEFT, FiringArc.RIGHT, FiringArc.REAR][rng.randi_range(0, 3)]
	var roll := rng.randi_range(2, 12)
	var table: Array = HitTable.LEFT if arc == FiringArc.LEFT else HitTable.RIGHT if arc == FiringArc.RIGHT else HitTable.FRONT
	var loc: int = table[roll - 2]
	var right := Location.name_of(loc)
	var names: Array[String] = [right]
	for l in [Location.HEAD, Location.CT, Location.LT, Location.RT, Location.LA, Location.RA, Location.LL, Location.RL]:
		if not names.has(Location.name_of(l)):
			names.append(Location.name_of(l))
	var pool := names.slice(1)
	_shuffle(pool, rng)
	var choices: Array[String] = [right]
	choices.append_array(pool.slice(0, 3))
	_shuffle(choices, rng)
	var note := " Rear shots use the front column but strike the thin rear armor." if arc == FiringArc.REAR else ""
	note += " A 2 also checks for a critical hit through the armor." if roll == 2 else ""
	return {"kind": "location", "choices": choices, "answer": choices.find(right),
			"prompt": "A shot hits a 'Mech in its %s. The location roll is %d. Where does it hit?" % [ARC_NAMES[arc], roll],
			"explain": "The %s column of the hit location table puts a roll of %d in the %s.%s" % [
					"front/rear" if arc == FiringArc.FRONT or arc == FiringArc.REAR else ARC_NAMES[arc], roll, right.to_lower(), note]}


static func _cluster(rng: RandomNumberGenerator) -> Dictionary:
	var rack: int = RACKS[rng.randi_range(0, RACKS.size() - 1)]
	var roll := rng.randi_range(2, 12)
	var n := ClusterTable.hits(rack, roll)
	return _numbers("cluster", "A %d-missile rack hits. The cluster roll is %d. How many missiles strike?" % [rack, roll],
			n, 1, rack, rng, "The cluster table's %d column gives %d for a roll of %d. On average %.1f of %d land." % [
					rack, n, roll, ClusterTable.expected(rack), rack])


static func _heat(rng: RandomNumberGenerator) -> Dictionary:
	var part := rng.randi_range(0, 2)
	var heat := rng.randi_range(14, 29) if part == 2 else rng.randi_range(5, 29)
	if part == 2:
		var need := HeatScale.shutdown_avoid(heat)
		var opts: Array[String] = ["4", "6", "8", "10"]
		return {"kind": "heat", "choices": opts, "answer": opts.find(str(need)),
				"prompt": "A 'Mech ends the turn at heat %d. What must it roll on 2d6 to avoid shutting down?" % heat,
				"explain": "At heat %d: %s." % [heat, HeatScale.effects_text(heat)]}
	var answers := [HeatScale.mp_penalty(heat), HeatScale.to_hit_penalty(heat)]
	var asks := ["how many Walking MP does it lose?", "what is the penalty to its shots?"]
	return _numbers("heat", "A 'Mech's heat is %d: %s" % [heat, asks[part]], answers[part], 0, 5, rng,
			"At heat %d: %s." % [heat, HeatScale.effects_text(heat)])


static func _odds(rng: RandomNumberGenerator) -> Dictionary:
	var need := rng.randi_range(3, 12)
	var right := Names.pct(Dice.chance_2d6(need))
	var choices: Array[String] = [right]
	var others := range(2, 13).filter(func(n): return Names.pct(Dice.chance_2d6(n)) != right)
	_shuffle(others, rng)
	for n in others.slice(0, 3):
		choices.append(Names.pct(Dice.chance_2d6(n)))
	choices.sort_custom(func(x: String, y: String) -> bool: return int(x.trim_suffix("%")) > int(y.trim_suffix("%")))
	var ways := roundi(Dice.chance_2d6(need) * 36.0)
	return {"kind": "odds", "choices": choices, "answer": choices.find(right),
			"prompt": "What is the chance of rolling %d or more on 2d6?" % need,
			"explain": "%d of the 36 ways two dice can land make %d or more: %s. Each point of to-hit modifier matters most around 7." % [ways, need, right]}


## Four numeric choices around `right` within lo..hi.
static func _numbers(kind: String, prompt: String, right: int, lo: int, hi: int,
		rng: RandomNumberGenerator, explain: String) -> Dictionary:
	var pool := []
	for d in [-3, -2, -1, 1, 2, 3]:
		if right + d >= lo and right + d <= hi:
			pool.append(right + d)
	_shuffle(pool, rng)
	var nums := [right] + pool.slice(0, 3)
	nums.sort()
	var choices: Array[String] = []
	for n in nums:
		choices.append(str(n))
	return {"kind": kind, "prompt": prompt, "choices": choices, "answer": nums.find(right), "explain": explain}


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = a[i]
		a[i] = a[j]
		a[j] = tmp
