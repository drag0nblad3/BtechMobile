extends TestCase


func test_surface_reaction_respects_surface_and_action() -> void:
	var dry := TerrainType.new()
	dry.id = "clear"
	var wet := TerrainType.new()
	wet.id = "water"
	wet.is_water = true
	var tile := MapTile.new(Vector2i(1, 2), dry, 0)
	check_eq(UnitView.surface_kind(tile, "step"), "soft_step")
	tile.surface = "snow"
	check_eq(UnitView.surface_kind(tile, "step"), "snow_dust")
	tile.surface = ""
	check_eq(UnitView.surface_kind(tile, "landing"), "landing")
	var river := MapTile.new(Vector2i(1, 2), wet, 0, 1)
	check_eq(UnitView.surface_kind(river, "step"), "splash")
	check_eq(UnitView.surface_kind(river, "landing"), "splash")
	check_eq(UnitView.surface_kind(tile, "jet"), "jumpjet")


func test_surface_particle_profiles_remain_small() -> void:
	for id in ["soft_step", "hard_step", "snow_dust", "splash", "jumpjet", "landing"]:
		var kind: Dictionary = VxBlast.KINDS[id]
		var count := int(kind["fire"]) + int(kind["smoke"]) + int(kind["debris"])
		check(count <= 30, "surface FX stay lightweight: " + id)
