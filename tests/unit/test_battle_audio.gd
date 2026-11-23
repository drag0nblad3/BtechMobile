extends TestCase
## Event routing and settings for non-authoritative, pooled battle sounds.


func test_weapon_categories_and_special_events() -> void:
	for spec in [{"id":"large_laser","want":"energy"},
			{"id":"ac20","want":"ballistic"}, {"id":"gauss_rifle","want":"gauss"},
			{"id":"lrm15","want":"missile"}, {"id":"flamer","want":"flamer"}]:
		var e := GameEvent.new(GameEvent.WEAPON_FIRED, {"weapon_id": spec["id"], "hit": true})
		check_eq(BattleAudioCues.of(e), spec["want"])
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.AMMO_EXPLOSION)), "ammo")
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.CRITICAL)), "critical")
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.UNIT_DESTROYED)), "kill")
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.FALL)), "fall")
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.SHUTDOWN, {"shutdown": true})), "shutdown")
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.HEAT, {"heat": 14})), "heat")
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.BUILDING, {"kind": "collapsed"})), "collapse")


func test_no_ammo_never_plays_weapon_and_tonnage_changes_footsteps() -> void:
	var e := GameEvent.new(GameEvent.WEAPON_FIRED, {"weapon_id": "lrm20", "no_ammo": true})
	check_eq(BattleAudioCues.of(e), "")
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.UNIT_MOVED,
			{"mode": MoveMode.Kind.JUMP})), "jump")
	check(BattleAudioCues.pitch("step", 100) < BattleAudioCues.pitch("step", 20),
			"heavy steps should sound lower than light steps")
	check_eq(BattleAudioCues.of(GameEvent.new(GameEvent.HEAT, {"heat": 8})), "")


func test_mute_and_volumes_do_not_change_rules() -> void:
	var old := [GameSettings.sound_master, GameSettings.sound_effects,
			GameSettings.sound_ui, GameSettings.sound_muted]
	GameSettings.set_sound_master(1.5)
	check_eq(GameSettings.sound_master, 1.0)
	GameSettings.set_sound_effects(-1.0)
	check_eq(GameSettings.sound_effects, 0.0)
	GameSettings.set_sound_ui(0.5)
	check_eq(GameSettings.sound_ui, 0.5)
	GameSettings.set_sound_muted(true)
	check(GameSettings.sound_muted, "mute must persist in GameSettings")
	GameSettings.set_sound_master(old[0])
	GameSettings.set_sound_effects(old[1])
	GameSettings.set_sound_ui(old[2])
	GameSettings.set_sound_muted(old[3])
