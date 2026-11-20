class_name BuildingType
extends RefCounted
## Static building class from data/terrain.json (book p. 131): civilian,
## light, medium, heavy, hardened. Damage of at least `threshold` from one
## attacker in a phase earns a Destroy Check against `destroy_tn`.

var id: String
var name: String
var civilian: bool = false  ## Any damage, or a 'Mech walking in, flattens it.
var threshold: int = 0
var destroy_tn: int = 0
var entry_class: int = 0    ## Lightest weight class that may force its way in (0 light .. 3 assault).
var color: Color


static func from_dict(d: Dictionary) -> BuildingType:
	var b := BuildingType.new()
	b.id = d["id"]
	b.name = d["name"]
	b.civilian = bool(d.get("civilian", false))
	b.threshold = int(d.get("threshold", 0))
	b.destroy_tn = int(d.get("destroy_tn", 0))
	b.entry_class = int(d.get("entry_class", 0))
	b.color = Color(d.get("color", "#8a8478"))
	return b
