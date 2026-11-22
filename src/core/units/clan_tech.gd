class_name ClanTech
extends RefCounted
## Clan construction differences (designs with "tech_base": "clan"). The
## game rules for each part are the same as the Inner Sphere's; what
## changes is size and weight, so a Clan 'Mech carries more:
## - XL engine: 2 slots in each side torso (not 3), so losing one side
##   torso is only 2 engine hits and the 'Mech fights on (XlEngine).
## - Double heat sinks fill 2 slots (not 3).
## - CASE is built into every location for free.
## - Ferro-fibrous armor gives 20% more points per ton (not 12%).
## - A targeting computer weighs 1 t per 5 t of linked weapons (not 4).
## Mixed-tech designs ("clan_parts") take each part's own tech (UnitDef.clan_part).
## TODO(rules): construction data, not in the Core Rulebook (TechManual
## figures, general knowledge).

const XL_SIDE_SLOTS := 2
const IS_XL_SIDE_SLOTS := 3
const DHS_SLOTS := 2
const IS_DHS_SLOTS := 3
const FERRO_MULT := 1.2
const TC_TONS_PER_SLOT := 5.0
const IS_TC_TONS_PER_SLOT := 4.0


static func xl_side_slots(def: UnitDef) -> int:
	return XL_SIDE_SLOTS if def.clan_part("engine") else IS_XL_SIDE_SLOTS


static func dhs_slots(def: UnitDef) -> int:
	return DHS_SLOTS if def.clan_part("heat_sinks") else IS_DHS_SLOTS


static func tc_tons_per_slot(def: UnitDef) -> float:
	return TC_TONS_PER_SLOT if def.clan_part("tc") else IS_TC_TONS_PER_SLOT
