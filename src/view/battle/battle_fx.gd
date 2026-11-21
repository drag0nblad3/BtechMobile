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
		"shot", "smash", "entry_failed":
			var from := _unit_pos(d.get("unit_id", -1))
			if t.building == null or from == Vector3.INF or _map.buildings == null:
				return
			var hit := _map.buildings.scar(t.coord, from, int(d.get("damage", 10)))
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
