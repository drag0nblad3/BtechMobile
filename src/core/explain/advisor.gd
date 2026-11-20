class_name Advisor
extends RefCounted
## Advice for the choice in front of the player: what a move, volley or
## physical attack does to the odds, and why one option beats another.
## FULL explains, LIGHT gives the key numbers, OFF returns "".


## Average damage a weapon deals per shot taken (hit chance x damage).
static func expected_damage(w: WeaponDef, th: ToHit) -> float:
	var per_hit := ClusterTable.expected(w.missiles) * w.damage if w.is_cluster() else float(w.damage)
	return th.chance() * per_hit


## Previewed move: own penalty, defensive bonus, heat, cover.
static func move(state: GameState, u: Unit, mode: int, key: Vector3i, opts: MoveOptions,
		level: int) -> String:
	if level == ExplainLevel.OFF:
		return ""
	var path := opts.path_to(key)
	var jump := mode == MoveMode.Kind.JUMP
	var hexes := Hex.distance(u.coord, MoveOptions.coord_of(key)) if jump \
			else MoveOptions.hexes_entered(path, u.coord)
	var moved: bool = opts.cost.get(key, 0) > 0
	var own := MoveMode.attacker_mod(mode) if moved else 0
	var tm := ToHitCalc.target_movement_mod(hexes, jump and moved)
	var heat := MoveMode.heat(mode, hexes) if moved else 0
	var tile := state.map.get_tile(MoveOptions.coord_of(key))
	var cover := LineOfSight.woods_value(tile) if tile else 0
	if tile and tile.is_water() and tile.depth == 1:
		cover += 1
	if level == ExplainLevel.LIGHT:
		return "Your shots +%d · enemy shots +%d · heat +%d" % [own, tm + cover, heat]
	var t := "Moving %d hexes: enemies get +%d to hit you" % [hexes, tm]
	t += (", +%d more from cover here." % cover) if cover > 0 else "."
	t += " Your own shots get +%d and you build %d heat." % [own, heat]
	if mode == MoveMode.Kind.RUN and moved:
		var walk_tm := ToHitCalc.target_movement_mod(mini(hexes, u.walk_mp()))
		if tm <= walk_tm:
			t += " Running here gains no defense over walking but costs +1 to your aim and 1 heat: walk instead."
		else:
			t += " Running buys +%d defense over walking, for +1 to your aim and 1 heat." % (tm - walk_tm)
	if jump and moved:
		t += " Jumping ignores terrain and lets you land behind enemies, but it is the worst for your own aim (+3) and the hottest."
	var rear := _rear_shots(state, u, MoveOptions.coord_of(key), key.z)
	if rear != "":
		t += " " + rear
	return t


## Mentions enemies whose rear or side this position would face.
static func _rear_shots(state: GameState, u: Unit, c: Vector2i, facing: int) -> String:
	for e in state.units:
		if e.side == u.side or e.destroyed:
			continue
		var arc_id := FiringArc.arc(e.coord, e.facing, c)
		if arc_id == FiringArc.REAR and Hex.distance(c, e.coord) <= 9:
			return "You'd be behind %s: shots there hit its thin rear armor." % Names.unit(e)
		if FiringArc.arc(c, facing, e.coord) == FiringArc.REAR:
			return "%s would be behind you, where only rear-mounted weapons can fire." % Names.unit(e)
	return ""


## Volley about to be declared: expected damage and heat consequences.
## shots: [{weapon: index, target_id}].
static func volley(state: GameState, u: Unit, shots: Array, level: int) -> String:
	if level == ExplainLevel.OFF:
		return ""
	var exp_dmg := 0.0
	var idx := []
	var worst := -1
	var worst_ratio := INF
	var primary := -1
	for sh: Dictionary in shots:
		var t := state.unit_by_id(int(sh["target_id"]))
		if primary < 0:
			primary = t.id
		var w := u.weapons[int(sh["weapon"])]
		var th := ToHitCalc.weapon(state, u, w, t, t.id != primary)
		if not th.possible():
			continue
		var ed := expected_damage(w.def, th)
		exp_dmg += ed
		idx.append(int(sh["weapon"]))
		if w.def.heat > 0 and ed / w.def.heat < worst_ratio:
			worst_ratio = ed / w.def.heat
			worst = int(sh["weapon"])
	var after := projected_heat(u, FireOptions.volley_heat(u, idx))
	var eff := HeatScale.effects_text(after)
	if level == ExplainLevel.LIGHT:
		return "Expected %.1f damage · heat next turn %d (%s)" % [exp_dmg, after, eff]
	var t := "On average this volley deals %.1f damage. Heat after this turn: %d (%s)." % [exp_dmg, after, eff]
	if after >= 5 and worst >= 0:
		var w := u.weapons[worst]
		var without := projected_heat(u, FireOptions.volley_heat(u, idx) - w.def.heat)
		t += " Holding the %s (worst damage per heat) would leave %d heat: %s." % [
				w.def.name, without, HeatScale.effects_text(without)]
	elif after == 0 and idx.size() < u.weapons.size():
		t += " You have heat to spare: firing more weapons costs nothing next turn."
	return t


## Heat at the end of this turn if the given weapon heat is added.
static func projected_heat(u: Unit, weapon_heat: int) -> int:
	var gained := u.heat_generated + weapon_heat + HeatPhase.ENGINE_HIT_HEAT * u.engine_hits
	return maxi(0, u.heat + gained - u.working_heat_sinks())


## Which enemy is the best target, by expected damage of everything that can fire.
static func targets(state: GameState, u: Unit, level: int) -> String:
	if level == ExplainLevel.OFF:
		return ""
	var ranked := []
	for e in state.units:
		if e.side == u.side or e.destroyed:
			continue
		var total := 0.0
		for o in FireOptions.for_target(state, u, e):
			if o["to_hit"].possible():
				total += expected_damage(o["weapon"].def, o["to_hit"])
		ranked.append([total, e])
	ranked.sort_custom(func(a, b): return a[0] > b[0])
	if ranked.is_empty() or ranked[0][0] <= 0.0:
		return "No enemy is in range and sight of any weapon." if level == ExplainLevel.FULL else "No shots"
	var parts: Array[String] = []
	for r in ranked:
		parts.append("%s %.1f" % [Names.unit(r[1]), r[0]])
	if level == ExplainLevel.LIGHT:
		return "Expected damage: " + ", ".join(parts)
	return "Best target: %s. Expected damage with everything that can fire: %s. Range, cover and how far each enemy moved make the difference." % [
			Names.unit(ranked[0][1]), ", ".join(parts)]


## Punch vs kick against an adjacent enemy.
static func physical(state: GameState, u: Unit, t: Unit, level: int) -> String:
	if level == ExplainLevel.OFF:
		return ""
	var punch := 0.0
	var kick := 0.0
	var kick_th: ToHit = null
	for o in PhysicalOptions.for_target(state, u, t):
		var th: ToHit = o["to_hit"]
		if not th.possible():
			continue
		if o["kind"] == "punch":
			punch += th.chance() * o["damage"]
		else:
			kick = maxf(kick, th.chance() * o["damage"])
			kick_th = th
	if punch == 0.0 and kick == 0.0:
		return "No punch or kick is possible against %s." % Names.unit(t)
	if level == ExplainLevel.LIGHT:
		return "Punches avg %.1f · kick avg %.1f" % [punch, kick]
	var t2 := "Both punches average %.1f damage; a kick averages %.1f." % [punch, kick]
	if kick_th != null:
		var fall := 1.0 - Dice.chance_2d6(Psr.standing_mods(u).target())
		t2 += " A kick also forces %s to roll or fall, but if it misses you roll too (%s chance you fall)." % [
				Names.unit(t), Names.pct((1.0 - kick_th.chance()) * fall)]
	return t2
