extends TestCase
## The Clan roster: OmniMech configurations built from Clan parts only.

const CHASSIS := ["fire_moth", "kit_fox", "adder", "viper", "ice_ferret", "nova", "stormcrow",
		"mad_dog", "hellbringer", "summoner", "timber_wolf", "gargoyle", "warhawk", "turkina", "dire_wolf",
		"mist_lynx", "crossbow", "grendel", "linebacker", "night_gyr", "shadow_cat", "executioner"]


func test_roster() -> void:
	var db := UnitDb.load_dir()
	var tw := db.get_def("timber_wolf_prime")
	check(tw != null and tw.omni and tw.is_clan(), "Timber Wolf Prime")
	check_eq(tw.display_name(), "Timber Wolf Prime")
	check(db.get_def("mad_dog_prime") != null, "Mad Dog Prime")
	var seen := {}
	for def: UnitDef in db.by_id.values():
		if not def.is_clan():
			continue
		seen[def.chassis] = true
		check(def.omni == (def.config != ""), def.id + " OmniMechs name their configuration")
		for m in def.weapon_mounts:
			check((m["weapon"] as WeaponDef).is_clan(), "%s carries Clan %s" % [def.id, m["weapon"].name])
	for c: String in CHASSIS:
		check(seen.has(c), c)
	for id: String in ["hunchback_iic", "phoenix_hawk_iic", "rifleman_iic", "warhammer_iic", "marauder_iic", "kodiak"]:
		var d := db.get_def(id)
		check(d != null and d.is_clan() and not d.omni, id + ": a Clan 'Mech that isn't an OmniMech")
	check(db.by_id.values().any(func(d: UnitDef) -> bool: return d.weapon_mounts.any(func(m: Dictionary) -> bool: return m["weapon"].artemis_builtin)), "an ATM user")


func test_clan_heavies_outclass_inner_sphere_peers() -> void:
	var db := UnitDb.load_dir()
	check(BattleValue.of(db.get_def("timber_wolf_prime")) > BattleValue.of(db.get_def("marauder_mad3r")) * 1.3,
			"same weight class, much more Battle Value")


func test_bots_fight_a_clan_battle() -> void:
	var db := UnitDb.load_dir()
	var fb := ForceBuilder.new(db, 8000)
	fb.add(0, "timber_wolf_prime")
	fb.add(0, "kit_fox_prime")
	fb.add(1, "atlas_as7d")
	fb.add(1, "marauder_mad3r")
	var gc := GameController.new(fb.build(MapLoader.load_file("res://data/maps/river_crossing.json", terrain())), 5)
	gc.start_turn()
	var guard := 0
	while not gc.state.game_over and gc.state.turn <= 8 and guard < 2000:
		guard += 1
		if not Bot.act(gc, gc.state.active_side()):
			break
	check(gc.state.turn > 2, "played several turns")
	var fired := gc.history.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.WEAPON_FIRED)
	check(not fired.is_empty(), "shots were fired")


func test_masc_mechs() -> void:
	var db := UnitDb.load_dir()
	for id: String in ["shadow_cat_prime", "shadow_cat_a", "executioner_prime", "executioner_a"]:
		var d := db.get_def(id)
		check(d != null and d.masc_loc >= 0, id + " has MASC")
	check_eq(Masc.size(db.get_def("executioner_prime")), 4, "95 t Clan: 95 / 25 rounds to 4")
