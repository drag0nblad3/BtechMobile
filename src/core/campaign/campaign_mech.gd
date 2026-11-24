class_name CampaignMech
extends RefCounted
## A 'Mech the company owns: an official design, its lasting damage
## (MechCondition) and the MechWarrior assigned to it.

var id := ""
var design := ""  ## UnitDef id.
var condition: Dictionary = {}  ## MechCondition; empty = undamaged.
var pilot_id := ""
var written_off := false


## A battle Unit carrying this 'Mech's damage.
func to_unit(db: UnitDb, unit_id: int, side: int, pilot: Pilot) -> Unit:
	var u := Unit.new(unit_id, db.get_def(design), side, Hex.INVALID, 0, pilot)
	MechCondition.apply(u, condition)
	return u


func damaged() -> bool:
	return not condition.is_empty()


## Ready to take the field: not destroyed or written off, with a pilot.
func can_deploy() -> bool:
	return not written_off and pilot_id != "" and not bool(condition.get("destroyed", false))


func to_dict() -> Dictionary:
	return {"id": id, "design": design, "condition": condition, "pilot": pilot_id,
		"written_off": written_off}


static func from_dict(d: Dictionary) -> CampaignMech:
	var m := CampaignMech.new()
	m.id = String(d.get("id", ""))
	m.design = String(d.get("design", ""))
	m.condition = d.get("condition", {})
	m.pilot_id = String(d.get("pilot", ""))
	m.written_off = bool(d.get("written_off", false))
	return m
