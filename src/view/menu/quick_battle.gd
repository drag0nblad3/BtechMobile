class_name QuickBattle
extends RefCounted
## One-tap skirmish: two different Inner Sphere starter lances of the same
## BV tier on a random generated map, you against the computer.


## Builds the battle; returns null if no two lances share a tier.
static func build(db: UnitDb, rng: RandomNumberGenerator) -> GameState:
	var picks := pick(rng)
	if picks.is_empty():
		return null
	var fb := ForceBuilder.new(db, ForceBuilder.BUDGETS.back())
	for side in 2:
		for id in picks[side].get("units", []):
			fb.add(side, String(id))
	var need := maxi(fb.bv(0), fb.bv(1))
	for level in ForceBuilder.BUDGETS:
		if level >= need:
			fb.budget = level
			break
	var maps := MapChoice.new()
	maps.index = rng.randi_range(0, maps.themes.size() - 1)
	maps.set_seed(rng.randi_range(1, 99999))
	return fb.build(maps.build())


## Two distinct IS lances with the same recommended BV, or [] if none.
static func pick(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var tiers := {}
	for form in StarterFormations.all():
		if String(form.get("kind", "")) == "lance":
			var bv := int(form.get("recommended_bv", 0))
			if not tiers.has(bv):
				tiers[bv] = []
			tiers[bv].append(form)
	var usable: Array = tiers.keys().filter(func(k: int) -> bool: return tiers[k].size() >= 2)
	if usable.is_empty():
		return []
	var forms: Array = tiers[usable[rng.randi_range(0, usable.size() - 1)]].duplicate()
	var a: Dictionary = forms.pop_at(rng.randi_range(0, forms.size() - 1))
	var b: Dictionary = forms[rng.randi_range(0, forms.size() - 1)]
	var out: Array[Dictionary] = [a, b]
	return out
