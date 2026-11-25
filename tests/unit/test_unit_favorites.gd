extends TestCase
## Preference persistence and stable display ordering without modifying saves.


func test_stable_partition_and_source_indices() -> void:
	var items := ["atlas", "locust", "atlas", "jenner", "raven"]
	var favorites := {"jenner": true, "atlas": true}
	var id_of := func(id: String) -> String: return id
	check_eq(UnitFavorites.indices(items, id_of, favorites), [0, 2, 3, 1, 4])
	check_eq(UnitFavorites.prioritized(items, id_of, favorites), ["atlas", "atlas", "jenner", "locust", "raven"])
	check_eq(items, ["atlas", "locust", "atlas", "jenner", "raven"])
	check_eq(UnitFavorites.indices(items, id_of, {}), [0, 1, 2, 3, 4])
	check_eq(UnitFavorites.prioritized(["locust"], id_of, favorites), ["locust"])


func test_exact_variant_priority() -> void:
	var a := make_def(9, 20)
	a.id = "test_prime"
	var b := make_def(9, 20)
	b.id = "test_a"
	var c := make_def(9, 20)
	c.id = "test_b"
	var variants: Array[UnitDef] = [a, b, c]
	var ordered := UnitFavorites.prioritized(variants, UnitFavorites.design_id, {"test_b": true})
	check_eq(ordered, [c, a, b])
	check_eq(variants, [a, b, c])


func test_preference_round_trip() -> void:
	var path := "user://test_unit_favorites.cfg"
	var favorites := {"atlas_as7d": true, "locust_lct1v": true}
	check_eq(UnitFavorites.write(path, favorites), OK)
	check_eq(UnitFavorites.read(path), favorites)
	favorites.erase("atlas_as7d")
	check_eq(UnitFavorites.write(path, favorites), OK)
	check_eq(UnitFavorites.read(path), favorites)
	DirAccess.remove_absolute(path)
