class_name GameLauncher
extends Control
## Start screen: training (first for new players), rules drills, a quick
## battle and the force builder. Development labs remain standalone scenes.

const BATTLE_MENU := "res://scenes/menu.tscn"
const DRILLS := "res://scenes/drills.tscn"
var _menu: Control
var _overlay: Control
var _loading: BattleLoading
var _continue: Button


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
	GameSettings.load_settings()
	var new_player := GameSettings.training.is_empty()
	_continue = UiKit.button(box, "CONTINUE", _resume_latest, Vector2(0, 64), "primary")
	_continue.name = "ContinueButton"
	_refresh_continue()
	var groups := HBoxContainer.new()
	groups.add_theme_constant_override("separation", 12)
	box.add_child(groups)
	var play := UiKit.panel(groups)
	play.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.label(play, "PLAY", 26)
	UiKit.button(play, "TRAINING  ·  START HERE" if new_player else "TRAINING",
		_open_training, Vector2(0, 54), "primary" if new_player else "secondary").name = "TrainingButton"
	UiKit.button(play, "QUICK BATTLE", _quick_battle, Vector2(0, 54)).name = "QuickBattleButton"
	UiKit.button(play, "BUILD A BATTLE", _open_battle, Vector2(0, 54),
		"secondary" if new_player else "primary").name = "BattleButton"
	var campaigns := UiKit.panel(groups)
	campaigns.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.label(campaigns, "CAMPAIGNS", 26)
	UiKit.button(campaigns, "MERCENARY CAMPAIGN", _open_campaign, Vector2(0, 52)).name = "CampaignButton"
	UiKit.label(campaigns, "Manage a company, repair damage and fight contracts.", 18)
	UiKit.button(campaigns, "MAP CAMPAIGN", _open_map_campaign, Vector2(0, 52)).name = "MapCampaignButton"
	UiKit.label(campaigns, "Command lances, capture territory and fight encounters.", 18)
	var tools := HBoxContainer.new()
	box.add_child(tools)
	var drills := UiKit.button(tools, "RULES DRILLS", _open_drills, Vector2(0, 48), "subtle")
	drills.name = "DrillsButton"
	var reference := UiKit.button(tools, "TECHNICAL READOUT", _open_reference, Vector2(0, 48), "subtle")
	reference.name = "TechnicalReadoutButton"
	var slots := UiKit.button(tools, "SAVE SLOTS", _open_slots, Vector2(0, 48), "subtle")
	slots.name = "SaveSlotsButton"
	for b: Button in [drills, reference, slots]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
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
		_refresh_continue()


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


## Most recently modified resumable operation in the active workspace.
func _latest() -> String:
	var best := ""
	var newest := 0
	for path: String in [CampaignStore.PATH, MapCampaignStore.PATH, BattleSave.SAVE_PATH]:
		var resolved := SaveProfiles.resolve(path)
		if not FileAccess.file_exists(resolved):
			continue
		var stamp := FileAccess.get_modified_time(resolved)
		if stamp < newest:
			continue
		if path == BattleSave.SAVE_PATH and not BattleSave.has_game():
			continue
		best = path
		newest = stamp
	return best


func _refresh_continue() -> void:
	var latest := _latest()
	_continue.disabled = latest.is_empty()
	match latest:
		BattleSave.SAVE_PATH: _continue.text = "CONTINUE  ·  SAVED BATTLE"
		CampaignStore.PATH: _continue.text = "CONTINUE  ·  MERCENARY CAMPAIGN"
		MapCampaignStore.PATH: _continue.text = "CONTINUE  ·  MAP CAMPAIGN"
		_: _continue.text = "CONTINUE  ·  NO SAVED OPERATION"


func _resume_latest() -> void:
	match _latest():
		BattleSave.SAVE_PATH:
			BattleLaunch.load_autosave = true
			await _open_scene("Saved battle", BattleLaunch.BATTLE_SCENE)
		CampaignStore.PATH: await _open_campaign()
		MapCampaignStore.PATH: await _open_map_campaign()
