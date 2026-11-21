class_name MapTheme
extends RefCounted
## A kind of battlefield for MapGenerator, from data/map_themes.json:
## how much of each terrain to lay down and how hilly the ground is.
## Shares are fractions of the whole map unless noted.

const DEFAULT_PATH := "res://data/map_themes.json"

var id: String
var name: String
var blurb: String              ## One line for the start screen.
var levels: Array[float] = []  ## Share of dry land at level 0, 1, 2, ...
var hill_scale := 0.08         ## Noise frequency: higher = smaller, busier hills.
var water := 0.0               ## Lakes and ponds.
var deep := 0.25               ## Share of lake hexes at Depth 2 or more.
var river_chance := 0.0        ## Chance of a river crossing the map.
var river_width := 1
var roads := 0                 ## Roads crossing the map.
var woods := 0.0
var heavy := 0.35              ## Share of woods that are heavy woods.
var woods_scale := 0.18
var rough := 0.0
var rubble := 0.0
var street_every := 0          ## Urban grid: a street every N hexes (0 = none).
var buildings := 0.0           ## Urban: chance per block hex; else share of the map.
var building_mix := {"light": 1.0}  ## Building class -> weight.
var max_height := 2            ## Tallest building, in levels.


static func from_dict(d: Dictionary) -> MapTheme:
	var t := MapTheme.new()
	t.id = d["id"]
	t.name = d.get("name", t.id)
	t.blurb = d.get("blurb", "")
	for v: float in d.get("levels", [1.0]):
		t.levels.append(v)
	t.hill_scale = float(d.get("hill_scale", t.hill_scale))
	t.water = float(d.get("water", 0.0))
	t.deep = float(d.get("deep", t.deep))
	t.river_chance = float(d.get("river_chance", 0.0))
	t.river_width = int(d.get("river_width", 1))
	t.roads = int(d.get("roads", 0))
	t.woods = float(d.get("woods", 0.0))
	t.heavy = float(d.get("heavy", t.heavy))
	t.woods_scale = float(d.get("woods_scale", t.woods_scale))
	t.rough = float(d.get("rough", 0.0))
	t.rubble = float(d.get("rubble", 0.0))
	t.street_every = int(d.get("street_every", 0))
	t.buildings = float(d.get("buildings", 0.0))
	t.building_mix = d.get("building_mix", t.building_mix)
	t.max_height = int(d.get("max_height", t.max_height))
	return t


static func load_all(path: String = DEFAULT_PATH) -> Array[MapTheme]:
	var out: Array[MapTheme] = []
	for d: Dictionary in JsonFile.read(path)["themes"]:
		out.append(from_dict(d))
	return out


static func find(id: String, path: String = DEFAULT_PATH) -> MapTheme:
	for t in load_all(path):
		if t.id == id:
			return t
	return null
