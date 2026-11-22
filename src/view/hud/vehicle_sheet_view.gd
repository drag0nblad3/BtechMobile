class_name VehicleSheetView
extends RefCounted
## A combat vehicle's live record sheet as rich text: motive and MP, crew,
## armor and structure per location, weapons, and motive or critical damage.


static func text(u: Unit) -> String:
	var d := u.def
	var v := u.vehicle
	var t := "[b]%s[/b]  %s · %d t %s %s%s\n" % [Names.unit(u), d.model, d.tonnage, d.weight_class(),
			d.vehicle.motive_name().to_lower(), " · Clan" if d.is_clan() else ""]
	t += "MP %d cruise / %d flank (base %d/%d) · no heat\n" % [u.walk_mp(), u.run_mp(),
			d.vehicle.cruise_mp, d.vehicle.flank_mp()]
	t += "Crew: gunnery %d, driving %d\n" % [u.pilot.gunnery, u.pilot.piloting]
	t += "\n[b]Armor / structure[/b]\n"
	for loc: int in VehicleLoc.ARMORED:
		if loc != VehicleLoc.TURRET or d.vehicle.turret:
			t += _loc_line(u, loc)
	t += "\n[b]Weapons[/b]\n"
	for w in u.weapons:
		var line := "%s · %s" % [w.label(), w.def.range_text()]
		if w.def.uses_ammo():
			line += " · ammo %d" % u.ammo_for(w.def)
		t += ("[color=#888888][s]%s[/s][/color]\n" % line) if not u.can_fire(w) else line + "\n"
	var dmg := _damage(v)
	if dmg != "":
		t += "\n[b]Vehicle damage[/b]\n" + dmg
	return t


static func _loc_line(u: Unit, loc: int) -> String:
	var code: String = VehicleLoc.CODES[loc]
	if u.structure[loc] <= 0:
		return "%s  [color=#ff6060]destroyed[/color]\n" % code
	var full := VehicleLoc.structure(u.def.tonnage)
	var col := "#ffffff" if u.structure[loc] == full else "#ffb040"
	return "%s  armor %d/%d  ·  [color=%s]structure %d/%d[/color]\n" % [code, u.armor[loc],
			u.def.armor[loc], col, u.structure[loc], full]


static func _damage(v: VehicleState) -> String:
	var out: Array[String] = []
	if v.immobile:
		out.append("immobile")
	if v.cruise_lost > 0:
		out.append("-%d cruise MP" % v.cruise_lost)
	if v.half_cruise:
		out.append("half cruise MP")
	if v.driving_mod > 0:
		out.append("+%d to driving rolls" % v.driving_mod)
	if v.sensor_hits > 0:
		out.append("sensors hit %d (+%d to fire)" % [v.sensor_hits, v.sensor_hits])
	if not v.stabilizers.is_empty():
		out.append("stabilizers hit")
	if v.turret_lost:
		out.append("turret blown off")
	elif v.turret_locked:
		out.append("turret locked")
	if v.crew_stunned > 0:
		out.append("crew stunned (%d turn%s)" % [v.crew_stunned, "" if v.crew_stunned == 1 else "s"])
	if v.commander_hit:
		out.append("commander hit")
	if v.driver_hit:
		out.append("driver hit")
	if v.engine_hit:
		out.append("engine hit")
	return "" if out.is_empty() else ", ".join(out) + "\n"
