class_name VolleyForecast
extends RefCounted
## Nominal weapon forecast using current declarations, not a simulated roll.
## Ammo is budgeted across weapons sharing the same ammunition type.
static func estimate(state: GameState, u: Unit, shots: Array) -> Dictionary:
	var damage := 0.0
	var hit_count := 0.0
	var all_miss := 1.0
	var heat := 0
	var ammo := 0
	var remaining := {}
	var primary := FireOptions.primary_target(state, u, shots)
	for sh: Dictionary in shots:
		var wi := int(sh["weapon"])
		if wi < 0 or wi >= u.weapons.size():
			continue
		var w := u.weapons[wi]
		var th: ToHit
		if sh.has("hex"):
			th = BuildingFire.to_hit(state, u, w, sh["hex"])
		else:
			var target := state.unit_by_id(int(sh["target_id"]))
			if target == null:
				continue
			th = ToHitCalc.weapon(state, u, w, target, target.id != primary)
			if sh.has("aim") and th.possible() and AimedShot.problem(state, w, target, int(sh["aim"]), th) == "":
				AimedShot.adjust(th, int(sh["aim"]), w)
		if not th.possible():
			continue
		var n := WeaponModes.shots(w)
		var requested := n
		if w.def.uses_ammo():
			var kind := WeaponModes.ammo_kind(w)
			var key := w.def.id + ":" + kind
			n = mini(n, int(remaining.get(key, u.ammo_for(w.def, kind))))
			remaining[key] = int(remaining.get(key, u.ammo_for(w.def, kind))) - n
			ammo += n
		if n == 0:
			continue
		damage += Advisor.expected_damage(w, th) * float(n) / float(maxi(1, requested))
		hit_count += th.chance()
		all_miss *= 1.0 - th.chance()
		heat += w.def.heat * n
		if w.cap_charged:
			heat += PpcCapacitor.HEAT
			damage += th.chance() * PpcCapacitor.DAMAGE
	return {"damage": damage, "hits": hit_count, "any_hit": 1.0 - all_miss, "ammo": ammo, "heat": heat, "after": Advisor.projected_heat(u, heat)}


static func summary(state: GameState, u: Unit, shots: Array) -> String:
	var f := estimate(state, u, shots)
	return "VOLLEY FORECAST  •  %.1f avg damage  •  %.1f expected hits  •  %d%% any hit\nUp to %d ammo shots  •  +%d weapon heat  •  approx %d end heat\nNominal estimates before armor, special effects and later events." % [f["damage"], f["hits"], roundi(f["any_hit"] * 100), f["ammo"], f["heat"], f["after"]]
