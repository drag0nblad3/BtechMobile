extends TestCase
## Campaign layer: company roster, damage carried between battles,
## MechWarrior wounds, kills and experience.


func _company() -> Campaign:
	return Campaign.create(CampaignRules.load_file())


## Builds a battle with the company's ready 'Mechs on side 0.
func _battle(c: Campaign) -> Array:
	var fb := ForceBuilder.new(designs(), 20000)
	var ids: Array = c.ready_mechs().map(func(m: CampaignMech) -> String: return m.id)
	for d in CampaignBattle.designs(c, ids):
		fb.add(0, d)
	fb.add(1, "commando_com2d")
	var s := fb.build(make_map(["c0 c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0 c0",
		"c0 c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0 c0"]))
	return [s, CampaignBattle.prepare(c, s, 0, ids)]


func test_starting_lance_uses_catalog_designs() -> void:
	var c := _company()
	check_eq(c.mechs.size(), 4, "a lance")
	for m in c.mechs:
		check(designs().get_def(m.design) != null, "%s is in the catalog" % m.design)
		check(c.pilot(m.pilot_id) != null, "each 'Mech has a pilot")
	check_eq(c.ready_mechs().size(), 4, "all ready")


func test_damage_carries_into_the_next_battle() -> void:
	var c := _company()
	var b := _battle(c)
	var s: GameState = b[0]
	var roster: Dictionary = b[1]
	check_eq(roster.size(), 4, "every 'Mech matched")
	var uid: int = roster.keys()[0]
	var u := s.unit_by_id(uid)
	u.armor[Location.LA] = 0
	u.structure[Location.LA] -= 1
	u.slots[Location.LA][0].hit = true
	u.ammo[0].shots -= 1 if not u.ammo.is_empty() else 0
	u.pilot.hits = 2
	u.heat = 9
	CampaignBattle.finish(c, s, roster, true)
	var m := c.mech(roster[uid])
	check(not m.condition.is_empty(), "damage kept")
	check_eq(c.pilot(m.pilot_id).wounds, 2, "wounds stay until healed with Support Points")
	var s2: GameState = _battle(c)[0]
	var again: Unit = null
	for v in s2.units:
		if v.side == 0 and v.def.id == m.design:
			again = v
			break
	check_eq(again.armor[Location.LA], 0, "armor still gone")
	check_eq(again.structure[Location.LA], u.structure[Location.LA], "structure still dented")
	check(again.slots[Location.LA][0].hit, "critical slot still broken")
	check_eq(again.heat, 0, "heat doesn't carry")
	check_eq(again.pilot.hits, 2, "pilot starts wounded")
	check_eq(again.pilot.name, c.pilot(m.pilot_id).name)


func test_undamaged_mech_comes_back_clean_and_kill_is_credited() -> void:
	var c := _company()
	var b := _battle(c)
	var roster: Dictionary = b[1]
	var uid: int = roster.keys()[1]
	var enemy: Unit = (b[0] as GameState).units_of_side(1)[0]
	var events: Array = [GameEvent.new(GameEvent.DAMAGE, {"unit_id": enemy.id, "source_id": uid, "amount": 5}),
		GameEvent.new(GameEvent.UNIT_DESTROYED, {"unit_id": enemy.id, "reason": "engine destroyed"})]
	var kills := CampaignBattle.kill_credit(events)
	check_eq(kills.get(uid, 0), 1, "last hit gets the kill")
	var frames: Array = [{"events": [{"event": "damage", "data": {"unit_id": enemy.id, "source_id": uid, "amount": 5}},
		{"event": "unit_destroyed", "data": {"unit_id": enemy.id, "reason": "engine destroyed"}}]}]
	check_eq(CampaignBattle.kill_credit_from_frames(frames), kills, "same credit from recorded frames")
	var report := CampaignBattle.finish(c, b[0], roster, true, kills)
	var m := c.mech(roster[uid])
	var p := c.pilot(m.pilot_id)
	check(m.condition.is_empty(), "nothing to fix")
	check_eq(p.kills, 1)
	check(p.fought_last, "fought in the last contract")
	check(report.size() >= 9, "a line per 'Mech and pilot")


func test_center_torso_loss_writes_off_and_head_kills_pilot() -> void:
	var c := _company()
	var b := _battle(c)
	var s: GameState = b[0]
	var roster: Dictionary = b[1]
	var ids: Array = roster.keys()
	Damage.destroy_location(s.unit_by_id(ids[0]), Location.CT)
	Damage.destroy_location(s.unit_by_id(ids[1]), Location.HEAD)
	CampaignBattle.finish(c, s, roster, false)
	var gone := c.mech(roster[ids[0]])
	var headless := c.mech(roster[ids[1]])
	check(gone.written_off, "no center torso, no 'Mech")
	check(not headless.written_off, "a headless 'Mech can be rebuilt")
	check(not headless.can_deploy(), "but not until it is")
	check(c.pilot(headless.pilot_id).dead, "the MechWarrior died with the head")
	check_eq(c.ready_mechs().size(), 2)


func test_left_the_map_is_not_a_wreck() -> void:
	var c := _company()
	var b := _battle(c)
	var roster: Dictionary = b[1]
	var uid: int = roster.keys()[2]
	Damage.destroy_unit((b[0] as GameState).unit_by_id(uid), "left the battlefield")
	CampaignBattle.finish(c, b[0], roster, false)
	check(c.mech(roster[uid]).can_deploy(), "withdrawn 'Mechs fight again")


func test_company_saves_and_loads() -> void:
	var c := _company()
	var b := _battle(c)
	(b[0] as GameState).unit_by_id((b[1] as Dictionary).keys()[0]).armor[Location.CT] = 3
	CampaignBattle.finish(c, b[0], b[1], true)
	var text := JSON.stringify(c.to_dict())
	var back := Campaign.from_dict(JSON.parse_string(text))
	var again := JSON.stringify(back.to_dict())
	check_eq(JSON.stringify(Campaign.from_dict(JSON.parse_string(again)).to_dict()), again, "stable round trip")
	check_eq(int(back.mechs[0].condition["armor"][Location.CT]), 3, "damage survives saving")
	var s2: GameState = _battle(back)[0]
	check(s2.units_of_side(0).size() == 4, "loaded company deploys")
	check_eq(back.add_mech("wasp_wsp1a").id != c.mechs[0].id, true, "ids keep counting")
