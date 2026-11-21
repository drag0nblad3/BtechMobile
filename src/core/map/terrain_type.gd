class_name TerrainType
extends RefCounted
## Static terrain definition, loaded from data/terrain.json.

var id: String
var token: String          ## Single character used in map files.
var name: String
var move_cost: int         ## Extra MP to enter, on top of the base 1.
var los_height: int        ## Levels added above the ground for line of sight.
var is_water: bool
var flammable: bool          ## Can be set on fire (woods; WoodsFire).
var top_color: Color
var detail_color: Color
var pattern: String        ## Ground look for the view: grass, rocks, paving, rubble, riverbed, forest.


static func from_dict(d: Dictionary) -> TerrainType:
	var t := TerrainType.new()
	t.id = d["id"]
	t.token = d["token"]
	t.name = d["name"]
	t.move_cost = int(d.get("move_cost", 0))
	t.los_height = int(d.get("los_height", 0))
	t.is_water = bool(d.get("water", false))
	t.flammable = bool(d.get("flammable", false))
	t.top_color = Color(d.get("color", "#808080"))
	t.detail_color = Color(d.get("detail_color", "#606060"))
	t.pattern = d.get("pattern", "grass")
	return t
