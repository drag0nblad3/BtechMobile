class_name UndoInput
extends RefCounted
## Training only: the "Undo move" button. Before each of your moves it keeps
## a MoveUndo capture; pressing Undo reloads the battle from it.

var scene: Node  ## The battle scene (battle_scene.gd).
var undo := MoveUndo.new()


func setup(battle: Node) -> void:
	scene = battle
	scene.movement.before_move = before_move
	scene.hud.undo_move.connect(take_back)
	refresh()


func before_move() -> void:
	if scene.training < 0:
		return
	undo.remember(scene.controller, scene.bots.bot_sides, scene.bots.skill, scene.training,
			scene.recorder.frames, scene._tutorial_path)


func refresh() -> void:
	scene.hud.undo_button.visible = scene.training >= 0 and undo.available(scene.controller)


func take_back() -> void:
	if not undo.available(scene.controller):
		refresh()
		return
	BattleLaunch.restore_snapshot = undo.snapshot
	undo.forget()
	scene.get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)
