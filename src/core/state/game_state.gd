class_name GameState
extends RefCounted
## Complete, serializable-in-principle state of one battle.
## Rules code reads and mutates this; views only read it.

var map: BattleMap
var units: Array[Unit] = []
var turn: int = 0
var phase: int = Phase.Kind.INITIATIVE
## Sides by initiative, loser first.
var initiative_order: Array[int] = []
## One side id per unit activation this phase (see UnequalNumbers).
var side_order: Array[int] = []
## Index into side_order of the side that acts next.
var order_index: int = 0
var initiative_rolls: Dictionary = {}  # side -> 2d6 total
## Weapon attacks declared this phase, resolved together at its end:
## [{attacker_id, weapon_index, target_id, to_hit: ToHit}].
var declared_fire: Array[Dictionary] = []
## Physical attacks declared this phase: [{attacker_id, kind, target_id, to_hit, limb}].
var declared_physical: Array[Dictionary] = []
## Damage to buildings this phase, per attacker: unit id -> {Vector2i: int}.
var building_hits: Dictionary = {}
## Building hexes destroyed in an attack phase; they come down at its end.
var doomed_buildings: Array[Vector2i] = []
## Optional Initiative Die rule and the dice in play: side -> bonus.
var initiative_die_rule := false
var initiative_die: Dictionary = {}
## Heat dealt to hexes this phase (Fire): Vector2i -> int.
var fire_heat: Dictionary = {}
## Spotters for indirect fire: unit id -> {target, turn}.
var spotting: Dictionary = {}
## TAG designations (Tag): target id -> {by, turn}; tag_used: unit id -> turn.
var tagged: Dictionary = {}
var tag_used: Dictionary = {}
## Distant Arrow IV missiles in flight (ArrowIv): [{attacker_id, weapon_index, hex, turn, need, mods}].
var artillery: Array[Dictionary] = []
## Weather, temperature and gravity for the whole map.
var conditions := Conditions.new():
	set(v):
		conditions = v
		if map != null:
			map.windy = v.wind
			Surfaces.apply_conditions(map, v)
## Units that passed this turn's low-visibility sensor check: id -> true.
var sees_through: Dictionary = {}
## Mission and its running score (Mission, MissionState).
var mission := MissionState.new()
## Hidden units (HiddenUnits): off `units` until revealed, so nothing can see them.
var hidden: Array[Unit] = []
## Point-blank shots waiting for their owners' answers: [{unit_id, target_id}].
var point_blank: Array[Dictionary] = []
## 'Mechs waiting to combat drop (CombatDrop): off the field until they land.
var reserves: Array[Unit] = []
## 'Mechs held back for a later wave (Waves).
var waiting: Array[Unit] = []
## Units that beat ECM Interference this turn: id -> true (EcmInterference).
var ecm_clear: Dictionary = {}
var game_over: bool = false
var winner: int = -1


func _init(battle_map: BattleMap) -> void:
	map = battle_map


func add_unit(u: Unit) -> void:
	units.append(u)


func unit_by_id(unit_id: int) -> Unit:
	for u in all_units():
		if u.id == unit_id:
			return u
	return null


## The living unit in a hex. Wrecks don't block movement or stacking.
## A 'Mech or vehicle comes before infantry sharing its hex (AssetStacking).
func unit_at(c: Vector2i) -> Unit:
	var inf: Unit = null
	for u in units:
		if u.coord == c and not u.destroyed and (u.asset == null or u.asset.carried_by < 0):
			if not AssetStacking.is_infantry(u):
				return u
			if inf == null:
				inf = u
	return inf


func units_of_side(side: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if u.side == side:
			out.append(u)
	return out


## On the field and hidden alike.
func all_units() -> Array[Unit]:
	var out: Array[Unit] = units.duplicate()
	out.append_array(hidden)
	out.append_array(reserves)
	out.append_array(waiting)
	return out


## Sides that still have a 'Mech on the field (hidden ones count).
func sides_alive() -> Array[int]:
	var out: Array[int] = []
	for u in all_units():
		if not u.destroyed and not out.has(u.side):
			out.append(u.side)
	out.sort()
	return out


func sides() -> Array[int]:
	var out: Array[int] = []
	for u in all_units():
		if not out.has(u.side):
			out.append(u.side)
	out.sort()
	return out


func active_side() -> int:
	if side_order.is_empty():
		return -1
	return side_order[order_index % side_order.size()]
