extends SceneTree
## Plays a few turns through the battle scene's input handlers (headless),
## so UI wiring errors show up without a device:
##   godot --headless -s tools/ui_smoke.gd [-- city]
## "city" fights on City Outskirts and also shoots at buildings.

var _scene: Node
var _frames := 0


func _initialize() -> void:
	BattleLaunch.bot_sides = [1]  # Blue is the computer; Red is driven below.
	if OS.get_cmdline_user_args().has("city"):
		var fb := ForceBuilder.new(UnitDb.load_dir(), 6000)
		fb.add(0, "hunchback_hbk4g")
		fb.add(0, "griffin_grf1n")
		fb.add(1, "wolverine_wvr6r")
		BattleLaunch.pending = fb.build(MapLoader.load_file(
				"res://data/maps/city_outskirts.json", TerrainDb.load_file()))
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3 or _scene.units_layer.is_busy():
		return false
	if _frames == 3:
		if _scene.focus_fx == null or _scene.fx._trails == null:
			printerr("BATTLE_VISUAL_SMOKE_FAILED: missing selection rings or projectile effects")
			quit(1)
			return true
		if _scene.hud.info_panel == null or _scene.hud.tip_panel == null:
			printerr("BATTLE_VISUAL_SMOKE_FAILED: missing compact tactical callouts")
			quit(1)
			return true
		BattleShotFx.spawn(_scene.fx._trails, Vector3(0.0, 2.0, 0.0),
				Vector3(4.0, 2.0, 4.0), "large_laser", true)
		if _scene.fx._trails.get_child_count() != 1:
			printerr("BATTLE_VISUAL_SMOKE_FAILED: tracer did not spawn")
			quit(1)
			return true
	var gc: GameController = _scene.controller
	if gc.state.game_over or gc.state.turn > 4:
		var intents := gc.history.filter(func(e): return e.type == GameEvent.INTENT).size()
		var bshots := gc.history.filter(func(e): return e.type == GameEvent.WEAPON_FIRED and e.data.has("target_hex")).size()
		print("ui smoke ok: turn %d, game over %s, computer explained %d actions, %d shots at buildings" % [gc.state.turn, gc.state.game_over, intents, bshots])
		return true
	var p := gc.pending_units()
	if p.is_empty() or _scene.bots.is_bot_turn():
		return false
	var u: Unit = p[0]
	match gc.state.phase:
		Phase.Kind.MOVEMENT:
			_scene.movement.on_hex_tapped(u.coord)
			_scene.movement.on_mode_toggled()
			if u.id % 3 == 0:
				_scene.movement.on_mode_toggled()  # jump, if it can
			var far: Vector2i = u.coord
			for c: Vector2i in _scene.movement.options.reachable_hexes():
				if Hex.distance(c, u.coord) > Hex.distance(far, u.coord):
					far = c
			_scene.movement.on_hex_tapped(far)
			_scene.movement.on_turn(1)
			_scene.movement.on_confirm()
		_:
			_scene.attacks.begin()
			_scene.attacks.on_twist(1)
			_scene.attacks.on_twist(-1)
			for c: Vector2i in gc.state.map.coords():  # aim at a building first, if any
				var t: MapTile = gc.state.map.get_tile(c)
				if t.building != null and Hex.distance(c, u.coord) <= 6:
					_scene.attacks.on_hex_tapped(c)
					break
			for e in gc.state.units:
				if e.side != u.side and not e.destroyed:
					_scene.attacks.on_hex_tapped(e.coord)
			_scene._toggle_sheet()
			_scene._cycle_explain()
			_scene._toggle_sheet()
			_scene.attacks.on_confirm()
	return false
