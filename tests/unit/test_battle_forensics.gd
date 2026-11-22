extends TestCase
## Forensic analysis uses only actual event facts; probabilities use 2d6.

func test_exact_two_d6_chances() -> void:
	check_eq(BattleForensics.chance_to_hit(2), 1.0)
	check_eq(BattleForensics.chance_to_hit(7), 21.0 / 36.0)
	check_eq(BattleForensics.chance_to_hit(12), 1.0 / 36.0)
	check_eq(BattleForensics.chance_to_hit(13), 0.0)


func test_ledger_reports_hits_damage_heat_and_moments() -> void:
	var events := [
		{"turn": 1, "event": GameEvent.WEAPON_FIRED, "text": "Atlas hits Jenner",
				"data": {"attacker_id": 1, "target_id": 2, "roll": 8, "need": 7, "hit": true}},
		{"turn": 1, "event": GameEvent.DAMAGE, "text": "Jenner takes 16 damage",
				"data": {"unit_id": 2, "source_id": 1, "amount": 16}},
		{"turn": 1, "event": GameEvent.HEAT, "text": "Atlas at 16 heat",
				"data": {"unit_id": 1, "heat": 16}},
		{"turn": 1, "event": GameEvent.PSR, "text": "Jenner falls to a failed PSR",
				"data": {"unit_id": 2, "ok": false}},
		{"turn": 1, "event": GameEvent.WEAPON_FIRED, "text": "Atlas misses easy shot",
				"data": {"attacker_id": 1, "target_id": 2, "roll": 3, "need": 4, "hit": false}},
		{"turn": 1, "event": GameEvent.UNIT_DESTROYED, "text": "Jenner destroyed",
				"data": {"unit_id": 2}},
	]
	var frames := [{"turn": 1, "event": "deployment", "events": events},
			{"turn": 1, "event": "damage", "events": []}]
	var report := BattleForensics.analyze(frames, {
			"1": {"name": "Atlas", "side": 0},
			"2": {"name": "Jenner", "side": 1}})
	var summary: Dictionary = report["summary"]
	check_eq(summary["attacks"], 2)
	check_eq(summary["hits"], 1)
	check_eq(summary["damage"], 16)
	check_eq(summary["kills"], 1)
	check_eq(summary["psr_failures"], 1)
	check_eq(summary["events"], 6)
	check_eq(report["units"][0]["name"], "Atlas")
	check_eq(report["units"][0]["damage_dealt"], 16)
	check_eq(report["units"][0]["heat_peak"], 16)
	check_eq(report["units"][1]["damage_taken"], 16)
	check_eq(report["units"][1]["psr_failures"], 1)
	check(report["moments"].size() >= 4)
	check_eq(report["timeline"][0]["frame"], 1)


func test_codec_packed_event_data_is_readable() -> void:
	var raw := {"attacker_id": 4, "target_id": 9, "roll": 10,
			"need": 11, "hit": false, "hex": Vector2i(3, 7)}
	var frames := [{"turn": 2, "event": "weapon_fired", "events": [
			{"turn": 2, "event": GameEvent.WEAPON_FIRED,
					"data": BattleCodec.pack(raw), "text": "Miss"}]}]
	var report := BattleForensics.analyze(frames)
	check_eq(report["summary"]["attacks"], 1)
	check_eq(report["summary"]["hits"], 0)
	check_eq(report["units"][0]["id"], 4)


func test_legacy_replay_without_ledger_does_not_invent_statistics() -> void:
	var report := BattleForensics.analyze([{"turn": 1, "event": "deployment"}])
	check_eq(report["summary"]["events"], 0)
	check_eq(report["summary"]["attacks"], 0)
	check_eq(report["moments"].size(), 0)
