class_name ChaosOptions
extends RefCounted
## Puts a contract's chosen options (Campaign Operations pp. 170-171) on
## the battle. `before` changes the ForceBuilder (extra enemy, weather);
## `after` changes the built units (enemy skills). Bad Weather and Heavy Fog
## use the Core Rulebook's Battlefield Conditions Table and Low Visibility
## instead of Tactical Operations. TODO(rules)


static func before(fb: ForceBuilder, chosen: Array[String], dice: Dice, rng: RandomNumberGenerator) -> void:
	if chosen.has("bad_intel"):
		var pool := EnemyForce.designs(fb.units)
		fb.rosters[1].append(pool[rng.randi_range(0, pool.size() - 1)].id)
	if chosen.has("bad_weather"):
		fb.conditions = ConditionsTable.roll(dice)
	if chosen.has("heavy_fog"):
		if fb.conditions == null or fb.conditions.is_clear():
			fb.conditions = Conditions.new()
		fb.conditions.low_visibility = true


static func after(state: GameState, chosen: Array[String], rules: ChaosRules) -> void:
	var enemy: Array[Unit] = []
	for u in state.all_units():
		if u.side == 1 and not u.is_asset():
			enemy.append(u)
	if chosen.has("bad_intel") and not enemy.is_empty():
		_skill(enemy.back(), rules.skill("veteran"))
	if chosen.has("elites"):
		for i in ceili(enemy.size() / 2.0):
			_skill(enemy[i], rules.skill("elite"))
	if chosen.has("a_cut_above"):
		for u in enemy:
			u.pilot.gunnery = maxi(0, u.pilot.gunnery - 1)
			u.pilot.piloting = maxi(0, u.pilot.piloting - 1)


static func _skill(u: Unit, s: Vector2i) -> void:
	u.pilot.gunnery = s.x
	u.pilot.piloting = s.y
