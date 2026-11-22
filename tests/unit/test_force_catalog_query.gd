extends TestCase
## Search is forgiving about case, spaces, model names and weapon names.


func test_find_by_name_and_model() -> void:
	var jenner := designs().get_def("jenner_jr7d")
	check(ForceCatalogQuery.matches(jenner, "jEnNeR"), "case-insensitive name")
	check(ForceCatalogQuery.matches(jenner, "JR7"), "model number")
	check(not ForceCatalogQuery.matches(jenner, "atlas"), "not a different chassis")


func test_find_by_weapon() -> void:
	var atlas := designs().get_def("atlas_as7d")
	check(ForceCatalogQuery.matches(atlas, "ac/20"), "match distinctive weapon")
	check(not ForceCatalogQuery.matches(atlas, "imaginary weapon"), "all terms required")


func test_blank_query_matches() -> void:
	var atlas := designs().get_def("atlas_as7d")
	check(ForceCatalogQuery.matches(atlas, "  "), "empty search shows all designs")
