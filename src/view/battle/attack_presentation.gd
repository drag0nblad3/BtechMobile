class_name AttackPresentation
extends Node
## Buffers the synchronous rules event burst; schedules cosmetic shots and
## snapshots in emission order. Never rolls dice or writes a live Unit.
signal visual_event(event: GameEvent)
signal trail_created(trail: Node3D)

var _fx: BattleFx
var _state: GameState
var _units: UnitsLayer
var _groups: Array[Dictionary] = []
var _current: Dictionary = {}
var _scheduled := false
var _playing := false
var _posed := {}


func setup(fx: BattleFx, state: GameState, units: UnitsLayer) -> void:
	_fx = fx
	_state = state
	_units = units


func collect(e: GameEvent) -> bool:
	if AttackEventMatch.starts(e):
		_current = {"attack": e, "entries": [], "pose": AttackVisualGeometry.pose(_state, e.data)}
		_groups.append(_current)
	elif e.type in [GameEvent.DAMAGE, GameEvent.UNIT_DESTROYED, GameEvent.AMMO_EXPLOSION, GameEvent.FALL, GameEvent.SHUTDOWN] or (e.type == GameEvent.BUILDING and e.data.get("kind") in ["shot", "cover_hit"]):
		var entry := AttackVisualGeometry.capture(_state, _units, e)
		if not _current.is_empty():
			# Criticals and secondary explosions may interleave cluster hits.
			# Preserve order, but only aim a projectile at direct contacts.
			entry["direct"] = AttackEventMatch.belongs(_current["attack"], e)
			_current["entries"].append(entry)
		else:
			_groups.append({"entries": [entry]})
	elif e.type in [GameEvent.PHASE_CHANGED, GameEvent.ACTIVE_SIDE, GameEvent.TURN_STARTED, GameEvent.GAME_OVER]:
		_current = {}
		return false
	else:
		return false
	if not _scheduled and not _playing:
		_scheduled = true
		_units.set_attack_playing(true)
		_flush.call_deferred()
	return true


func _flush() -> void:
	_scheduled = false
	if _groups.is_empty():
		_playing = false
		for id: int in _posed:
			var v: UnitView = _units.views.get(id)
			if v != null:
				AttackVisualGeometry.apply_pose(v, {"twist": v.unit.torso_twist, "flip": v.unit.arms_flipped})
		_posed.clear()
		_units.set_attack_playing(false)
		return
	_playing = true
	var batch := _groups.duplicate()
	_groups.clear()
	_current = {}
	var timeline := create_tween()
	# Stagger launches; preserve event-time snapshot order by sorting arrival
	# callbacks on one clock. A lance alpha strike must not take 30 seconds.
	var actions: Array[Dictionary] = []
	var at := 0.34
	var order := 0
	for group: Dictionary in batch:
		var attack: GameEvent = group.get("attack")
		var entries: Array = group["entries"]
		if attack != null:
			var duration := 0.24 if attack.type == GameEvent.PHYSICAL else ShotFx.arrival_time(String(attack.data.get("weapon_id", attack.data.get("weapon", ""))))
			actions.append({"at": maxf(0.0, at - duration), "order": order, "callback": _launch.bind(group)})
			order += 1
		for entry: Dictionary in entries:
			actions.append({"at": at, "order": order, "callback": _arrive.bind(entry)})
			order += 1
		at += 0.12 if attack != null and attack.type == GameEvent.PHYSICAL else 0.085
	actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["order"]) < int(b["order"]) if is_equal_approx(a["at"], b["at"]) else float(a["at"]) < float(b["at"]))
	var previous := 0.0
	for action: Dictionary in actions:
		var delay := float(action["at"]) - previous
		if delay > 0.0001:
			timeline.tween_interval(delay)
		timeline.tween_callback(action["callback"])
		previous = float(action["at"])
	timeline.tween_interval(0.20)
	timeline.tween_callback(_flush)


func _launch(group: Dictionary) -> void:
	var e: GameEvent = group["attack"]
	var d := e.data
	visual_event.emit(e)
	var av: UnitView = _units.views.get(int(d.get("attacker_id", -1)))
	if av == null or not av.visible:
		return
	var tv: UnitView = _units.views.get(int(d.get("target_id", -1)))
	var points: Array[Vector3] = []
	for entry: Dictionary in group["entries"]:
		var event: GameEvent = entry["event"]
		if entry.get("direct", false) and (event.type == GameEvent.DAMAGE or event.type == GameEvent.BUILDING):
			if e.type == GameEvent.PHYSICAL and event.data.get("unit_id") == d.get("attacker_id") and event.type == GameEvent.DAMAGE:
				continue
			if not entry["points"].is_empty() and entry["points"][0] != Vector3.INF:
				points.append(entry["points"][0])
	if e.type == GameEvent.PHYSICAL:
		var contact := points[0] if not points.is_empty() else (tv.global_position + Vector3.UP * 0.5 if tv != null and tv.visible else av.global_position)
		if not d.get("hit", false):
			contact += Vector3(0.35, 0.25, 0.35)
		MeleeContact.play(av, d, contact)
		return
	if not AttackEventMatch.fired(d):
		return
	AttackVisualGeometry.apply_pose(av, group["pose"])
	_posed[av.unit.id] = true
	var origins := AttackSockets.origins(av, d)
	if origins.is_empty() or origins[0] == Vector3.INF:
		return
	var origin := origins[0]
	var weapon := String(d.get("weapon_id", d.get("weapon", "")))
	var target := tv.impact_point(origin) if tv != null and tv.visible else AttackVisualGeometry.hex_point(_state, d.get("target_hex", Hex.INVALID), origin)
	if target == Vector3.INF and not points.is_empty():
		target = points[0]
	if target == Vector3.INF:
		return
	if AttackEventMatch.intercepted(d):
		var stop := origin.lerp(target, 0.72)
		ShotFx.spawn(_fx, origin, stop, weapon, false)
		_intercept(stop, weapon)
		return
	if not d.get("hit", false):
		ShotFx.spawn(_fx, origin, target + ShotFx.miss_offset(int(d.get("attacker_id", 0)), int(d.get("target_id", 0)), weapon), weapon, false)
		return
	if d.get("ams", false) and ShotFx.style(weapon) == "missile":
		var stopped := origin.lerp(target, 0.72)
		ShotFx.spawn(_fx, origin, stopped, weapon, false)
		_intercept(stopped, weapon)
	if points.is_empty():
		if tv != null and d.has("narc_loc"):
			target = tv.impact_location(int(d["narc_loc"]), false)
		points.append(target)
	for i in points.size():
		if get_tree().get_nodes_in_group("battle_shot").size() >= ShotFx.MAX_ACTIVE:
			break
		var from := origins[i % origins.size()]
		VxFx.flash(_fx, from, 0.07)
		var trail := ShotFx.spawn(_fx, from, points[i], weapon, true)
		if trail != null:
			trail_created.emit(trail)


func _intercept(point: Vector3, weapon: String) -> void:
	var t := create_tween()
	t.tween_interval(maxf(0.01, ShotFx.arrival_time(weapon)))
	t.tween_callback(func(): VxBlast.spawn(_fx, point, "impact", 17))


func _arrive(entry: Dictionary) -> void:
	var e: GameEvent = entry["event"]
	visual_event.emit(e)
	var v: UnitView = _units.views.get(int(e.data.get("unit_id", -1)))
	if e.type == GameEvent.DAMAGE and e.data.get("covered", false) and not entry["points"].is_empty():
		VxBlast.spawn(_fx, entry["points"][0], "dust", int(e.data.get("source_id", 0)))
	_fx.play_now(e, entry["points"])
	if v != null and not entry["record"].is_empty() and not e.data.get("covered", false):
		v.apply_attack_record(entry["record"])
	_units.react(e)
	if _fx.scars != null:
		_fx.scars.on_event(e)
