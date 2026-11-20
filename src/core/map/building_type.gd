class_name BuildingType
extends RefCounted
## Static building class (light, medium, heavy, hardened) from data/terrain.json.

var id: String
var name: String
var cf: int          ## Construction factor: damage it takes to bring it down.
var move_cost: int   ## Extra MP for a 'Mech to enter.
var psr_mod: int     ## Piloting roll modifier to push through without harm.
var color: Color


static func from_dict(d: Dictionary) -> BuildingType:
	var b := BuildingType.new()
	b.id = d["id"]
	b.name = d["name"]
	b.cf = int(d["cf"])
	b.move_cost = int(d.get("move_cost", 1))
	b.psr_mod = int(d.get("psr_mod", 0))
	b.color = Color(d.get("color", "#8a8478"))
	return b
