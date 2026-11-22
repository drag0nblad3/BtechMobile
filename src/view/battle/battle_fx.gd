class_name BattleFx
extends Node3D
## Voxel explosions for game events (VxBlast): hits puff, ammo explosions
## and destroyed 'Mechs blow up, collapsing buildings throw dust and rubble,
## and shots or 'Mechs forcing their way in knock holes in building walls.
## Reads state only; the record sheet and events decide what happened.

const MECH_HEIGHT := 0.55  ## Where on a 'Mech model blasts are centred.

var _state: GameState
var _units: UnitsLayer
var _map: MapView
var _fire_sequence: Dictionary = {}  # Tracks identical mounts within a volley.


func setup(state: GameState, units: UnitsLayer, map_view: MapView) -> void:
	name = "BattleFx"
	_state = state
	_units = units
	_map = map_view


func play(e: GameEvent) -> void:
	match e.type:
		GameEvent.WEAPON_FIRED:
			_weapon_fire(e.data)
		GameEvent.PHYSICAL:
			if e.data.get("hit", false):
				_at_unit(e.data.get("target_id", -1), "impact")
		GameEvent.DAMAGE:
			_location_impact(e.data)
		GameEvent.PHASE_CHANGED:
			_fire_sequence.clear()
		GameEvent.FALL:
			var fallen := _unit_pos(int(e.data.get("unit_id", -1)))
			if fallen != Vector3.INF:
				VxBlast.spawn(self, fallen - Vector3(0, 0.35, 0), "fall", randi())
		GameEvent.AMMO_EXPLOSION:
			_at_unit(e.data["unit_id"], "blast")
		GameEvent.UNIT_DESTROYED:
			_at_unit(e.data["unit_id"], "mech")
		GameEvent.BUILDING:
			_building(e.data)


## Brief readable beams/projectiles are purely visual; rules still resolve
## immediately and no projectile affects targeting, damage or replay state.
func _weapon_fire(d: Dictionary) -> void:
	if d.get("no_ammo", false) or d.get("streak_held", false):
		return
	var attacker_id := int(d.get("attacker_id", -1))
	var target_id := int(d.get("target_id", -1))
	var av: UnitView = _visible_view(attacker_id)
	var tv: UnitView = _visible_view(target_id)
	if av == null or tv == null:
		return
	var weapon := String(d.get("weapon_id", d.get("weapon", "")))
	var mount := _fired_mount(attacker_id, weapon)
	var a := av.mount_world(mount) if mount != null else _unit_pos(attacker_id)
	var target := _unit_pos(target_id)
	var hit := bool(d.get("hit", false))
	if mount != null:
		av.recoil(0.9 if ShotFx.style(weapon) == "ballistic" else 0.45)
	VxBlast.spawn(self, a, "muzzle", attacker_id * 37 + weapon.length())
	var destination := target
	if not hit:
		destination += ShotFx.miss_offset(int(d.get("attacker_id", 0)),
			int(d.get("target_id", 0)), weapon)
	if get_tree().get_nodes_in_group("battle_shot").size() < ShotFx.MAX_ACTIVE:
		ShotFx.spawn(self, a, destination, weapon, hit)
	if not hit:
		VxBlast.spawn(self, destination - Vector3(0, 0.3, 0), "miss",
			int(d.get("attacker_id", 0)) * 131 + int(d.get("target_id", 0)))


## The actual DAMAGE event provides the rolled location; do not guess one
## from the preceding WEAPON_FIRED event or modify the rules' damage rolls.
func _location_impact(d: Dictionary) -> void:
	if d.get("covered", false):
		return
	var v := _visible_view(int(d.get("unit_id", -1)))
	if v == null:
		return
	var loc := int(d.get("loc", Location.CT))
	if loc < 0 or loc >= Location.COUNT:
		return
	var point := v.impact_world(loc, bool(d.get("rear", false)))
	VxBlast.spawn(self, point, "armor", int(d.get("unit_id", 0)) * 47 + loc)


func _visible_view(id: int) -> UnitView:
	var u := _state.unit_by_id(id) if id >= 0 else null
	var v := _units.view_of(u) if u != null else null
	return v if v != null and v.visible else null


## Cycle repeated weapon IDs across their actual record-sheet mounts.
func _fired_mount(id: int, weapon: String) -> MountedWeapon:
	var u := _state.unit_by_id(id) if id >= 0 else null
	if u == null:
		return null
	var matches: Array[MountedWeapon] = []
	for w: MountedWeapon in u.weapons:
		if w.def.id == weapon or w.def.name == weapon:
			matches.append(w)
	if matches.is_empty():
		return null
	var key := "%d:%s" % [id, weapon]
	var step := int(_fire_sequence.get(key, 0))
	_fire_sequence[key] = step + 1
	return matches[step % matches.size()]


func _building(d: Dictionary) -> void:
	var t := _state.map.get_tile(d.get("coord", Hex.INVALID))
	if t == null:
		return
	var at := HexLayout.tile_top(t)
	match d["kind"]:
		"collapsed", "bridge_collapsed", "flattened":
			VxBlast.spawn(self, at + Vector3(0, 0.25, 0), "dust")
		"shot", "smash", "entry_failed":
			var from := _unit_pos(d.get("unit_id", -1))
			if from == Vector3.INF or (t.building == null and t.bridge == null):
				return
			var hit := Vector3.ZERO
			if t.building != null and _map.buildings != null:
				hit = _map.buildings.scar(t.coord, from, int(d.get("damage", 10)))
			elif t.bridge != null and _map.bridges != null:
				hit = _map.bridges.scar(t.coord, from, int(d.get("damage", 10)))
			VxBlast.spawn(self, hit, "impact" if d["kind"] == "shot" else "dust", randi())


func _at_unit(unit_id: int, kind: String, jitter := Vector3.ZERO) -> void:
	var p := _unit_pos(unit_id)
	if p != Vector3.INF:
		VxBlast.spawn(self, p + jitter * randf_range(-1, 1), kind, randi())


## Where a unit's model is (blast height), or INF when it isn't shown.
func _unit_pos(unit_id: int) -> Vector3:
	var u := _state.unit_by_id(unit_id) if unit_id >= 0 else null
	var v := _units.view_of(u) if u else null
	if v == null or not v.visible:
		return Vector3.INF
	return v.global_position + Vector3(0, MECH_HEIGHT, 0)
