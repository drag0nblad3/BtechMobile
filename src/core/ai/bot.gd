class_name Bot
extends RefCounted
## A computer opponent. It plays through the same GameController calls as the
## UI, one unit at a time, and announces why it chose each action so a
## learner can compare its thinking with their own.


## Takes the next action for `side` if it is that side's turn, playing at
## `skill` (BotSkill.Level). Returns true if it acted.
static func act(gc: GameController, side: int, skill: int = BotSkill.Level.VETERAN) -> bool:
	BotSkill.use(skill)
	var s := gc.state
	if s.game_over:
		return false
	if not s.point_blank.is_empty():
		return BotHidden.answer(gc, side)
	if BotHidden.reveal(gc, side):
		return true
	if s.active_side() != side:
		return false
	var pending := gc.pending_units()
	if pending.is_empty():
		return false
	var u := pending[0]
	match s.phase:
		Phase.Kind.MOVEMENT:
			if s.reserves.has(u):
				var d := BotDrop.plan(s, u)
				gc.announce(u, d["reason"])
				return gc.combat_drop(u, d["hex"], d["facing"])
			var ride := BotTransport.ride(s, u)
			if ride != null:
				gc.announce(u, "climbs aboard %s to cover the distance faster" % Names.unit(ride))
				return gc.board(u, ride)
			var m := BotTransport.pickup(s, u)
			if m.is_empty():
				m = BotMove.plan(s, u)
			if BotSkill.advanced_tricks():
				m = BotMasc.plan(gc, u, m)
			gc.announce(u, m["reason"])
			if not gc.submit_move(u, m["key"], m["mode"], m.get("charge", -1), false, false, m.get("leave", false)):
				return false
			var drop := BotTransport.after_move(gc, u)
			if drop != "":
				gc.announce(u, drop)
			return true
		Phase.Kind.WEAPON_ATTACK:
			var tag_at := BotTag.choose(s, u) if BotSkill.basic_tricks() else null
			if tag_at != null:
				gc.announce(u, "fires TAG at %s so its lancemates' missiles can arc in" % Names.unit(tag_at))
				gc.fire_tag(u, tag_at.id)
			var f := BotFire.plan(s, u)
			var club := BotPhysical.club_instead(s, u, f["value"]) if BotSkill.advanced_tricks() else ""
			if club != "":
				gc.announce(u, club)
				return gc.pick_up_club(u)
			if f["twist"] == BotFire.FLIP:
				gc.set_arms_flipped(u, true)
			elif f["twist"] != 0:
				gc.set_torso_twist(u, f["twist"])
			var modes: Dictionary = f.get("modes", {})
			for i: int in modes:
				gc.set_weapon_mode(u, i, modes[i])
			var unjam := BotModes.unjam_all(gc, u)
			if unjam != "":
				f["reason"] += "; " + unjam
			var tag := BotNarc.add_beacons(s, u, f["shots"]) if BotSkill.basic_tricks() else ""
			if tag != "":
				f["reason"] += "; " + tag
			var aim := BotAim.choose(s, u, f["shots"]) if BotSkill.advanced_tricks() else ""
			gc.announce(u, f["reason"] + (" (flips its arms to fire backwards)" if f["twist"] == BotFire.FLIP
					else " (twists its torso)" if f["twist"] != 0 else "") + ("; " + aim if aim != "" else ""))
			return gc.declare_fire(u, f["shots"])
		Phase.Kind.PHYSICAL_ATTACK:
			var p := BotPhysical.plan(s, u)
			if not p["attacks"].is_empty():
				gc.announce(u, p["reason"])
			return gc.declare_physical(u, p["attacks"])
	return false
