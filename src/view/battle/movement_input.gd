class_name MovementInput
extends Node
## Movement-phase interaction: tap a unit to select, tap a hex to preview
## the path, adjust facing, tap again (or Confirm) to commit.

signal unit_selected(u: Unit)

const COLOR_WALK := Color(0.25, 0.75, 1.0, 0.33)
const COLOR_RUN := Color(1.0, 0.6, 0.2, 0.33)
const COLOR_JUMP := Color(0.7, 0.4, 1.0, 0.33)

var controller: GameController
var highlighter: HexHighlighter
var aim_guide: BattleAimOverlay
var marker: FacingMarker
var hud: BattleHud
var units_layer: UnitsLayer
var bots: BotDriver

var selected: Unit
var mode := MoveMode.Kind.WALK
var options: MoveOptions
var preview: Vector3i
var has_preview := false
var before_move := Callable()  ## Called just before a move is submitted (training undo).
var smash := false  ## Fail building entry rolls on purpose (Destroy Checks).


func on_hex_tapped(c: Vector2i) -> void:
	if units_layer.is_busy() or controller.state.phase != Phase.Kind.MOVEMENT:
		return
	if controller.state.game_over or (bots and bots.is_bot_turn()):
		return
	var u := _pending_at(c)
	if u and u != selected and controller.pending_units().has(u):
		_select(u)
	elif selected and has_preview and MoveOptions.coord_of(preview) == c:
		on_confirm()
	elif selected and options.reachable_hexes().has(c):
		_set_preview(_best_key_in(c))
	else:
		clear_selection()


## A unit in the hex still to move, other than the selected one (infantry
## can share a hex with a 'Mech or vehicle).
func _pending_at(c: Vector2i) -> Unit:
	for p in controller.pending_units():
		if p.coord == c and p != selected:
			return p
	return controller.state.unit_at(c)


func on_mode_toggled() -> void:
	if selected == null:
		return
	if selected.asset != null:  # Assets: move, or declare backward movement
		if mode != MoveMode.Kind.JUMP:
			mode = MoveMode.Kind.WALK if mode == MoveMode.Kind.RUN else MoveMode.Kind.RUN
		_replan()
		return
	mode = (mode + 1) % MoveMode.Kind.size()
	if mode == MoveMode.Kind.JUMP and selected.jump_mp() <= 0:
		mode = MoveMode.Kind.WALK
	_replan()


func on_masc(sc := false) -> void:
	if selected == null or units_layer.is_busy():
		return
	var tip := MascInput.engage_sc(controller, selected) if sc else MascInput.engage(controller, selected)
	mode = MoveMode.Kind.RUN
	_replan()
	hud.set_tip(tip)


func on_turn(step: int) -> void:
	if not has_preview:
		return
	var c := MoveOptions.coord_of(preview)
	for i in range(1, 6):
		var k := MoveOptions.key(c, Hex.rotate(preview.z, step * i))
		if options.can_reach(k):
			_set_preview(k)
			return


func on_confirm() -> void:
	if selected and has_preview:
		var u := selected
		var k := preview
		var sm := smash and _forces_entry()
		var why := MissionFlow.move_problem(controller.state, u, k, mode, false)
		if why != "":
			hud.set_tip(why)
			return
		clear_selection()
		if before_move.is_valid():
			before_move.call()
		controller.submit_move(u, k, mode, -1, false, sm)


## Move to the previewed hex and off the battlefield (mission exits, withdrawal).
func on_leave() -> void:
	if selected and has_preview and _can_leave():
		var u := selected
		var k := preview
		clear_selection()
		controller.submit_move(u, k, mode, -1, false, false, true)


func _can_leave() -> bool:
	return MissionFlow.move_problem(controller.state, selected, preview, mode, true) == ""


## Drop the selected 'Mech prone: at the end of the previewed move when it
## has 1 MP to spare, otherwise where it stands.
func on_prone() -> void:
	if selected == null or selected.prone:
		return
	var u := selected
	var k := preview
	var m := mode
	var after := has_preview and k != options.start_key() and ProneMoves.can_drop_after(options, k)
	clear_selection()
	if after:
		controller.submit_move(u, k, m, -1, true)
	else:
		controller.go_prone(u)


func on_smash() -> void:
	smash = not smash
	_refresh()


## Does the previewed move force its way into a 'Mech-scale building?
func _forces_entry() -> bool:
	if not has_preview or mode == MoveMode.Kind.JUMP or preview == options.careful_entry or selected.on_roof:
		return false
	for c in BuildingRules.entered(controller.state.map, selected.coord, options.path_to(preview), false):
		if not controller.state.map.get_tile(c).building.type.civilian:
			return true
	return false


## Enemy straight ahead of the previewed end position, if a charge (or a
## death from above, when jumping) could be declared there.
func charge_target() -> Unit:
	if not has_preview:
		return null
	var c := MoveOptions.coord_of(preview)
	var e := controller.state.unit_at(Hex.neighbor(c, preview.z))
	if e == null or e.side == selected.side:
		return null
	if not Charge.has_mp(controller.state, c, e.coord, mode, options.budget - int(options.cost.get(preview, 0))):
		return null
	return e


func on_charge() -> void:
	var e := charge_target()
	if e:
		var u := selected
		var k := preview
		var m := mode
		clear_selection()
		controller.submit_move(u, k, m, e.id)


func clear_selection() -> void:
	selected = null
	has_preview = false
	options = null
	highlighter.clear()
	if aim_guide != null:
		aim_guide.clear()
	marker.visible = false
	hud.show_move_controls(false)
	hud.leave_button.visible = false
	hud.masc_button.visible = false
	hud.sc_button.visible = false
	hud.prone_button.visible = false
	hud.refresh_move_actions()
	hud.set_info("")


## Select a unit to move (the HUD's Next button).
func select(u: Unit) -> void:
	if u != selected:
		_select(u)


func _select(u: Unit) -> void:
	selected = u
	mode = MoveMode.Kind.RUN if u.masc_used or u.sc_used else MoveMode.Kind.WALK
	if u.asset != null:
		mode = MoveMode.Kind.JUMP if u.asset.card.motive == "j" else MoveMode.Kind.RUN
	smash = false
	hud.show_move_controls(true)
	unit_selected.emit(u)
	_replan()


func _replan() -> void:
	var keep := preview if has_preview else Vector3i.ZERO
	var had := has_preview
	options = MovePlanner.plan(controller.state, selected, mode)
	has_preview = false
	marker.visible = false
	if had and options.can_reach(keep):
		_set_preview(keep)
	else:
		_refresh()


func _best_key_in(c: Vector2i) -> Vector3i:
	# Prefer keeping the previewed facing when moving the preview around.
	if has_preview:
		var k := MoveOptions.key(c, preview.z)
		if options.can_reach(k):
			return k
	return options.end_keys_in(c)[0]


func _set_preview(k: Vector3i) -> void:
	preview = k
	has_preview = true
	var c := MoveOptions.coord_of(k)
	marker.show_at(HexLayout.to_world(c, controller.state.map.get_tile(c).level), k.z)
	_refresh()


func _refresh() -> void:
	var hexes := {}
	var base: Color = [COLOR_WALK, COLOR_RUN, COLOR_JUMP][mode]
	for c in options.reachable_hexes():
		hexes[c] = base
	if has_preview:
		var route: Array[Vector3i] = options.path_to(preview)
		for i in route.size():
			var progress := float(i + 1) / float(maxi(1, route.size()))
			hexes[MoveOptions.coord_of(route[i])] = HexHighlighter.PATH.lerp(
				HexHighlighter.DESTINATION, progress)
		hexes[MoveOptions.coord_of(preview)] = HexHighlighter.DESTINATION
	hexes[selected.coord] = HexHighlighter.SELECTED
	highlighter.show_hexes(hexes)
	if aim_guide != null:
		var facing := preview.z if has_preview else selected.facing
		var pos := MoveOptions.coord_of(preview) if has_preview else selected.coord
		aim_guide.show_arcs(selected, pos, facing)
	hud.set_mode_label(AssetMove.mode_name(selected, mode))
	var spent: int = options.cost[preview] if has_preview else 0
	var where := Hex.label(MoveOptions.coord_of(preview)) if has_preview else "-"
	var heat_text := ""
	if selected.asset == null and selected.vehicle == null and selected.ba == null:
		var heat_gain := 0
		if has_preview:
			heat_gain = 1 if mode == MoveMode.Kind.WALK else 2 if mode == MoveMode.Kind.RUN else maxi(3, MoveOptions.hexes_entered(options.path_to(preview), selected.coord))
		heat_text = "  |  heat %d (+%d)" % [selected.heat, heat_gain]
	hud.set_info("%s  |  %s %d/%d MP  |  to %s%s%s" % [selected.def.display_name(),
			AssetMove.mode_name(selected, mode), spent, options.budget, where, heat_text,
			"  |  prone: standing costs 2 MP and a roll" if selected.prone else ""])
	var ct := charge_target()
	hud.charge_button.visible = ct != null
	hud.charge_button.text = "Death from Above" if mode == MoveMode.Kind.JUMP else "Charge"
	hud.masc_button.text = MascInput.label(selected)
	hud.masc_button.visible = hud.masc_button.text != ""
	hud.sc_button.text = MascInput.sc_label(selected)
	hud.sc_button.visible = hud.sc_button.text != ""
	hud.smash_button.visible = _forces_entry()
	hud.smash_button.text = "Smash in: on" if smash else "Smash in"
	hud.leave_button.visible = has_preview and controller.state.mission.def != null and _can_leave()
	hud.prone_button.visible = not selected.prone
	hud.refresh_move_actions()
	if has_preview:
		var tip := Advisor.move(controller.state, selected, mode, preview, options,
				GameSettings.explain_level)
		if ct:
			tip += "\n" + Advisor.charge(selected, ct, mode, MoveOptions.hexes_entered(
					options.path_to(preview), selected.coord), GameSettings.explain_level)
		var why := MissionFlow.move_problem(controller.state, selected, preview, mode, false)
		hud.set_tip(tip + ("\n" + why if why != "" else ""))
	else:
		hud.set_tip("Tap a highlighted hex to preview the move." if GameSettings.explain_level != ExplainLevel.OFF else "")
