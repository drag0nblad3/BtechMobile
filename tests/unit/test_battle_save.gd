extends TestCase
## Round-trip live mid-phase battles, nested record sheets, maps and replay.

func _battle() -> GameController:
	var map := MapLoader.from_dict({
		"rows": ["c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0"],
		"buildings": [{"hex": "0202", "type": "light", "height": 2}],
		"colors": {"clear": "#556677"},
		"fog": {"heavy": ["0303"]}
	}, terrain())
	var state := GameState.new(map)
	var db := designs()
	state.add_unit(Unit.new(1, db.get_def("atlas_as7d"), 0, hex_at(0, 3), 0))
	state.add_unit(Unit.new(2, db.get_def("jenner_jr7d"), 1, hex_at(2, 0), 3))
	state.mission.def = Mission.from_dict({"name": "Hold Ground", "victory": "vp",
			"objectives": [{"hex": "0202", "radius": 1, "vp": 3}]})
	state.conditions = Conditions.from_dict({"wind": true})
	var c := GameController.new(state, 78651)
	c.start_turn()
	return c


func test_round_trip_mid_phase_preserves_rules_and_rng() -> void:
	var c := _battle()
	var u := c.state.unit_by_id(1)
	u.armor[Location.LA] -= 8
	u.structure[Location.RA] -= 2
	u.pilot.hits = 2
	u.heat = 12
	u.weapons[0].mode = "ultra"
	u.ammo[0].shots -= 1
	u.slots[Location.CT][0].hit = true
	u.flooded[Location.LL] = true
	u.narc_pods.append({"side": 1, "loc": Location.CT, "turn": 1})
	c.state.map.get_tile(hex_at(1, 1)).on_fire = true
	c.state.map.get_tile(hex_at(2, 2)).surface = "mud"
	c.state.mission.add_vp(0, 3)
	c.state.mission.def.objectives[0].found = true
	c.state.mission.def.objectives[0].claimed[0] = true
	var th := ToHit.new()
	th.add("gunnery", 4)
	th.aim_loc = Location.CT
	c.state.phase = Phase.Kind.WEAPON_ATTACK
	c.state.declared_fire.append({"attacker_id": 1, "weapon_index": 0,
			"target_id": 2, "to_hit": th})
	c.state.building_hits[1] = {hex_at(1, 1): 8}
	var payload := BattleSave.capture(c, [1], BotSkill.Level.REGULAR, -1, [])
	var restored := BattleSave.restore(payload, designs(), terrain())
	check(not restored.is_empty(), "valid save should restore")
	if restored.is_empty():
		return
	var other: GameController = restored["controller"]
	var ru := other.state.unit_by_id(1)
	check_eq(other.state.phase, Phase.Kind.WEAPON_ATTACK)
	check_eq(ru.armor[Location.LA], u.armor[Location.LA])
	check_eq(ru.structure[Location.RA], u.structure[Location.RA])
	check_eq(ru.pilot.hits, 2)
	check_eq(ru.heat, 12)
	check_eq(ru.weapons[0].mode, "ultra")
	check_eq(ru.ammo[0].shots, u.ammo[0].shots)
	check(ru.slots[Location.CT][0].hit, "critical slot damage persisted")
	check(ru.flooded.has(Location.LL), "integer location keys survived JSON")
	check_eq(ru.narc_pods.size(), 1)
	check(other.state.map.get_tile(hex_at(1, 1)).on_fire, "fire persisted")
	check_eq(other.state.map.get_tile(hex_at(2, 2)).surface, "mud")
	check_eq(other.state.map.get_tile(hex_at(1, 1)).building.height, 2)
	check_eq(other.state.map.get_tile(hex_at(2, 2)).fog, 2)
	check_eq(other.state.mission.vp[0], 3)
	check(other.state.mission.def.objectives[0].found)
	check_eq(other.state.declared_fire[0]["to_hit"].aim_loc, Location.CT)
	check_eq(other.state.building_hits[1][hex_at(1, 1)], 8)
	check_eq(other.dice.roll_2d6(), c.dice.roll_2d6(),
			"next dice roll must match uninterrupted battle")
	check_eq(restored["bots"], [1])


func test_recorded_frames_are_immutable_after_capture() -> void:
	var c := _battle()
	var recorder := BattleRecorder.new()
	recorder.begin(c.state)
	var at := c.state.unit_by_id(2)
	at.armor[Location.LL] -= 10
	recorder.record(GameEvent.new(GameEvent.DAMAGE, {"unit_id": at.id}),
			c.state, "Jenner hit in the left leg.")
	at.armor[Location.LL] -= 4
	var replayed := BattleRecorder.state_at(recorder.frames[1], designs(), terrain())
	check_eq(replayed.unit_by_id(2).armor[Location.LL],
			at.def.armor[Location.LL] - 10)
	check_eq(recorder.frames.size(), 2)
	check_eq(recorder.frames[1]["event"], "damage")


func test_round_trip_hidden_and_reserve_units() -> void:
	var c := _battle()
	var u := c.state.unit_by_id(2)
	c.state.units.erase(u)
	c.state.reserves.append(u)
	c.state.hidden.append(u)
	var data := BattleSave.capture(c, [], 0, -1, [])
	var restored := BattleSave.restore(data, designs(), terrain())
	check(not restored.is_empty())
	if restored.is_empty():
		return
	var s: GameState = restored["controller"].state
	check_eq(s.units.size(), 1)
	check_eq(s.reserves.size(), 1)
	check_eq(s.hidden.size(), 1)
	check_eq(s.reserves[0].id, 2)
	check_eq(s.hidden[0].id, 2)


func test_compressed_payload_round_trip() -> void:
	var c := _battle()
	var path := "user://battle_codec_test.zst"
	var payload := BattleSave.capture(c, [1], 2, -1, [])
	check(BattleSave._write(path, payload), "compressed save should be writable")
	var disk := BattleSave._read(path)
	check_eq(disk.get("schema", -1), BattleSave.VERSION)
	var restored := BattleSave.restore(disk, designs(), terrain())
	check(not restored.is_empty(), "compressed save should decode")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))



func test_asset_round_trip_keeps_card_state_and_generated_weapon() -> void:
	var c := _battle()
	var db := designs()
	var def := db.get_def("savior_repair_vehicle")
	check(def != null, "sample Battlefield Support Asset must be present")
	if def == null:
		return
	var vehicle := Unit.new(99, def, 0, hex_at(1, 0), 0)
	c.state.add_unit(vehicle)
	vehicle.asset.improved = true
	vehicle.asset.check = 5
	vehicle.asset.damage = 3
	vehicle.asset.carried_by = 2
	vehicle.asset.altitude = 1
	vehicle.weapons[0].fired = true
	var payload := BattleSave.capture(c, [], BotSkill.Level.REGULAR, -1, [])
	var restored := BattleSave.restore(payload, db, terrain())
	check(not restored.is_empty(), "asset battle should restore")
	if restored.is_empty():
		return
	var v: Unit = restored["controller"].state.unit_by_id(99)
	check(v != null and v.asset != null, "asset card restored")
	if v == null or v.asset == null:
		return
	check_eq(v.asset.check, 5)
	check_eq(v.asset.damage, 3)
	check_eq(v.asset.carried_by, 2)
	check_eq(v.asset.altitude, 1)
	check_eq(v.asset.card.short_range, def.asset.short_range)
	check_eq(v.asset.card.special("APC"), 2)
	check_eq(v.weapons[0].def.id, "asset_attack")
	check_eq(v.weapons[0].def.damage, 3)
	check(v.weapons[0].fired, "generated asset weapon firing state persisted")


func test_vehicle_round_trip_keeps_motive_and_crew_damage() -> void:
	var c := _battle()
	var db := designs()
	var def := db.get_def("manticore_heavy_tank")
	var tank := Unit.new(98, def, 0, hex_at(1, 0), 0)
	c.state.add_unit(tank)
	tank.vehicle.cruise_lost = 1
	tank.vehicle.turret_locked = true
	tank.vehicle.crew_stunned = 2
	tank.armor[VehicleLoc.TURRET] = 3
	var payload := BattleSave.capture(c, [], BotSkill.Level.REGULAR, -1, [])
	var restored := BattleSave.restore(payload, db, terrain())
	check(not restored.is_empty(), "vehicle battle should restore")
	if restored.is_empty():
		return
	var v: Unit = restored["controller"].state.unit_by_id(98)
	check(v != null and v.vehicle != null, "vehicle state restored")
	if v == null or v.vehicle == null:
		return
	check_eq(v.vehicle.cruise_lost, 1)
	check(v.vehicle.turret_locked, "turret lock persisted")
	check_eq(v.vehicle.crew_stunned, 2)
	check_eq(v.vehicle.spec.cruise_mp, def.vehicle.cruise_mp)
	check(v.vehicle.spec.turret, "turret spec persisted")
	check_eq(v.armor[VehicleLoc.TURRET], 3)
	check(v.weapons[0].on_vehicle and v.weapons[0].label().contains("("), "vehicle weapon label")
	check(not v.weapons[0].label().contains("(HD"), "vehicle weapon uses vehicle location codes")


func test_delta_frames_round_trip_and_legacy_restore() -> void:
	var c := _battle()
	var recorder := BattleRecorder.new()
	recorder.begin(c.state)
	var u := c.state.unit_by_id(2)
	for i in 36:
		u.heat = i
		if i == 12:
			c.state.map.get_tile(hex_at(1, 1)).on_fire = true
		recorder.record(GameEvent.new(GameEvent.DAMAGE, {"unit_id": u.id}), c.state, "Hit")
	var encoded := BattleFrameStorage.encode(recorder.frames)
	check(encoded[1].has("state_delta"), "ordinary frame is a delta")
	check(not encoded[1]["state_delta"].has("map"), "unchanged map is not stored again")
	check(encoded[13]["state_delta"].has("map"), "changed terrain is stored")
	check(encoded[32].has("state"), "periodic checkpoint")
	var decoded := BattleFrameStorage.decode(encoded)
	check_eq(decoded, recorder.frames, "lossless random access")
	for i in [36, 1, 13, 0, 32]:
		var s := BattleRecorder.state_at(decoded[i], designs(), terrain())
		check_eq(s.unit_by_id(2).heat, 0 if i == 0 else i - 1)
		check_eq(s.map.get_tile(hex_at(1, 1)).on_fire, i >= 13)
	var path := "user://battle_frame_delta_test.zst"
	var payload := BattleSave.capture(c, [], 0, -1, recorder.frames)
	check(BattleSave._write(path, payload))
	var restored := BattleSave._read(path)
	check_eq(restored.get("frames", []), recorder.frames)
	payload["schema"] = 1
	check(not BattleSave.restore(payload, designs(), terrain()).is_empty(), "legacy save remains readable")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_undo_capture_does_not_gain_later_ledger_events() -> void:
	var c := _battle()
	var recorder := BattleRecorder.new()
	recorder.begin(c.state)
	var payload := BattleSave.capture(c, [], 0, -1, recorder.frames)
	recorder.record(GameEvent.new(GameEvent.INTENT, {"text": "later"}), c.state, "Later")
	check_eq(payload["frames"][0]["events"].size(), 0)
	check_eq(recorder.frames[0]["events"].size(), 1)
