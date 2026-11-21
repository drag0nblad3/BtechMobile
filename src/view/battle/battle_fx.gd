class_name BattleFx
extends Node3D
## Voxel explosions for game events (VxBlast): hits puff, ammo explosions
## and destroyed 'Mechs blow up, collapsing buildings throw dust and rubble.
## Reads state only; the record sheet and events decide what happened.

const MECH_HEIGHT := 0.55  ## Where on a 'Mech model blasts are centred.

var _state: GameState
var _units: UnitsLayer


func setup(state: GameState, units: UnitsLayer) -> void:
	name = "BattleFx"
	_state = state
	_units = units


func play(e: GameEvent) -> void:
	match e.type:
		GameEvent.WEAPON_FIRED:
			if e.data.get("hit", false):
				_at_unit(e.data.get("target_id", -1), "impact", Vector3(0, 0.1, 0))
		GameEvent.PHYSICAL:
			if e.data.get("hit", false):
				_at_unit(e.data.get("target_id", -1), "impact")
		GameEvent.AMMO_EXPLOSION:
			_at_unit(e.data["unit_id"], "blast")
		GameEvent.UNIT_DESTROYED:
			_at_unit(e.data["unit_id"], "mech")
		GameEvent.BUILDING:
			_building(e.data)


func _building(d: Dictionary) -> void:
	var t := _state.map.get_tile(d.get("coord", Hex.INVALID))
	if t == null:
		return
	var at := HexLayout.tile_top(t)
	match d["kind"]:
		"collapsed", "flattened":
			VxBlast.spawn(self, at + Vector3(0, 0.25, 0), "dust")
		"shot":
			var h := t.building.height if t.building else 1
			VxBlast.spawn(self, at + Vector3(0, h * HexLayout.LEVEL_HEIGHT * 0.6, 0), "impact")


func _at_unit(unit_id: int, kind: String, jitter := Vector3.ZERO) -> void:
	var u := _state.unit_by_id(unit_id)
	var v := _units.view_of(u) if u else null
	if v == null or not v.visible:
		return
	VxBlast.spawn(self, v.global_position + Vector3(0, MECH_HEIGHT, 0) + jitter * randf_range(-1, 1), kind, randi())
