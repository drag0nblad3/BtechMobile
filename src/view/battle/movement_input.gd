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
var marker: FacingMarker
var hud: BattleHud
var units_layer: UnitsLayer

var selected: Unit
var mode := MoveMode.Kind.WALK
var options: MoveOptions
var preview: Vector3i
var has_preview := false


func on_hex_tapped(c: Vector2i) -> void:
	if units_layer.is_busy() or controller.state.phase != Phase.Kind.MOVEMENT:
		return
	if controller.state.game_over:
		return
	var u := controller.state.unit_at(c)
	if u and u != selected and controller.pending_units().has(u):
		_select(u)
	elif selected and has_preview and MoveOptions.coord_of(preview) == c:
		on_confirm()
	elif selected and options.reachable_hexes().has(c):
		_set_preview(_best_key_in(c))
	else:
		clear_selection()


func on_mode_toggled() -> void:
	if selected == null:
		return
	mode = (mode + 1) % MoveMode.Kind.size()
	if mode == MoveMode.Kind.JUMP and selected.jump_mp() <= 0:
		mode = MoveMode.Kind.WALK
	_replan()


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
		clear_selection()
		controller.submit_move(u, k, mode)


func clear_selection() -> void:
	selected = null
	has_preview = false
	options = null
	highlighter.clear()
	marker.visible = false
	hud.show_move_controls(false)
	hud.set_info("")


func _select(u: Unit) -> void:
	selected = u
	mode = MoveMode.Kind.WALK
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
		for k in options.path_to(preview):
			hexes[MoveOptions.coord_of(k)] = HexHighlighter.PATH
	hexes[selected.coord] = HexHighlighter.SELECTED
	highlighter.show_hexes(hexes)
	hud.set_mode_label(MoveMode.name_of(mode))
	var spent: int = options.cost[preview] if has_preview else 0
	var where := Hex.label(MoveOptions.coord_of(preview)) if has_preview else "-"
	hud.set_info("%s  |  %s %d/%d MP  |  to %s%s" % [selected.def.display_name(),
			MoveMode.name_of(mode), spent, options.budget, where,
			"  |  prone: standing costs 2 MP and a roll" if selected.prone else ""])
	if has_preview:
		hud.set_tip(Advisor.move(controller.state, selected, mode, preview, options,
				GameSettings.explain_level))
	else:
		hud.set_tip("Tap a highlighted hex to preview the move." if GameSettings.explain_level != ExplainLevel.OFF else "")
