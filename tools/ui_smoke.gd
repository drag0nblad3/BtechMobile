extends SceneTree
## Plays a few turns through the battle scene's input handlers (headless),
## so UI wiring errors show up without a device:
##   godot --headless -s tools/ui_smoke.gd

var _scene: Node
var _frames := 0


func _initialize() -> void:
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3 or _scene.units_layer.is_busy():
		return false
	var gc: GameController = _scene.controller
	if gc.state.game_over or gc.state.turn > 4:
		print("ui smoke ok: turn %d, game over %s" % [gc.state.turn, gc.state.game_over])
		return true
	var p := gc.pending_units()
	if p.is_empty():
		return false
	var u: Unit = p[0]
	match gc.state.phase:
		Phase.Kind.MOVEMENT:
			_scene.movement.on_hex_tapped(u.coord)
			_scene.movement.on_mode_toggled()
			var far: Vector2i = u.coord
			for c: Vector2i in _scene.movement.options.reachable_hexes():
				if Hex.distance(c, u.coord) > Hex.distance(far, u.coord):
					far = c
			_scene.movement.on_hex_tapped(far)
			_scene.movement.on_turn(1)
			_scene.movement.on_confirm()
		_:
			_scene.attacks.begin()
			for e in gc.state.units:
				if e.side != u.side and not e.destroyed:
					_scene.attacks.on_hex_tapped(e.coord)
			_scene._toggle_sheet()
			_scene._cycle_explain()
			_scene._toggle_sheet()
			_scene.attacks.on_confirm()
	return false
