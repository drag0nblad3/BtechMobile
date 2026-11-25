extends SceneTree
## Headless campaign route: launcher -> campaign -> start company -> battle
## -> take a contract -> end the battle -> report and Warchest written back.

const OUT := "user://campaign.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	CampaignStore.delete()
	change_scene_to_file("res://scenes/launcher.tscn")
	await _frames(2)
	var b := current_scene.find_child("CampaignButton", true, false) as Button
	if not _check(b != null, "campaign button missing"):
		return
	b.pressed.emit()
	await _frames(4)
	var screen := current_scene.find_child("*CampaignScreen*", true, false)
	for n in current_scene.get_children():
		if n is CampaignScreen:
			screen = n
	if not _check(screen is CampaignScreen, "campaign screen did not open"):
		return
	(screen.find_child("StartCompany", true, false) as Button).pressed.emit()
	await _frames(1)
	var form := screen.find_child("FormationButton", true, false) as Button
	if not _check(form != null, "formation button missing"):
		return
	var formed := not form.disabled
	if formed:
		form.pressed.emit()
		await _frames(1)
		screen.call("_build")  # the first redraw renamed its buttons around the freed ones
		await _frames(1)
	var fight := screen.find_child("TakeContract0", true, false) as Button
	if not _check(fight != null and not fight.disabled, "contract button missing"):
		return
	fight.pressed.emit()
	await _frames(6)
	if not _check(current_scene.get("in_campaign") == true, "battle is not a campaign battle"):
		return
	var ctl: GameController = current_scene.get("controller")
	if not _check(not formed or not ctl.state.formations.is_empty(), "the chosen formation wasn't set up"):
		return
	var mine := ctl.state.all_units().filter(func(u: Unit) -> bool: return u.side == 0)
	mine[0].armor[Location.LA] = 0
	for u in ctl.state.all_units():  # hidden and reserve 'Mechs too
		if u.side == 1:
			Damage.destroy_unit(u, "engine destroyed")
	ctl.state.game_over = true
	current_scene.call("_on_event", GameEvent.new(GameEvent.GAME_OVER, {"winner": 0}))
	await _frames(1)
	var c := CampaignStore.load_company()
	if not _check(c != null and c.battles == 1 and CampaignStore.pending_roster().is_empty(), "battle not written back"):
		return
	if not _check(c.contract == null and c.last_met >= 1, "contract not settled"):
		return
	var back := CampaignScreen.new()
	root.add_child(back)
	await _frames(1)
	(back.find_child("ConvertWp", true, false) as Button).pressed.emit()
	await _frames(1)
	if not _check(c.mechs.any(func(m: CampaignMech) -> bool: return m.salvage), "no salvage claimed"):
		return
	var fix := back.find_child("Repair_%s_armor" % c.mechs[0].id, true, false) as Button
	if not _check(fix != null, "no repair button for the damaged 'Mech"):
		return
	fix.pressed.emit()
	await _frames(1)
	c = CampaignStore.load_company()
	if not _check(c.sp > 0 and c.sp < 100 and c.converted == 100 and c.mechs[0].condition.is_empty(), "Support Points repair failed: %d SP" % c.sp):
		return
	print("CAMPAIGN SMOKE OK: ", " | ".join(c.last_report), " | SP left after repair: ", c.sp)
	CampaignStore.delete()
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check(ok: bool, msg: String) -> bool:
	if not ok:
		push_error("CAMPAIGN SMOKE FAILED: " + msg)
		quit(1)
	return ok
