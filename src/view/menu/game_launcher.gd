class_name GameLauncher
extends Control
## Start screen: choose the rules-driven battle game or the voxel graphics lab.

const BATTLE_MENU := "res://scenes/menu.tscn"
const VOXEL_LAB := "res://scenes/voxel_mech_lab.tscn"
const VX_SHOWCASE := "res://scenes/vx_showcase.tscn"


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
	var bg := ColorRect.new()
	bg.color = Color("0c1622")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 440.0
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	var title := UiKit.label(column, "BTECH MOBILE", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := UiKit.label(column, "Choose a mode", UiKit.SMALL)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var battle := UiKit.button(column, "PLAY BATTLE GAME", _open_battle, Vector2(0, 88))
	battle.name = "BattleButton"
	var lab := UiKit.button(column, "VOXEL MECH LAB", _open_lab, Vector2(0, 88))
	lab.name = "VoxelLabButton"
	var caption := UiKit.label(column, "Test walking, targeted armor damage and limb destruction.", UiKit.SMALL)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vx := UiKit.button(column, "CLAUDE VOXEL TEST", _open_vx, Vector2(0, 72))
	vx.name = "VxShowcaseButton"


func _open_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_MENU)


func _open_lab() -> void:
	get_tree().change_scene_to_file(VOXEL_LAB)


func _open_vx() -> void:
	get_tree().change_scene_to_file(VX_SHOWCASE)
