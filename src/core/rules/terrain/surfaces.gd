class_name Surfaces
extends RefCounted
## Ice, mud and snow terrain modifications (book pp. 121-125, errata p. 124)
## and how the whole-map conditions lay them down.
## Ice: a frozen water hex is walked on like dry ground at its surface; any
## piloting roll made in an ice hex gets +1 (entering needs no roll).
## Mud: a running 'Mech that turns in a mud hex rolls at -1 at once and falls
## there if it fails. Snow: ending the move in snow sheds 1 extra heat per
## leg (4 if prone); falling in snow next to a lower hex starts an avalanche
## (Avalanche). None of the three can burn (buildings still can).
## Conditions: Extreme Cold freezes every water hex; Extreme Heat dries water
## into sinkholes (the bottom becomes the ground); Rain lays mud on every hex
## but depth 1+ water and buildings; Snowfall lays snow on every hex but
## depth 1+ water (no cooling for a 'Mech inside a building).

const ICE := "ice"
const MUD := "mud"
const SNOW := "snow"
const ICE_MOD := 1
const MUD_TURN_MOD := -1
const SNOW_PER_LEG := 1
const SNOW_PRONE := 4


## Changes the map for the conditions. Safe to call more than once.
static func apply_conditions(map: BattleMap, c: Conditions) -> void:
	map.no_fire = c.rain
	for t: MapTile in map.tiles.values():
		if t.terrain.is_water and t.depth > 0:
			if c.heat > 0 and map.ground != null:
				t.level -= t.depth
				t.depth = 0
				t.terrain = map.ground
				t.surface = ""
			elif c.cold > 0:
				t.surface = ICE
			continue
		if c.rain and t.building == null and t.terrain.id != "pavement":
			t.surface = MUD
		elif c.snowfall:
			t.surface = SNOW
	if c.heat > 0:
		for t: MapTile in map.tiles.values():
			if t.surface == ICE:
				t.surface = ""


## +1 to a piloting roll made in an ice hex.
static func add_psr(th: ToHit, state: GameState, u: Unit) -> void:
	if state == null:
		return
	var tile := state.map.get_tile(u.coord)
	if tile != null and tile.surface == ICE:
		EnvSpecialist.add_psr(th, u, EnvSpecialist.ICE, "on ice", ICE_MOD, "Treacherous footing: +1 to any piloting roll made on ice.")


## Extra heat shed in the Heat Phase by a 'Mech that ended its move in snow.
static func snow_cooling(state: GameState, u: Unit) -> int:
	var tile := state.map.get_tile(u.coord)
	if tile == null or tile.surface != SNOW or (tile.building != null and not u.on_roof):
		return 0
	if u.prone:
		return SNOW_PRONE
	return SNOW_PER_LEG * maxi(0, 2 - u.legs_destroyed())


## Mud rolls for a running move: one per mud hex the 'Mech turns in.
## [{index, reason, mod, levels, back}] like MovePsr.action_rolls.
static func mud_rolls(state: GameState, u: Unit, path: Array[Vector3i], from: Vector3i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if u.def.quad:
		return out  # four legs keep their footing in mud (p. 238)
	var prev := from
	var rolled := {}
	for i in path.size():
		var k := path[i]
		var c := MoveOptions.coord_of(k)
		var turned := c == MoveOptions.coord_of(prev) and k.z != prev.z
		var standing_turn := u.prone and i == 0
		var tile := state.map.get_tile(c)
		if turned and not standing_turn and tile != null and tile.surface == MUD and not rolled.has(c):
			rolled[c] = true
			out.append({"index": i, "reason": "turning in mud while running", "mod": MUD_TURN_MOD,
					"levels": 0, "back": false})
		prev = k
	return out
