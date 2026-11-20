class_name UnitDef
extends RefCounted
## Static unit design (one variant), loaded from data/units/<id>.json.
## Armor, internals, weapons and heat sinks get added here as the
## combat modules land; keep this class data-only.

var id: String
var name: String      ## e.g. "Atlas"
var model: String     ## e.g. "AS7-D"
var tonnage: int
var walk_mp: int
var jump_mp: int


static func from_dict(d: Dictionary) -> UnitDef:
	var u := UnitDef.new()
	u.id = d["id"]
	u.name = d["name"]
	u.model = d.get("model", "")
	u.tonnage = int(d["tonnage"])
	u.walk_mp = int(d["walk_mp"])
	u.jump_mp = int(d.get("jump_mp", 0))
	return u


## Running MP = walking MP x 1.5, rounded up.
func run_mp() -> int:
	return ceili(walk_mp * 1.5)


func display_name() -> String:
	return ("%s %s" % [name, model]).strip_edges()
