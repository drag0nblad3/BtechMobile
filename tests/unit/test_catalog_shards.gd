extends TestCase
## Both legacy fixture dictionaries and sharded catalog arrays must load.

func _write(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		check(false, "Could not create " + path)
		return
	f.store_string(JSON.stringify(data))
	f.close()


func _make_catalog(suffix: String, single: Dictionary, shard: Array) -> String:
	var dir := "user://test_catalog_%s_%d" % [suffix, Time.get_ticks_usec()]
	check_eq(DirAccess.make_dir_recursive_absolute(dir), OK)
	_write(dir.path_join("a_single.json"), single)
	_write(dir.path_join("b_shard.json"), shard)
	return dir


func _cleanup(dir: String) -> void:
	for path in JsonFile.list_dir(dir):
		check_eq(DirAccess.remove_absolute(path), OK)
	check_eq(DirAccess.remove_absolute(dir), OK)


func _mech(id: String) -> Dictionary:
	return {"id": id, "name": id, "tonnage": 50, "walk_mp": 4}


func _vehicle(id: String) -> Dictionary:
	return {"id": id, "name": id, "tonnage": 20,
		"vehicle": {"motive": "h", "cruise_mp": 5}}


func _ba(id: String) -> Dictionary:
	return {"id": id, "name": id, "tonnage": 1,
		"battle_armor": {"troopers": 4, "armor": 3}}


func test_mixed_mech_catalog_and_omni_configurations() -> void:
	var omni := _mech("omni")
	omni["tech_base"] = "clan"
	omni["configs"] = [{"model": "Prime", "bv": 1000},
		{"model": "A", "bv": 1200, "walk_mp": 5}]
	var dir := _make_catalog("mech", _mech("legacy"), [omni, _mech("shard")])
	var db := UnitDb.load_dir(dir)
	check_eq(db.by_id.keys(), ["legacy", "omni_prime", "omni_a", "shard"])
	var prime := db.get_def("omni_prime")
	var config_a := db.get_def("omni_a")
	check(prime != null and config_a != null, "Missing OmniMech configurations")
	if prime != null and config_a != null:
		check_eq(prime.bv, 1000)
		check_eq(prime.chassis, "omni")
		check_eq(config_a.bv, 1200)
		check_eq(config_a.walk_mp, 5)
		check(config_a.omni and config_a.is_clan())
	_cleanup(dir)


func test_mixed_vehicle_catalog() -> void:
	var dir := _make_catalog("vehicle", _vehicle("legacy_v"),
		[_vehicle("shard_v1"), _vehicle("shard_v2")])
	var db := UnitDb.new()
	db.weapons = weapons()
	db.add_vehicles(dir)
	check_eq(db.vehicles.keys(), ["legacy_v", "shard_v1", "shard_v2"])
	var def := db.get_def("shard_v2")
	check(def != null, "Missing vehicle")
	if def != null:
		check_eq(def.vehicle.motive, "h")
		check_eq(def.vehicle.cruise_mp, 5)
	_cleanup(dir)


func test_mixed_battle_armor_catalog() -> void:
	var dir := _make_catalog("ba", _ba("legacy_ba"), [_ba("shard_ba1"), _ba("shard_ba2")])
	var db := UnitDb.new()
	db.weapons = weapons()
	db.add_battle_armor(dir)
	check_eq(db.battle_armor.keys(), ["legacy_ba", "shard_ba1", "shard_ba2"])
	var def := db.get_def("shard_ba2")
	check(def != null, "Missing battle armor")
	if def != null:
		check_eq(def.battle_armor.troopers, 4)
		check_eq(def.battle_armor.armor, 3)
	_cleanup(dir)
