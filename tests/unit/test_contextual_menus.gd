extends TestCase
## Attack and movement controls must not outlive the action that opened them.


func _hud() -> BattleHud:
	var hud := BattleHud.new()
	hud.side_panel = PanelContainer.new()
	hud.side_box = VBoxContainer.new()
	hud.side_panel.add_child(hud.side_box)
	hud.add_child(hud.side_panel)
	var move_frame := PanelContainer.new()
	hud.add_child(move_frame)
	hud.move_bar = HBoxContainer.new()
	move_frame.add_child(hud.move_bar)
	hud.more_button = MenuButton.new()
	hud.move_bar.add_child(hud.more_button)
	var attack_frame := PanelContainer.new()
	hud.add_child(attack_frame)
	hud.attack_bar = HBoxContainer.new()
	attack_frame.add_child(hud.attack_bar)
	hud.attack_button = Button.new()
	hud.attack_bar.add_child(hud.attack_button)
	hud.skip_button = Button.new()
	hud.attack_bar.add_child(hud.skip_button)
	hud.game_over_box = VBoxContainer.new()
	hud.add_child(hud.game_over_box)
	hud.game_over_label = Label.new()
	hud.game_over_box.add_child(hud.game_over_label)
	hud.game_over_detail = Label.new()
	hud.game_over_box.add_child(hud.game_over_detail)
	return hud


func _input(hud: BattleHud) -> AttackInput:
	var ai := AttackInput.new()
	ai.hud = hud
	ai.highlighter = HexHighlighter.new()
	ai.highlighter.multimesh = MultiMesh.new()
	return ai


func test_single_weapon_submission_dismisses_targeting_menu() -> void:
	var hud := _hud()
	var ai := _input(hud)
	hud.show_side(Label.new())
	ai.shots[0] = 123  # One selected weapon, as with Fire after choosing one.
	ai.clear()  # Shared path for Fire, Hold Fire, and melee declarations.
	check(not hud.side_panel.visible, "targeting panel must close once submitted")
	check(ai.shots.is_empty(), "the submitted weapon choice must be reset")
	ai.highlighter.free()
	ai.free()
	hud.free()


func test_explicitly_open_record_sheet_is_not_dismissed_by_attack() -> void:
	var hud := _hud()
	var ai := _input(hud)
	hud.sheet_open = true
	hud.show_side(Label.new())
	ai.clear()
	check(hud.side_panel.visible, "an intentionally opened record sheet stays visible")
	check(hud.sheet_open, "clearing targeting does not toggle the sheet")
	ai.highlighter.free()
	ai.free()
	hud.free()


func test_game_over_dismisses_even_an_open_record_sheet() -> void:
	var hud := _hud()
	hud.sheet_open = true
	hud.show_side(Label.new())
	hud.show_game_over("Battle complete")
	check(not hud.side_panel.visible, "a finished battle has no contextual side panel")
	check(not hud.sheet_open, "the record sheet is no longer active")
	check(hud.game_over_box.visible, "the result remains visible")
	hud.free()


func test_end_of_movement_hides_actions_controls() -> void:
	var hud := _hud()
	hud.show_move_controls(true)
	hud.show_move_controls(false)
	check(not hud.move_bar.visible, "movement controls vanish with the selection")
	hud.free()
