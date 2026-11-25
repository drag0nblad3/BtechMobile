extends SceneTree
## Headless map campaign route: launcher -> map campaign -> start -> give an
## order -> end the day with an enemy lance next door -> fight -> end the
## battle -> damage and the day written back.


const SEED := 74021


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	MapCampaignStore.delete()
	change_scene_to_file("res://scenes/launcher.tscn")
	await _frames(2)
	var b := current_scene.find_child("MapCampaignButton", true, false) as Button
	if not _check(b != null, "map campaign button missing"):
		return
	b.pressed.emit()
	await _frames(4)
	var screen: MapCampaignScreen = null
	for n in current_scene.get_children():
		if n is MapCampaignScreen:
			screen = n
	if not _check(screen != null, "map campaign screen did not open"):
		return
	screen.rng.seed = SEED
	print("MAP_CAMPAIGN_SEED|", SEED)
	(screen.find_child("StartMapCampaign", true, false) as Button).pressed.emit()
	await _frames(1)
	var mc := screen.mc
	var grid := screen.find_child("ZoneGrid", true, false) as MapZoneGrid
	if not _check(grid != null and grid.get_child_count() == mc.region.width * mc.region.height, "zone grid missing tiles"):
		return
	for tile in grid.get_children():
		if not _check(tile is MapHexButton and tile._has_point(tile.size / 2.0)
				and not tile._has_point(Vector2.ZERO), "hex hit area is incorrect"):
			return
	if not _check(screen.find_child("CaptureProgress", true, false) is ProgressBar, "capture progress missing"):
		return
	# Use a real bridge garrison: the bot holds it, it has no automatic
	# repair benefit, and no other enemy is allowed into this fixture.
	var alpha := mc.lances_of(0)[0]
	var bridge: Dictionary = {}
	for loc: Dictionary in mc.region.locations:
		if loc["kind"] == "bridge":
			bridge = loc
			break
	if not _check(not bridge.is_empty(), "fixture needs a bridge"):
		return
	var foe: MapLance
	for l: MapLance in mc.lances_of(1):
		if l.zone == bridge["zone"]:
			foe = l
			break
	if not _check(foe != null, "fixture needs a bridge garrison"):
		return
	mc.lances = mc.lances.filter(func(l: MapLance) -> bool: return l.side == 0 or l == foe)
	alpha.zone = mc.region.neighbors(foe.zone)[0]
	MapOrders.give(mc, alpha, MapLance.DEFEND)
	screen.call("_build")
	await _frames(1)
	(screen.find_child("Lance_" + alpha.id, true, false) as Button).pressed.emit()
	await _frames(1)
	(screen.find_child("Order_attack", true, false) as Button).pressed.emit()
	await _frames(1)
	screen.call("_tap_zone", foe.zone)
	await _frames(1)
	if not _check(alpha.order == MapLance.ATTACK and alpha.target == foe.zone, "order not given"):
		return
	(screen.find_child("EndTurn", true, false) as Button).pressed.emit()
	await _frames(1)
	if not _check(mc.battles.size() == 1, "expected one battle, got %s (seed %d)" % [mc.battles, SEED]):
		return
	(screen.find_child("Fight_0", true, false) as Button).pressed.emit()
	BattleLaunch.bot_sides = []
	await _frames(6)
	if not _check(current_scene.get("in_map_campaign") == true, "battle is not a map campaign battle"):
		return
	var ctl: GameController = current_scene.get("controller")
	# Freeze automated play: this smoke verifies routing/persistence, not AI.
	var mine := ctl.state.all_units().filter(func(u: Unit) -> bool: return u.side == 0)
	if not _check(not mine.is_empty(), "no player units in encounter"):
		return
	var pending := MapCampaignStore.pending()
	var roster: Dictionary = pending["rosters"][0]
	var damaged_id: String = roster.get(mine[0].id, "")
	if not _check(not damaged_id.is_empty(), "damaged unit has no saved roster mapping"):
		return
	mine[0].armor[Location.LA] = 0
	for u in ctl.state.all_units():
		if u.side == 1:
			Damage.destroy_unit(u, "engine destroyed")
	ctl.state.game_over = true
	current_scene.call("_on_event", GameEvent.new(GameEvent.GAME_OVER, {"winner": 0}))
	await _frames(1)
	var after := MapCampaignStore.load_campaign()
	if not _check(after != null and MapCampaignStore.pending().is_empty(), "battle not written back"):
		return
	if not _check(after.turn == 2 and after.battles.is_empty(), "seed %d: turn %d, remaining battles %s" % [SEED, after.turn, after.battles]):
		return
	var damaged := after.player.mech(damaged_id)
	if not _check(damaged != null and not damaged.condition.is_empty()
			and int(damaged.condition["armor"][Location.LA]) == 0, "specific arm damage not carried over"):
		return
	print("MAP CAMPAIGN SMOKE OK: ", " | ".join(after.log))
	MapCampaignStore.delete()
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check(ok: bool, msg: String) -> bool:
	if not ok:
		push_error("MAP CAMPAIGN SMOKE FAILED: " + msg)
		quit(1)
	return ok
