class_name CampaignLaunch
extends RefCounted
## Sets up the company's next battle: up to a lance of its ready 'Mechs
## against an Inner Sphere starter lance of the nearest Battle Value, on a
## random generated map. Contracts will replace this simple pick.

const LANCE := 4


## The battle, or null when nothing can fight. Saves the deployment.
static func build(c: Campaign, db: UnitDb, rng: RandomNumberGenerator) -> GameState:
	var ids: Array = []
	for m in c.ready_mechs():
		if ids.size() < LANCE:
			ids.append(m.id)
	if ids.is_empty():
		return null
	var fb := ForceBuilder.new(db, ForceBuilder.BUDGETS.back())
	for d in CampaignBattle.designs(c, ids):
		fb.add(0, d)
	var enemy := enemy_lance(db, fb.bv(0), rng)
	for id: String in enemy:
		fb.add(1, id)
	var maps := MapChoice.new()
	maps.index = rng.randi_range(0, maps.themes.size() - 1)
	maps.set_seed(rng.randi_range(1, 99999))
	var state := fb.build(maps.build())
	if state == null:
		return null
	CampaignStore.save(c, CampaignBattle.prepare(c, state, 0, ids))
	return state


## One of the two Inner Sphere starter lances closest to `bv`.
static func enemy_lance(db: UnitDb, bv: int, rng: RandomNumberGenerator) -> Array:
	var scored: Array = []
	for form in StarterFormations.all():
		if String(form.get("kind", "")) != "lance":
			continue
		var fb := ForceBuilder.new(db, ForceBuilder.BUDGETS.back())
		for id in form.get("units", []):
			fb.add(1, String(id))
		scored.append([absi(fb.bv(1) - bv), form.get("units", [])])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if scored.is_empty():
		return []
	return scored[rng.randi_range(0, mini(1, scored.size() - 1))][1]
