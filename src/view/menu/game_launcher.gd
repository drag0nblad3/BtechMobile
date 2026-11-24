class_name GameLauncher
extends Control
## Start screen: training (first for new players), rules drills, a quick
## battle, the force builder, and the voxel graphics labs.

const BATTLE_MENU := "res://scenes/menu.tscn"
const VOXEL_LAB := "res://scenes/voxel_mech_lab.tscn"
const VX_SHOWCASE := "res://scenes/vx_showcase.tscn"
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
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := UiKit.panel(center)
	box.get_parent().custom_minimum_size.x = 550
	box.add_theme_constant_override("separation", 18)
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
	var train := UiKit.button(box, "TRAINING  ·  START HERE" if new_player else "TRAINING",
		_open_training, Vector2(0, 76), "primary" if new_player else "secondary")
	train.name = "TrainingButton"
	var camp := UiKit.button(box, "CAMPAIGN", _open_campaign, Vector2(0, 64))
	camp.name = "CampaignButton"
	camp.tooltip_text = "A mercenary company whose damage, wounds and experience carry from battle to battle"
	var drills := UiKit.button(box, "RULES DRILLS", func(): get_tree().change_scene_to_file(DRILLS), Vector2(0, 58))
	drills.name = "DrillsButton"
	drills.tooltip_text = "Quick questions on to-hit numbers, hit locations, missiles, heat and odds"
	var quick := UiKit.button(box, "QUICK BATTLE", _quick_battle, Vector2(0, 70))
	quick.name = "QuickBattleButton"
	quick.tooltip_text = "Two matched lances on a random map, you against the computer"
	var battle := UiKit.button(box, "BUILD A BATTLE", _open_battle, Vector2(0, 70),
		"secondary" if new_player else "primary")
	battle.name = "BattleButton"
	var labs := HBoxContainer.new()
	labs.add_theme_constant_override("separation", 10)
	box.add_child(labs)
	var lab := UiKit.button(labs, "VOXEL LAB", _open_lab, Vector2(0, 52), "subtle")
	lab.name = "VoxelLabButton"
	var vx := UiKit.button(labs, "VOXEL SHOWCASE", _open_vx, Vector2(0, 52), "subtle")
	vx.name = "VxShowcaseButton"
	for b in [lab, vx]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UiKit.SMALL)


func _open_training() -> void:
	BattleLaunch.open_training = true
	get_tree().change_scene_to_file(BATTLE_MENU)


func _open_campaign() -> void:
	BattleLaunch.open_campaign = true
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


func _open_lab() -> void:
	get_tree().change_scene_to_file(VOXEL_LAB)


func _open_vx() -> void:
	get_tree().change_scene_to_file(VX_SHOWCASE)
