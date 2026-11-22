class_name TransportInput
extends Node
## The Board / Unload button in the move bar (APC Special, AssetTransport).
## Infantry boards a friendly transport where it stands or where its
## previewed move ends; a transport unloads a rider where its previewed
## move ends (or where it stands).

var controller: GameController
var movement: MovementInput
var _button: Button


func setup(gc: GameController, move_input: MovementInput, hud: BattleHud) -> void:
	controller = gc
	movement = move_input
	_button = Button.new()
	_button.custom_minimum_size = BattleHud.BUTTON_SIZE
	_button.add_theme_font_size_override("font_size", BattleHud.FONT_SIZE)
	_button.pressed.connect(_pressed)
	hud.move_bar.add_child(_button)
	_button.visible = false


func _process(_delta: float) -> void:
	if _button == null or not _button.is_visible_in_tree() and movement.selected == null:
		return
	var plan := _plan()
	_button.visible = not plan.is_empty()
	if not plan.is_empty():
		_button.text = plan["text"]


## {text, kind: board|unload, other: Unit} or {} when there's nothing to do.
func _plan() -> Dictionary:
	var u := movement.selected
	if u == null or movement.options == null:
		return {}
	var s := controller.state
	var at := MoveOptions.coord_of(movement.preview) if movement.has_preview else u.coord
	for o in s.units:
		if o.side != u.side or o.destroyed or o == u:
			continue
		if o.coord == at and u.asset != null and u.asset.carried_by < 0:
			var save := u.coord
			u.coord = at
			var why := AssetTransport.board_problem(s, u, o)
			u.coord = save
			if why == "":
				return {"text": "Board", "kind": "board", "other": o}
		if o.asset != null and o.asset.carried_by == u.id:
			return {"text": "Unload", "kind": "unload", "other": o}
	return {}


func _pressed() -> void:
	var plan := _plan()
	if plan.is_empty():
		return
	var u := movement.selected
	var other: Unit = plan["other"]
	var moving := movement.has_preview and movement.preview != movement.options.start_key()
	if moving:
		movement.on_confirm()
	elif plan["kind"] == "unload":
		movement.clear_selection()
	if plan["kind"] == "board":
		if not moving:
			movement.clear_selection()
		controller.board(u, other)
	else:
		controller.deploy(other)
