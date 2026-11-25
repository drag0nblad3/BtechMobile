class_name UnitsLayer
extends Node3D
## Owns all UnitViews and plays GameEvents that affect units.

signal busy_changed(busy: bool)

var views: Dictionary = {}  # unit id -> UnitView
var _playing := 0
var attack_playing := false


## Hidden units only show for sides in `see_hidden` (the human players).
func build(state: GameState, see_hidden: Array = [0, 1]) -> void:
	for u in state.all_units():
		build_one(state, u, see_hidden)


## Invisible reserves have a view/position, but need not allocate a model
## until they enter the battle. Replay's synchronous build stays unchanged.
func build_one(state: GameState, u: Unit, see_hidden: Array, defer_off_field := false) -> void:
	var on_field := (not state.hidden.has(u) or see_hidden.has(u.side)) \
			and not state.reserves.has(u) and not state.waiting.has(u) and not state.mission.exited.has(u.id)
	var v := UnitView.new()
	add_child(v)
	v.setup(u, state.map, on_field or not defer_off_field)
	v.set_field_visible(on_field)
	views[u.id] = v


func view_of(u: Unit) -> UnitView:
	return views.get(u.id)


func is_busy() -> bool:
	return _playing > 0 or attack_playing


## path/start come from the controller's UNIT_MOVED event.
func play_move(unit_id: int, path: Array, from_coord: Vector2i, from_facing: int,
		mode: int = -1) -> void:
	var v: UnitView = views[unit_id]
	_playing += 1
	busy_changed.emit(true)
	v.animation_finished.connect(_on_done, CONNECT_ONE_SHOT)
	v.play_path(path, from_coord, from_facing, mode)


## Re-reads a unit's condition (prone, destroyed, facing after a fall).
func refresh_unit(unit_id: int) -> void:
	var v: UnitView = views.get(unit_id)
	if v and _playing == 0 and not attack_playing:
		v.snap_to_state()


## Plays a cosmetic pose after the record-sheet snapshot has been applied.
func react(e: GameEvent) -> void:
	var id := int(e.data.get("unit_id", -1))
	var v: UnitView = views.get(id)
	if v != null:
		UnitVoxels.react(v._model, e)
	if e.type != GameEvent.PHYSICAL:
		return
	var attacker: UnitView = views.get(int(e.data.get("attacker_id", -1)))
	if attacker == null or not (attacker._model is VxMech):
		return
	var anim := (attacker._model as VxMech).anim
	var side := 0 if int(e.data.get("limb", Location.LA)) in [Location.LA, Location.LL] else 1
	match String(e.data.get("kind", "")):
		"punch": anim.punch(side)
		"kick": anim.kick(side)


func reload_looks() -> void:
	for view: UnitView in views.values():
		if view._model != null:
			view.refresh_look()
			view.show_condition()


func _on_done() -> void:
	_playing -= 1
	if not is_busy():
		busy_changed.emit(false)


func set_attack_playing(on: bool) -> void:
	if attack_playing == on:
		return
	attack_playing = on
	busy_changed.emit(is_busy())
