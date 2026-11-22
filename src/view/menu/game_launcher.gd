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
	var battle := UiKit.button(box, "ENTER BATTLE", _open_battle, Vector2(0, 88), "primary")
	battle.name = "BattleButton"
	var lab := UiKit.button(box, "VOXEL MECH LAB", _open_lab, Vector2(0, 76))
	lab.name = "VoxelLabButton"
	var vx := UiKit.button(box, "VOXEL SHOWCASE", _open_vx, Vector2(0, 70), "subtle")
	vx.name = "VxShowcaseButton"
	var footer := UiKit.label(box, "SKIRMISH   •   TACTICAL ACADEMY   •   REPLAYS", 17)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiSkin.label(footer, "muted")


func _open_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_MENU)


func _open_lab() -> void:
	get_tree().change_scene_to_file(VOXEL_LAB)


func _open_vx() -> void:
	get_tree().change_scene_to_file(VX_SHOWCASE)
