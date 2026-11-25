class_name CampaignLaunch
extends RefCounted
## Sets up a contract's battle: up to a lance of the company's ready 'Mechs
## against official designs sized to the contract's share of their BV, on
## a random generated map, with the contract's standard mission (Forced
## Withdrawal on, so crippled 'Mechs count), chosen options and the
## company's formation.

const LANCE := 4


## The battle, or null when nothing can fight. Saves the deployment.
static func build(c: Campaign, db: UnitDb, rng: RandomNumberGenerator,
		k: Contract = null, chaos: ChaosRules = null) -> GameState:
	var ids: Array = []
	for m in c.ready_mechs():
		if ids.size() < LANCE:
			ids.append(m.id)
	if ids.is_empty():
		return null
	var fb := ForceBuilder.new(db, ForceBuilder.BUDGETS.back())
	fb.commanders = true
	for d in CampaignBattle.designs(c, ids):
		fb.add(0, d)
	var percent := k.enemy_percent if k != null else 100
	for id in EnemyForce.pick(fb, fb.bv(0) * percent / 100, rng):
		fb.add(1, id)
	var dice := Dice.new(rng.randi())
	if k != null:
		fb.mission_id = k.mission_id
		fb.forced_withdrawal = true
		ChaosOptions.before(fb, k.chosen, dice, rng)
	var maps := MapChoice.new()
	maps.index = rng.randi_range(0, maps.themes.size() - 1)
	maps.set_seed(rng.randi_range(1, 99999))
	var state := fb.build(maps.build(), dice)
	if state == null:
		return null
	if k != null and chaos != null:
		ChaosOptions.after(state, k.chosen, chaos)
	var roster := CampaignBattle.prepare(c, state, 0, ids)
	CampaignFormation.apply(c, state)
	CampaignStore.save(c, roster)
	return state
