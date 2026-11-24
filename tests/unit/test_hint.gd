extends TestCase
## The Hint button suggests the Elite computer's choice without changing the game.


func _game() -> GameController:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json", terrain(), designs())
	var gc := GameController.new(s, 5)
	gc.start_turn()
	return gc


func _to_phase(gc: GameController, phase: int) -> void:
	var guard := 0
	while gc.state.phase != phase and guard < 200:
		guard += 1
		if not Bot.act(gc, gc.state.active_side()):
			break


func test_move_hint_is_elite_plan_and_changes_nothing() -> void:
	var gc := _game()
	_to_phase(gc, Phase.Kind.MOVEMENT)
	var u := gc.pending_units()[0]
	BotSkill.use(BotSkill.Level.NOVICE)
	var before := [u.coord, u.facing, u.heat_generated, gc.dice.roll_2d6()]
	gc.dice = Dice.new(9)
	var h := Hint.move(gc.state, u, ExplainLevel.FULL)
	check_eq(BotSkill.level, BotSkill.Level.NOVICE, "skill level restored")
	check_eq([u.coord, u.facing, u.heat_generated], before.slice(0, 3), "unit untouched")
	check_eq(gc.dice.roll_2d6(), Dice.new(9).roll_2d6(), "no dice used")
	BotSkill.use(BotSkill.Level.ELITE)
	var m := BotMove.plan(gc.state, u)
	check_eq(h["key"], m["key"], "same hex and facing as the Elite bot")
	check(String(h["text"]).begins_with("Hint: "), "explained: " + h["text"])
	check(MovePlanner.plan(gc.state, u, h["mode"]).can_reach(h["key"]), "suggested move is legal")
	BotSkill.use(BotSkill.Level.VETERAN)


func test_fire_hint_is_declarable() -> void:
	var gc := _game()
	_to_phase(gc, Phase.Kind.WEAPON_ATTACK)
	check_eq(gc.state.phase, Phase.Kind.WEAPON_ATTACK, "reached weapon phase")
	var u := gc.pending_units()[0]
	var h := Hint.fire(gc.state, u, ExplainLevel.LIGHT)
	check(String(h["text"]).begins_with("Hint: "), h["text"])
	check_eq(u.torso_twist, 0, "planning left the torso alone")
	if h["twist"] != BotFire.FLIP:
		gc.set_torso_twist(u, h["twist"])
	check(gc.declare_fire(u, h["shots"]), "hinted volley can be declared")


func test_physical_hint_text() -> void:
	var gc := _game()
	_to_phase(gc, Phase.Kind.PHYSICAL_ATTACK)
	if gc.state.phase != Phase.Kind.PHYSICAL_ATTACK:
		return
	var u := gc.pending_units()[0]
	var h := Hint.physical(gc.state, u, ExplainLevel.FULL)
	check(String(h["text"]).begins_with("Hint: "), h["text"])
	check(gc.declare_physical(u, h["attacks"]), "hinted attack can be declared")
