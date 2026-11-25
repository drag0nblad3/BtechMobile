class_name GameLauncher
extends Control
## Start screen: training (first for new players), rules drills, a quick
## battle and the force builder. Development labs remain standalone scenes.

const BATTLE_MENU := "res://scenes/menu.tscn"
const DRILLS := "res://scenes/drills.tscn"
var _menu: Control
var _overlay: Control
var _loading: BattleLoading


## Android Back remains available with automatic back-to-exit disabled.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
			return
		get_viewport().set_input_as_handled()
		_back()


func _back() -> void:
	if _loading != null:
		return
	if is_instance_valid(_overlay):
		UiKit.close_overlay(_overlay)
		return
	get_tree().quit()


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	var scroll := UiKit.landscape_scroll(self)
	_menu = scroll.get_parent()
	var box := UiKit.panel(scroll)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	var eyebrow := UiKit.label(box, "FIELD OPERATIONS  /  COMMAND INTERFACE", 18)
	UiSkin.label(eyebrow, "section")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := UiKit.label(box, "BTECH  MOBILE", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiSkin.label(title, "heading")
	var subtitle := UiKit.label(box, "TACTICAL COMBAT SIMULATOR", UiKit.SMALL)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiSkin.rule(box)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 12)
	actions.add_theme_constant_override("v_separation", 12)
	box.add_child(actions)
	GameSettings.load_settings()
	var new_player := GameSettings.training.is_empty()
	var train := UiKit.button(actions, "TRAINING  ·  START HERE" if new_player else "TRAINING",
		_open_training, Vector2(0, 76), "primary" if new_player else "secondary")
	train.name = "TrainingButton"
	var camp := UiKit.button(actions, "CAMPAIGN", _open_campaign, Vector2(0, 64))
	camp.name = "CampaignButton"
	camp.tooltip_text = "A mercenary company whose damage, wounds and experience carry from battle to battle"
	var map_camp := UiKit.button(actions, "MAP CAMPAIGN", _open_map_campaign, Vector2(0, 64))
	map_camp.name = "MapCampaignButton"
	map_camp.tooltip_text = "Take a region zone by zone with a company of three lances"
	var drills := UiKit.button(actions, "RULES DRILLS", _open_drills, Vector2(0, 58))
	drills.name = "DrillsButton"
	drills.tooltip_text = "Quick questions on to-hit numbers, hit locations, missiles, heat and odds"
	var quick := UiKit.button(actions, "QUICK BATTLE", _quick_battle, Vector2(0, 70))
	quick.name = "QuickBattleButton"
	quick.tooltip_text = "Two matched lances on a random map, you against the computer"
	var battle := UiKit.button(actions, "BUILD A BATTLE", _open_battle, Vector2(0, 70),
		"secondary" if new_player else "primary")
	battle.name = "BattleButton"
	var reference := UiKit.button(actions, "TECHNICAL READOUT", _open_reference, Vector2(0, 76))
	reference.name = "TechnicalReadoutButton"
	var slots := UiKit.button(actions, "SAVE SLOTS", _open_slots, Vector2(0, 76))
	slots.name = "SaveSlotsButton"
	for b: Button in [train, camp, map_camp, drills, quick, battle, reference, slots]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 76
	if BattleLaunch.open_training:
		BattleLaunch.open_training = false
		_open_training.call_deferred()
	elif BattleLaunch.open_campaign:
		BattleLaunch.open_campaign = false
		_open_campaign.call_deferred()
	elif BattleLaunch.open_map_campaign:
		BattleLaunch.open_map_campaign = false
		_open_map_campaign.call_deferred()


func _open_training() -> void:
	await _open_screen("Training", func() -> Control: return TrainingScreen.new())


func _open_campaign() -> void:
	await _open_screen("Campaign", func() -> Control: return CampaignScreen.new())


func _open_map_campaign() -> void:
	await _open_screen("Map campaign", func() -> Control: return MapCampaignScreen.new())


func _open_reference() -> void:
	await _open_screen("Technical readout", func() -> Control: return TechnicalReadout.new())


func _open_slots() -> void:
	await _open_screen("Save slots", func() -> Control: return SaveSlotScreen.new())


func _open_drills() -> void:
	await _open_scene("Rules drills", DRILLS)


func _open_battle() -> void:
	await _open_scene("Force builder", BATTLE_MENU)


func _open_screen(title: String, factory: Callable) -> void:
	if _loading != null or is_instance_valid(_overlay):
		return
	await _begin_loading(title)
	_overlay = factory.call()
	_overlay.tree_exited.connect(_restore_menu, CONNECT_ONE_SHOT)
	_menu.hide()
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _end_loading()


func _restore_menu() -> void:
	_overlay = null
	if is_inside_tree() and is_instance_valid(_menu):
		_menu.show()


func _open_scene(title: String, path: String) -> void:
	if _loading != null or is_instance_valid(_overlay):
		return
	await _begin_loading(title)
	if get_tree().change_scene_to_file(path) != OK:
		await _end_loading()


func _begin_loading(title: String) -> void:
	_loading = BattleLoading.new()
	_loading.heading = "COMMAND INTERFACE  /  " + title.to_upper()
	add_child(_loading)
	await _loading.step("Opening " + title + "…", 10.0)


func _end_loading() -> void:
	await _loading.step("Ready", 100.0)
	_loading.hide()
	_loading.queue_free()
	_loading = null


func _quick_battle() -> void:
	if _loading != null or is_instance_valid(_overlay):
		return
	await _begin_loading("Quick battle")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var db := UnitDb.load_dir()
	await _loading.step("Selecting matched forces and battlefield", 40.0)
	var state := QuickBattle.build(db, rng)
	var path := BATTLE_MENU
	if state != null:
		BattleLaunch.pending = state
		BattleLaunch.bot_sides = [1]
		path = BattleLaunch.BATTLE_SCENE
	if get_tree().change_scene_to_file(path) != OK:
		BattleLaunch.pending = null
		await _end_loading()
