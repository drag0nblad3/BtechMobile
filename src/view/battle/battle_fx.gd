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
	var attacker: Unit = _state.unit_by_id(attacker_id) if attacker_id >= 0 else null
	var victim: Unit = _state.unit_by_id(target_id) if target_id >= 0 else null
	var av: UnitView = _units.view_of(attacker) if attacker != null else null
	var tv: UnitView = _units.view_of(victim) if victim != null else null
	var weapon_index := int(d.get("weapon_index", d.get("weapon", -1))) if d.get("weapon", -1) is int else -1
	var weapon_name := String(d.get("weapon_id", d.get("weapon_name", "")))
	var a := av.weapon_origin(weapon_name, weapon_index) if av != null and av.visible else Vector3.INF
	var target := tv.impact_point(a) if tv != null and tv.visible and a != Vector3.INF else _unit_pos(target_id)
	if a == Vector3.INF or target == Vector3.INF:
		return
	var hit := bool(d.get("hit", false))
	var weapon := weapon_name
	var destination := target
	if not hit:
		destination += ShotFx.miss_offset(int(d.get("attacker_id", 0)),
			int(d.get("target_id", 0)), weapon)
	var voxel_fired := av != null and UnitVoxels.fire(av, d, destination)
	if not voxel_fired and get_tree().get_nodes_in_group("battle_shot").size() < ShotFx.MAX_ACTIVE:
		ShotFx.spawn(self, a, destination, weapon, hit)
	if hit:
		VxBlast.spawn(self, destination, "impact", attacker_id * 131 + target_id)
		if tv != null:
			_flash_armor(tv, destination)
	if av != null and not voxel_fired:
		_recoil(av, weapon)
	else:
		VxBlast.spawn(self, destination - Vector3(0, 0.3, 0), "miss",
			int(d.get("attacker_id", 0)) * 131 + int(d.get("target_id", 0)))


## Subtle view-only kick and a localized armor flash, bounded by short tweens.
func _recoil(view: UnitView, weapon: String) -> void:
	if not is_instance_valid(view) or view.get_meta("recoiling", false):
		return
	view.set_meta("recoiling", true)
	var model := view.get_node_or_null("WeaponRecoil")
	if model != null:
		return
	var intensity := 0.045 if ShotFx.style(weapon) == "ballistic" else 0.018
	var start := view.scale
	var tw := view.create_tween()
	tw.tween_property(view, "scale", start * (1.0 - intensity), 0.07)
	tw.tween_property(view, "scale", start, 0.16)
	tw.tween_callback(func():
		if is_instance_valid(view):
			view.remove_meta("recoiling"))


func _flash_armor(view: UnitView, at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.name = "ArmorSpark"
	light.light_color = Color("#ffe3b3")
	light.light_energy = 0.6
	light.omni_range = 1.3
	light.shadow_enabled = false
	add_child(light)
	light.global_position = at
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.15)
	tw.tween_callback(light.queue_free)


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
