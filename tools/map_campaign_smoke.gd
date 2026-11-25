extends SceneTree
## Headless map campaign route: launcher -> map campaign -> start -> give an
## order -> end the day with an enemy lance next door -> fight -> end the
## battle -> damage and the day written back.


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
	(screen.find_child("StartMapCampaign", true, false) as Button).pressed.emit()
	await _frames(1)
	var mc := screen.mc
	var grid := screen.find_child("ZoneGrid", true, false) as MapZoneGrid
	if not _check(grid != null and grid.get_child_count() == mc.region.width * mc.region.height, "zone grid missing tiles"):
		return
	for tile in grid.get_children():
		var art := tile.get_node_or_null("ZoneArt") as MapZoneArt
		if not _check(tile is Button and art != null and art.mouse_filter == Control.MOUSE_FILTER_IGNORE, "zone artwork blocks input or is missing"):
			return
	if not _check(screen.find_child("CaptureProgress", true, false) is ProgressBar, "capture progress missing"):
		return
	var alpha := mc.lances_of(0)[0]
	(screen.find_child("Lance_" + alpha.id, true, false) as Button).pressed.emit()
	await _frames(1)
	(screen.find_child("Order_attack", true, false) as Button).pressed.emit()
	await _frames(1)
	var foe := mc.lances_of(1)[0]
	foe.zone = mc.region.neighbors(alpha.zone)[0]  # the enemy is next door
	screen.call("_tap_zone", foe.zone)
	await _frames(1)
	if not _check(alpha.order == MapLance.ATTACK and alpha.target == foe.zone, "order not given"):
		return
	(screen.find_child("EndTurn", true, false) as Button).pressed.emit()
	await _frames(1)
	if not _check(not mc.battles.is_empty(), "no battle after attacking the enemy lance"):
		return
	(screen.find_child("Fight_0", true, false) as Button).pressed.emit()
	await _frames(6)
	if not _check(current_scene.get("in_map_campaign") == true, "battle is not a map campaign battle"):
		return
	var ctl: GameController = current_scene.get("controller")
	var mine := ctl.state.all_units().filter(func(u: Unit) -> bool: return u.side == 0)
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
	if not _check(after.turn == 2 and after.battles.is_empty(), "the day did not end: turn %d" % after.turn):
		return
	var damaged := after.player.mechs.any(func(m: CampaignMech) -> bool: return not m.condition.is_empty())
	if not _check(damaged, "player damage not carried over"):
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
