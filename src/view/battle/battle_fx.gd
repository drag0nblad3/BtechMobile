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
var _trails: Node3D
var _damage_text: Node3D


func setup(state: GameState, units: UnitsLayer, map_view: MapView) -> void:
	name = "BattleFx"
	_state = state
	_units = units
	_map = map_view
	_trails = Node3D.new()
	_trails.name = "WeaponTrails"
	add_child(_trails)
	_damage_text = Node3D.new()
	_damage_text.name = "DamageText"
	add_child(_damage_text)


func play(e: GameEvent) -> void:
	match e.type:
		GameEvent.WEAPON_FIRED:
			_weapon(e.data)
		GameEvent.DAMAGE:
			_damage_popup(e.data)
		GameEvent.PHYSICAL:
			if e.data.get("hit", false):
				_at_unit(e.data.get("target_id", -1), "impact")
		GameEvent.AMMO_EXPLOSION:
			_at_unit(e.data["unit_id"], "blast")
		GameEvent.UNIT_DESTROYED:
			_at_unit(e.data["unit_id"], "mech")
		GameEvent.BUILDING:
			_building(e.data)


## A clear visual path from shooter to target, including near misses.
func _weapon(d: Dictionary) -> void:
	if d.get("no_ammo", false) or d.get("streak_held", false):
		return
	var source := _unit_pos(int(d.get("attacker_id", -1)))
	var target := _unit_pos(int(d.get("target_id", -1)))
	if source != Vector3.INF and target != Vector3.INF:
		var seed := int(d.get("attacker_id", 0)) * 47 				+ int(d.get("target_id", 0)) * 13 + int(d.get("roll", 0))
		BattleShotFx.spawn(_trails, source, target,
				String(d.get("weapon_id", "")), bool(d.get("hit", false)), seed)
	if d.get("hit", false):
		_at_unit(int(d.get("target_id", -1)), "impact", Vector3(0, 0.1, 0))


## Damage numbers rise once per packet, with a strict mobile-friendly cap.
func _damage_popup(d: Dictionary) -> void:
	if bool(d.get("covered", false)) or int(d.get("amount", 0)) <= 0 			or _damage_text.get_child_count() >= 18:
		return
	var p := _unit_pos(int(d.get("unit_id", -1)))
	if p == Vector3.INF:
		return
	var number := Label3D.new()
	number.text = "-%d" % int(d["amount"])
	number.font_size = 38
	number.pixel_size = 0.002
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.no_depth_test = true
	number.fixed_size = true
	number.outline_size = 7
	number.outline_modulate = Color("#1b1920")
	number.modulate = Color("#ffc17a")
	_damage_text.add_child(number)
	var offset := float((_damage_text.get_child_count() % 5) - 2) * 0.16
	number.global_position = p + Vector3(offset, 0.12, 0.0)
	var tw := number.create_tween().set_parallel(true)
	tw.tween_property(number, "position:y", number.position.y + 0.65, 0.68)
	tw.tween_property(number, "modulate:a", 0.0, 0.68).set_delay(0.12)
	var done := number.create_tween()
	done.tween_interval(0.84)
	done.tween_callback(number.queue_free)


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
