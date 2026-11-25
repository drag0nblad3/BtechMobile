class_name TerrainMaster
extends RefCounted
## Terrain Master SPA (Campaign Operations p. 81), bought once per specialty
## ("terrain_master:forest_ranger"). Forest Ranger: woods cost 1 MP less, and
## after walking it is +1 to hit while in woods. Mountaineer: rough and rubble
## cost 1 MP less, so does each level change, and -1 on the rubble roll.
## Frogman: water deeper than depth 1 costs 1 MP less. Swamp Beast: -1 on
## mud rolls. 'Mechs only here; nothing here lets a unit into terrain it
## can't enter.
## TODO(rules): Frogman's -1 to rolls under water, Swamp Beast's mud cloud,
## Nightwalker (no light-based MP costs in play) and Drag Racer (vehicles).

const FOREST_RANGER := "forest_ranger"
const MOUNTAINEER := "mountaineer"
const FROGMAN := "frogman"
const SWAMP_BEAST := "swamp_beast"
const WOODS := ["light_woods", "heavy_woods"]
const ROUGH := ["rough", "rubble"]


static func has(u: Unit, kind: String) -> bool:
	return Spa.choices(u, Spa.TERRAIN_MASTER).has(kind)


## MP taken off a 'Mech's cost of entering `to` from `from` (never below 1 in all).
static func discount(map: BattleMap, u: Unit, from: Vector2i, to: Vector2i) -> int:
	var kinds := Spa.choices(u, Spa.TERRAIN_MASTER)
	if kinds.is_empty():
		return 0
	var src := map.get_tile(from)
	var dst := map.get_tile(to)
	if src == null or dst == null:
		return 0
	var paved := Roads.road_step(src, dst) or Bridges.onto_deck(src, dst)
	var d := 0
	if kinds.has(FOREST_RANGER) and not paved and WOODS.has(dst.terrain.id):
		d += 1
	if kinds.has(MOUNTAINEER):
		if not paved and ROUGH.has(dst.terrain.id):
			d += 1
		if Roads.climb_cost(src, dst, MoveCost.level_change(src, dst)) > 0:
			d += 1
	if kinds.has(FROGMAN) and dst.is_water() and dst.depth > 1 and not Bridges.onto_deck(src, dst):
		d += 1
	return d


## Forest Ranger cover: +1 to hit a target that walked and stands in woods.
static func add_cover(th: ToHit, state: GameState, t: Unit) -> void:
	if t == null or t.move_mode != MoveMode.Kind.WALK or not has(t, FOREST_RANGER):
		return
	var tile := state.map.get_tile(t.coord)
	if tile != null and WOODS.has(tile.terrain.id):
		th.add("Forest Ranger", 1, "Forest Ranger: walking through woods, it uses every tree for cover.")


## Piloting modifier for a move roll ("entering rubble", mud).
static func psr_mod(u: Unit, reason: String) -> int:
	if reason == "entering rubble" and has(u, MOUNTAINEER):
		return -1
	if reason.contains("mud") and has(u, SWAMP_BEAST):
		return -1
	return 0
