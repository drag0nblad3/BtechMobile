class_name Salvage
extends RefCounted
## Battlefield salvage (Campaign Operations p. 173): a company that meets
## at least one Objective claims every enemy 'Mech left destroyed or
## crippled on the field. Each joins the roster with its damage and no
## MechWarrior. A 'Mech that withdrew or left the map is gone; one with its
## center torso blown out is beyond repair (TODO(rules): our reading of
## "Truly Destroyed", which is in Strategic Operations).


## Enemy 'Mechs of `side`'s foes that can be salvaged from `state`.
static func wrecks(state: GameState, side: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.all_units():
		if u.side == side or u.is_asset() or u.def.vehicle != null or u.def.battle_armor != null:
			continue
		if state.mission.exited.has(u.id) or u.destroyed_reason in CampaignBattle.LEFT_MAP:
			continue
		if not (u.destroyed or state.mission.is_crippled(u)):
			continue
		if MechCondition.written_off(MechCondition.capture(u)):
			continue
		out.append(u)
	return out


## Adds the salvage to `c` if it met an Objective. Returns report lines.
static func claim(c: Campaign, state: GameState, side: int) -> Array[String]:
	var out: Array[String] = []
	if c.last_met < 1:
		if not wrecks(state, side).is_empty():
			out.append("No salvage: the contract met no objective.")
		return out
	for u in wrecks(state, side):
		var m := c.add_mech(u.def.id)
		m.condition = MechCondition.lasting(u)
		m.salvage = true
		out.append("Salvage: %s %s joins the company%s." % [u.def.name, u.def.model,
				" (knocked out, needs structure repair)" if u.destroyed else ""])
	return out
