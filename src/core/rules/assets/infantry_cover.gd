class_name InfantryCover
extends RefCounted
## Infantry Assets inside a building (book p. 145): +1 to their Destroy
## Check number per building class (Light +1 ... Hardened +4), to at most
## 11. Damage from enemy infantry inside the same building cancels it for
## the turn (AssetState.flushed).

const CLASS_BONUS := {"light": 1, "medium": 2, "heavy": 3, "hardened": 4, "castle_brian": 5}


static func inside_building(state: GameState, u: Unit) -> bool:
	if u.asset == null or not u.asset.card.is_infantry() or u.asset.card.mechanized or u.on_roof:
		return false
	var tile := state.map.get_tile(u.coord)
	return tile != null and tile.building != null


static func check_bonus(state: GameState, u: Unit) -> int:
	if not inside_building(state, u) or u.asset.flushed:
		return 0
	return int(CLASS_BONUS.get(state.map.get_tile(u.coord).building.type.id, 0))
