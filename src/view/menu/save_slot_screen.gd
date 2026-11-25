class_name SaveSlotScreen
extends Control
## Slot selection is only available from the launcher, never mid-battle.
var _list: VBoxContainer
var _notice: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	var scroll := UiKit.landscape_scroll(self)
	var box := UiKit.panel(scroll)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	box.add_child(head)
	UiKit.button(head, "Back", queue_free, Vector2(120, 52))
	UiKit.label(head, "SAVE SLOTS", 32)
	UiKit.label(box, "Choose an independent save workspace. Battles, replays and both campaign types autosave to the selected slot. Slot 1 contains your existing saves.", 20)
	_notice = UiKit.label(box, "", 20)
	_list = VBoxContainer.new()
	box.add_child(_list)
	_draw()


func _draw() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for slot in SaveProfiles.COUNT:
		var selected := slot == SaveProfiles.active()
		var b := UiKit.button(_list, "Slot %d%s  •  %s" % [slot + 1, " (active)" if selected else "", SaveProfiles.contents(slot)], _select.bind(slot), Vector2(0, 56), "selected" if selected else "secondary")
		b.name = "SaveSlot%d" % (slot + 1)
	var resume := UiKit.button(_list, "Resume active battle", _resume, Vector2(0, 58), "primary")
	resume.disabled = not BattleSave.has_game()


func _select(slot: int) -> void:
	if SaveProfiles.select(slot):
		_notice.text = "Slot %d selected. Start or continue a campaign from the main menu." % (slot + 1)
		_draw()
	else:
		_notice.text = "Could not change save slot."


func _resume() -> void:
	if not BattleSave.has_game():
		return
	BattleLaunch.load_autosave = true
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)
