class_name AssetMoveCost
extends RefCounted
## MP for an Asset to enter one hex (book pp. 141-143). Terrain costs as
## for 'Mechs, but each level up or down costs 2 MP and only one level per
## hex (two between road hexes). By movement type: foot/jump infantry go
## anywhere but water of depth 1+; hover can't enter woods and treats the
## rest (water too) as clear; tracked can't enter heavy woods; wheeled can't
## enter woods, rough or rubble; VTOLs treat everything as clear.
## Only infantry and VTOLs enter building hexes (1 MP, no roll).
## TODO(rules): garages, sand, roof moves and VTOL flight levels.

const PROHIBITED := MoveCost.PROHIBITED
const LEVEL_MP := 2


static func enter_cost(state: GameState, u: Unit, from: Vector2i, to: Vector2i,
		backward := false) -> int:
	var src := state.map.get_tile(from)
	var dst := state.map.get_tile(to)
	if src == null or dst == null:
		return PROHIBITED
	var card := u.asset.card
	var m := card.motive
	var wind := 1 if state.conditions.wind and ["h", "j", "v"].has(m) else 0
	if m == "v":
		return 1 + wind
	if not may_enter(card, dst):
		return PROHIBITED
	if dst.building != null:
		return 1
	var change := absi(ground(card, dst) - ground(card, src))
	var max_change := 0 if backward else (2 if Roads.road_step(src, dst) else 1)
	if change > max_change:
		return PROHIBITED
	var terrain := 0 if m == "h" else dst.terrain.move_cost
	return 1 + terrain + LEVEL_MP * change + surface_mp(card, dst) + wind


## Hexes the Asset may be in at all.
static func may_enter(card: AssetCard, tile: MapTile) -> bool:
	var m := card.motive
	if m == "v":
		return true
	if tile.is_water() and m != "h":
		return false
	if tile.building != null:
		return card.is_infantry() and not card.mechanized
	if tile.surface == Surfaces.SNOW and m == "f" and not card.has("SNOW"):
		return false
	match tile.terrain.id:
		"light_woods":
			return m != "h" and m != "w"
		"heavy_woods":
			return m != "h" and m != "w" and m != "t"
		"rough", "rubble":
			return m != "w"
	return true


## Level a ground Asset moves at: hovercraft skim the water surface.
static func ground(card: AssetCard, tile: MapTile) -> int:
	return tile.level if card.motive == "h" and tile.is_water() else tile.floor_level()


## Ice, mud and snow (p. 142 Battlefield Conditions table).
static func surface_mp(card: AssetCard, tile: MapTile) -> int:
	var m := card.motive
	match tile.surface:
		Surfaces.ICE:
			return 1 if m == "w" and not card.has("SNOW") else 0
		Surfaces.MUD:
			return 0 if ["h", "j", "v"].has(m) else 1
		Surfaces.SNOW:
			return 1 if (m == "t" or m == "w") and not card.has("SNOW") else 0
	return 0
