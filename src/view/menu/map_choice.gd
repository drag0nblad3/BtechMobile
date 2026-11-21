class_name MapChoice
extends RefCounted
## The start screen's map pick: a generated theme (with size and seed) or
## one of the hand-made maps in data/maps/. Generated themes come first.

var themes: Array[MapTheme] = MapTheme.load_all()
var files := JsonFile.list_dir("res://data/maps")
var index := 0
var size_index := 1  ## MapGenerator.SIZES: two mapsheets, the standard battlefield.
var seed_value := 0
var _terrain := TerrainDb.load_file()
var _cached: BattleMap = null


func _init() -> void:
	reroll()


func count() -> int:
	return themes.size() + files.size()


func is_generated() -> bool:
	return index < themes.size()


func theme() -> MapTheme:
	return themes[index] if is_generated() else null


func sheets() -> Vector2i:
	return MapGenerator.SIZES[size_index]


func next_map() -> void:
	index = (index + 1) % count()
	_cached = null


func next_size() -> void:
	size_index = (size_index + 1) % MapGenerator.SIZES.size()
	_cached = null


func reroll() -> void:
	set_seed(randi_range(1, 99999))


func set_seed(s: int) -> void:
	seed_value = maxi(1, s)
	_cached = null


## The chosen map, freshly built (a battle changes its tiles).
func build() -> BattleMap:
	if is_generated():
		return MapGenerator.build(theme(), sheets(), seed_value, _terrain)
	return MapLoader.load_file(files[index - themes.size()], _terrain)


## The chosen map for the preview; rebuilt only when the choice changes.
func preview() -> BattleMap:
	if _cached == null:
		_cached = build()
	return _cached


## Start-screen lines: name, size and seed; the theme's blurb and the
## terrain mix when explanations are on.
func describe(level: int) -> String:
	var m := preview()
	var text := ""
	if is_generated():
		text = "%s (generated), %s, seed %d" % [theme().name, MapGenerator.size_name(sheets()), seed_value]
	else:
		text = "%s (%d×%d hexes)" % [m.name, m.width, m.height]
	if level != ExplainLevel.OFF:
		text += "\nTerrain: " + MapStats.new(m).summary()
	if level == ExplainLevel.FULL and is_generated():
		text += "\n" + theme().blurb
	return text
