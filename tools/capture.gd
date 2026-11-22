extends SceneTree
## Renders the game to a PNG (for visual checks without a device):
##   xvfb-run godot --rendering-method gl_compatibility -s tools/capture.gd -- out.png [mode]
## Modes: (none) battle start · select (move highlights) · attack (weapon phase,
## first enemy targeted) · sheet (record sheet open) · menu (force builder) · setupmenu (its Battlefield page) · clanmenu (its Clan list) ·
## map=<id> (battle start on that map) · gen=<theme>[:seed] (generated two-sheet map) ·
## tutorial (training battle, first lesson) · rolls (sample roll feed) ·
## launcher (first screen) · training (the training campaign screen) · notebook (its notebook, two missions played).

var _frames := 0
var _scene: Node
var _out := "capture.png"
var _mode := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_mode = args[1] if args.size() > 1 else ""
	if _mode.begins_with("map=") or _mode.begins_with("gen=") or _mode == "vfx":  # two lances on that map
		var fb := ForceBuilder.new(UnitDb.load_dir(), 6000)
		for id in ["griffin_grf1n", "warhammer_whm6r"]:
			fb.add(0, id)
		for id in ["marauder_mad3r", "wasp_wsp1a"]:
			fb.add(1, id)
		BattleLaunch.pending = fb.build(_capture_map())
	if _mode == "vfx":
		BattleLaunch.bot_sides = []  # cinematic frame, no bot actions
	if _mode == "tutorial":
		var tut := "res://data/scenarios/tutorial.json"
		BattleLaunch.pending = ScenarioLoader.load_file(tut, TerrainDb.load_file(), UnitDb.load_dir())
		BattleLaunch.bot_sides = [1]
		BattleLaunch.tutorial_path = tut
	BattleLaunch.open_training = _mode in ["training", "notebook"]
	if _mode == "notebook":
		GameSettings.load_settings()
		GameSettings.training = {"first_steps": {"won": true, "kills": 1}, "woods": {"won": false, "kills": 0}}
	var path := "res://scenes/launcher.tscn" if _mode == "launcher" else "res://scenes/menu.tscn" if _mode.ends_with("menu") or BattleLaunch.open_training else "res://scenes/main.tscn"
	_scene = load(path).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		match _mode:
			"select":
				_select_far_move()
			"attack", "sheet", "rolls":
				_to_weapon_phase()
			"notebook":
				_scene.get_child(_scene.get_child_count() - 1)._show_notebook()
			"setupmenu":
				_scene._show_page(1)
			"clanmenu":
				_scene.catalog.mode = DesignFilter.Mode.CLAN
				_scene.catalog.rebuild()
	if _frames == 30 and _mode == "rolls":
		_show_sample_rolls()
	if _frames == 7 and (_mode == "attack" or _mode == "sheet"):
		_target_nearest()
	if _frames == 8 and _mode == "sheet":
		_scene._toggle_sheet()
	if _frames == 8 and _mode == "vfx":
		_stage_battle_visuals()
	if _frames == 39 and _mode == "vfx":
		# Visual review only: place a PPC across the visible battlefield.
		# Does not affect the actual combat resolution or either roster.
		var all_units: Array = _scene.controller.state.units
		if all_units.size() >= 2:
			var muzzle: Vector3 = _scene.units_layer.view_of(all_units[0]).global_position + Vector3(0, 0.65, 0)
			var target: Vector3 = _scene.units_layer.view_of(all_units[all_units.size() - 1]).global_position + Vector3(0, 0.55, 0)
			ShotFx.spawn(_scene.fx, muzzle, target, "er_ppc", true)
			VxBlast.spawn(_scene.fx, target, "impact")
		_scene.hud.show_combat_event(GameEvent.new(GameEvent.WEAPON_FIRED, {"hit": true}))
	if _frames == 28 and _mode == "hitfx":
		var victim: Unit = _scene.controller.state.units[-1]
		var view: UnitView = _scene.units_layer.view_of(victim)
		_scene.rig.focus(view.position)
		victim.heat = 22  # capture-only: never submitted to controller
		_scene.fx.play(GameEvent.new(GameEvent.HEAT, {"unit_id": victim.id, "heat": victim.heat}))
		_scene.fx.play(GameEvent.new(GameEvent.DAMAGE,
				{"unit_id": victim.id, "loc": Location.RA, "rear": false, "amount": 24}))
	if _frames == 40:
		root.get_viewport().get_texture().get_image().save_png(_out)
		print("saved ", _out)
		return true
	return false


func _select_far_move() -> void:
	var u: Unit = _scene.controller.pending_units()[0]
	_scene.movement.on_hex_tapped(u.coord)
	var reach: Dictionary = _scene.movement.options.reachable_hexes()
	var far: Vector2i = u.coord
	for c: Vector2i in reach:
		if Hex.distance(c, u.coord) > Hex.distance(far, u.coord):
			far = c
	_scene.movement.on_hex_tapped(far)


## Everyone walks straight ahead as far as possible, then the first
## attacker targets the nearest enemy.
func _to_weapon_phase() -> void:
	var gc: GameController = _scene.controller
	while gc.state.phase == Phase.Kind.MOVEMENT:
		var u: Unit = gc.pending_units()[0]
		var opts := MovePlanner.plan(gc.state, u, MoveMode.Kind.RUN)
		var best := opts.start_key()
		for k: Vector3i in opts.cost:
			if opts.can_reach(k) and k.z == u.facing and opts.cost[k] > opts.cost.get(best, 0):
				best = k
		gc.submit_move(u, best, MoveMode.Kind.RUN)


func _target_nearest() -> void:
	var gc: GameController = _scene.controller
	var a: Unit = _scene.attacks.attacker
	var best_e: Unit = null
	for e in gc.state.units:
		if e.side != a.side and (best_e == null or Hex.distance(a.coord, e.coord) < Hex.distance(a.coord, best_e.coord)):
			best_e = e
	# Capture only: bring the target into range so the weapon list has rows.
	var spot := Hex.neighbor(Hex.neighbor(Hex.neighbor(Hex.neighbor(a.coord, a.facing), a.facing), a.facing), a.facing)
	if gc.state.map.has(spot) and gc.state.unit_at(spot) == null:
		best_e.coord = spot
		_scene.units_layer.refresh_unit(best_e.id)
	_scene.attacks.on_hex_tapped(best_e.coord)


func _capture_map() -> BattleMap:
	var arg := _mode.substr(4)
	if _mode.begins_with("map=") or _mode == "vfx":
		var id := "city_outskirts" if _mode == "vfx" else arg
		return MapLoader.load_file("res://data/maps/%s.json" % id, TerrainDb.load_file())
	var parts := arg.split(":")
	var seed_value := int(parts[1]) if parts.size() > 1 else 1
	return MapGenerator.build(MapTheme.find(parts[0]), Vector2i(2, 1), seed_value, TerrainDb.load_file())


## Screenshot-only staging: show real loaded model views in the frame.
## This script is not used by gameplay and does not change deployment rules.
func _stage_battle_visuals() -> void:
	var state: GameState = _scene.controller.state
	if state.units.size() < 2:
		return
	var box := HexLayout.map_bounds(state.map)
	var center := box.get_center()
	var targets := [center + Vector3(-3.5, 0, 0), center + Vector3(3.5, 0, 0)]
	var staged := [state.units[0], state.units[state.units.size() - 1]]
	for i in staged.size():
		var unit: Unit = staged[i]
		var chosen := Hex.INVALID
		var nearest := INF
		for coord: Vector2i in state.map.coords():
			var tile: MapTile = state.map.get_tile(coord)
			if tile.building != null or tile.depth > 0:
				continue
			if state.unit_at(coord) != null:
				continue
			var distance := HexLayout.to_world(coord).distance_to(targets[i])
			if distance < nearest:
				nearest = distance
				chosen = coord
		if chosen != Hex.INVALID:
			unit.coord = chosen
			_scene.units_layer.refresh_unit(unit.id)


## Review only: sample lines in the roll feed, nothing is resolved.
func _show_sample_rolls() -> void:
	var s: GameState = _scene.controller.state
	var a: Unit = s.units[0]
	var t: Unit = s.units[s.units.size() - 1]
	for e in [GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": a.id, "weapon": "Medium Laser", "roll": 9, "need": 8, "hit": true}),
			GameEvent.new(GameEvent.DAMAGE, {"unit_id": t.id, "amount": 5, "loc": Location.LT}),
			GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": a.id, "weapon": "AC/20", "roll": 6, "need": 8, "hit": false}),
			GameEvent.new(GameEvent.PSR, {"unit_id": t.id, "roll": 5, "need": 7, "ok": false})]:
		_scene.hud.roll_feed.add_event(e, s)
