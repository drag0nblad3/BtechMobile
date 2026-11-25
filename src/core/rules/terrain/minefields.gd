class_name Minefields
extends RefCounted
## Minefields (book pp. 156, 191, 193). Each field belongs to one side and
## has a density (Light, Medium, Heavy: 9+, 8+, 7+ to go off) and 5-point
## damage groups (2, 4, 6 new, never past 6). When a 'Mech or ground vehicle
## enters the hex, friend or foe, every field there rolls 2D6 with no
## modifiers; a jumper only sets them off by landing there. On a hit each
## group strikes the front column of the Kick table and the field loses one
## group (gone at 0); a miss leaves it in place. A field laid on a field of
## the same side adds its groups and density. Artillery striking the hex
## clears it: each side with mines there rolls 2D6, 5+ removes them all.
## Infantry, battle armor, hovercraft and VTOLs never set mines off. Laying
## mines in an occupied hex doesn't attack the units already there.
## TODO(rules): mines go off after the whole move (the 'Mech doesn't stop
## in the hex); displacement, combat drops and Assets don't trigger them;
## no pre-placed Minefield Strikes; mines are shown to both sides; missile
## attacks can't clear them.

const NEED := {1: 9, 2: 8, 3: 7}
const GROUPS := {1: 2, 2: 4, 3: 6}
const NAMES := {1: "Light", 2: "Medium", 3: "Heavy"}
const MAX_GROUPS := 6
const GROUP := 5
const CLEAR := 5


## Lays a field of `density` for `side` in `c`, merging with that side's field.
static func lay(state: GameState, emit: Callable, c: Vector2i, side: int, density: int) -> void:
	var t := state.map.get_tile(c)
	if t == null or t.is_water():
		return
	var f := _field(state, c, side)
	if f.is_empty():
		f = {"hex": c, "side": side, "density": 0, "groups": 0}
		state.minefields.append(f)
	f["density"] = mini(3, int(f["density"]) + density)
	f["groups"] = mini(MAX_GROUPS, int(f["groups"]) + int(GROUPS[density]))
	emit.call(GameEvent.MINEFIELD, {"kind": "laid", "coord": c, "side": side, "density": f["density"], "groups": f["groups"]})


static func sets_off(u: Unit) -> bool:
	return not u.destroyed and u.ba == null and u.asset == null and (u.vehicle == null or u.vehicle.motive != "h")


## Mines `u` set off on a move: every hex entered on the ground, or the landing hex.
static func after_move(state: GameState, dice: Dice, emit: Callable, u: Unit, path: Array[Vector3i],
		from: Vector2i, jump: bool) -> void:
	if state.minefields.is_empty() or not sets_off(u):
		return
	var hexes: Array[Vector2i] = []
	if jump:
		hexes.append(u.coord)
	else:
		var last := from
		for k in path:
			var c := MoveOptions.coord_of(k)
			if c != last:
				hexes.append(c)
				last = c
	for c in hexes:
		enter(state, dice, emit, u, c)


static func enter(state: GameState, dice: Dice, emit: Callable, u: Unit, c: Vector2i) -> void:
	for f: Dictionary in state.minefields.duplicate():
		if f["hex"] != c or u.destroyed:
			continue
		var need: int = NEED[int(f["density"])] + (2 if Spa.has(u, Spa.EAGLES_EYES) else 0)  # Campaign Operations p. 74
		var roll := dice.roll_2d6()
		var d := {"kind": "triggered", "coord": c, "side": f["side"], "unit_id": u.id, "roll": roll,
				"need": need, "hit": roll >= need, "groups": f["groups"], "density": f["density"]}
		emit.call(GameEvent.MINEFIELD, d)
		if roll < need:
			continue
		for i in int(f["groups"]):
			if u.destroyed:
				break
			var hl := HitTable.roll_kick(dice, FiringArc.FRONT, u.def.quad) if u.vehicle == null else {}
			WeaponFire.hit_with(state, dice, emit, u, FiringArc.FRONT, GROUP, -1, "minefield", hl)
		f["groups"] = int(f["groups"]) - 1
		if int(f["groups"]) <= 0:
			state.minefields.erase(f)


## Artillery struck `c`: each side with mines there tries to clear them all.
static func clear(state: GameState, dice: Dice, emit: Callable, c: Vector2i) -> void:
	var sides: Array[int] = []
	for f: Dictionary in state.minefields:
		if f["hex"] == c and not sides.has(int(f["side"])):
			sides.append(int(f["side"]))
	for s in sides:
		var roll := dice.roll_2d6()
		var ok := roll >= CLEAR
		emit.call(GameEvent.MINEFIELD, {"kind": "cleared" if ok else "survived", "coord": c, "side": s, "roll": roll, "need": CLEAR})
		if ok:
			state.minefields = state.minefields.filter(func(f: Dictionary) -> bool: return f["hex"] != c)
			return


static func _field(state: GameState, c: Vector2i, side: int) -> Dictionary:
	for f: Dictionary in state.minefields:
		if f["hex"] == c and int(f["side"]) == side:
			return f
	return {}


## Fields in `c` (for the view and explanations).
static func at(state: GameState, c: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f: Dictionary in state.minefields:
		if f["hex"] == c:
			out.append(f)
	return out
