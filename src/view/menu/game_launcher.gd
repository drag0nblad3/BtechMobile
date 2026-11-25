class_name GameLauncher
extends Control
## Start screen: training (first for new players), rules drills, a quick
## battle and the force builder. Development labs remain standalone scenes.

const BATTLE_MENU := "res://scenes/menu.tscn"
const DRILLS := "res://scenes/drills.tscn"


## Android Back remains available with automatic back-to-exit disabled.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
			return
		get_viewport().set_input_as_handled()
		get_tree().quit()


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	var scroll := UiKit.landscape_scroll(self)
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
	var drills := UiKit.button(actions, "RULES DRILLS", func(): get_tree().change_scene_to_file(DRILLS), Vector2(0, 58))
	drills.name = "DrillsButton"
	drills.tooltip_text = "Quick questions on to-hit numbers, hit locations, missiles, heat and odds"
	var quick := UiKit.button(actions, "QUICK BATTLE", _quick_battle, Vector2(0, 70))
	quick.name = "QuickBattleButton"
	quick.tooltip_text = "Two matched lances on a random map, you against the computer"
	var battle := UiKit.button(actions, "BUILD A BATTLE", _open_battle, Vector2(0, 70),
		"secondary" if new_player else "primary")
	battle.name = "BattleButton"
	for b: Button in [train, camp, map_camp, drills, quick, battle]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 76


func _open_training() -> void:
	BattleLaunch.open_training = true
	get_tree().change_scene_to_file(BATTLE_MENU)


func _open_campaign() -> void:
	BattleLaunch.open_campaign = true
	get_tree().change_scene_to_file(BATTLE_MENU)


func _open_map_campaign() -> void:
	BattleLaunch.open_map_campaign = true
	get_tree().change_scene_to_file(BATTLE_MENU)


func _quick_battle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var state := QuickBattle.build(UnitDb.load_dir(), rng)
	if state == null:
		_open_battle()
		return
	BattleLaunch.pending = state
	BattleLaunch.bot_sides = [1]
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)


func _open_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_MENU)

