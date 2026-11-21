class_name RecordSheetView
extends RefCounted
## A live record sheet for one Unit, as rich text: movement, heat, pilot,
## armor and structure per location, weapons, and critical damage.


## `on_power(want)`: if given, a button to shut down or restart by choice.
static func build(u: Unit, on_power: Callable = Callable()) -> Control:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("normal_font_size", 19)
	l.add_theme_font_size_override("bold_font_size", 21)
	l.text = text(u)
	var want := power_choice(u)
	if not on_power.is_valid() or want[0] == null:
		return l
	var box := VBoxContainer.new()
	box.add_child(l)
	var b := Button.new()
	b.text = want[1]
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func() -> void: on_power.call(want[0]))
	box.add_child(b)
	return box


## [request to send, button text], or [null, ""] when there's nothing to offer.
static func power_choice(u: Unit) -> Array:
	if u.destroyed or (u.shutdown and not u.voluntary_shutdown):
		return [null, ""]
	if u.power_request != "":
		return ["", "Cancel: stay %s" % ("shut down" if u.shutdown else "powered up")]
	if u.shutdown:
		return [VoluntaryShutdown.ON, "Restart at the Heat Phase"]
	return [VoluntaryShutdown.OFF, "Shut down at the Heat Phase (sheds heat, can't act)"]


static func text(u: Unit) -> String:
	var d := u.def
	var t := "[b]%s[/b]  %s · %d t %s\n" % [Names.unit(u), d.model, d.tonnage, d.weight_class()]
	t += "MP %d walk / %d run (base %d/%d)\n" % [u.walk_mp(), u.run_mp(), d.walk_mp, d.run_mp()]
	t += "Heat [color=%s]%d[/color] / 30: %s\n" % [_heat_color(u.heat), u.heat, HeatScale.effects_text(u.heat)]
	t += "Heat sinks %d of %d%s\n" % [u.working_heat_sinks(), d.heat_sinks,
			" double (%d heat)" % u.dissipation() if d.double_heat_sinks else ""]
	var tech: Array[String] = []
	if d.is_xl():
		tech.append("XL engine (dies if a side torso is lost)")
	if d.structure_type == "endo_steel":
		tech.append("endo steel structure")
	if d.ecm_loc >= 0:
		tech.append("Guardian ECM%s" % (" (destroyed)" if u.ecm_lost else ""))
	if d.tc_loc >= 0:
		tech.append("targeting computer%s" % (" (destroyed)" if u.tc_lost else ""))
	if d.armor_type == "ferro_fibrous":
		tech.append("ferro-fibrous armor")
	for p: Dictionary in u.narc_pods:
		if not u.is_location_destroyed(p["loc"]):
			tech.append("Narc pod on its %s (%s)" % [Location.code(p["loc"]), Names.side(p["side"])])
	if not tech.is_empty():
		t += ", ".join(tech) + "\n"
	t += "MechWarrior: gunnery %d, piloting %d, hits %d/6%s\n" % [u.pilot.gunnery,
			u.pilot.piloting, u.pilot.hits, "" if u.pilot.conscious else " (unconscious)"]
	var cond: Array[String] = []
	if u.destroyed:
		cond.append("[color=#ff6060]DESTROYED: %s[/color]" % u.destroyed_reason)
	if u.prone:
		cond.append("prone")
	if u.shutdown:
		cond.append("shut down")
	for i in d.melee.size():
		cond.append("%s (%s)%s" % [d.melee[i]["kind"], Location.code(d.melee[i]["loc"]), " destroyed" if u.melee_lost.has(i) else ""])
	if u.club != "":
		cond.append("holding a %s club" % u.club)
	for pair in [[u.engine_hits, "engine hits"], [u.gyro_hits, "gyro hits"], [u.sensor_hits, "sensor hits"]]:
		if pair[0] > 0:
			cond.append("%d %s" % pair)
	if not cond.is_empty():
		t += ", ".join(cond) + "\n"
	t += "\n[b]Armor / structure[/b]\n"
	for loc in Location.COUNT:
		t += _loc_line(u, loc)
	t += "\n[b]Weapons[/b]  (heat · damage · range)\n"
	for w in u.weapons:
		t += _weapon_line(u, w)
	var crits := _crits(u)
	if crits != "":
		t += "\n[b]Critical damage[/b]\n" + crits
	return t


static func _loc_line(u: Unit, loc: int) -> String:
	var d := u.def
	if u.is_location_destroyed(loc):
		return "%s  [color=#ff6060]destroyed[/color]\n" % Location.code(loc)
	var a := "%d/%d" % [u.armor[loc], d.armor[loc]]
	if Location.HAS_REAR.has(loc):
		a += "  rear %d/%d" % [u.rear_armor[loc], d.rear_armor[loc]]
	var full := StructureTable.points(d.tonnage, loc)
	var s := "%d/%d" % [u.structure[loc], full]
	var col := "#ffffff" if u.structure[loc] == full else "#ffb040"
	var wet := "  [color=#60b0ff]flooded[/color]" if u.flooded.get(loc, false) else ""
	return "%s  armor %s  ·  [color=%s]structure %s[/color]%s\n" % [Location.code(loc), a, col, s, wet]


static func _weapon_line(u: Unit, w: MountedWeapon) -> String:
	var line := "%s  %d · %s · %s" % [w.label(), w.def.heat,
			("%d×%d" % [w.def.missiles, w.def.damage]) if w.def.is_cluster() else str(w.def.damage),
			w.def.range_text()]
	if w.def.uses_ammo():
		line += " · ammo %d" % u.ammo_for(w.def)
		if w.def.lbx:
			line += " + %d cluster" % u.ammo_for(w.def, WeaponModes.CLUSTER)
	if not u.can_fire(w):
		return "[color=#888888][s]%s[/s][/color]\n" % line
	return line + "\n"


static func _crits(u: Unit) -> String:
	var t := ""
	for loc in Location.COUNT:
		for s: CritSlot in u.slots[loc]:
			if s.hit:
				t += "%s: %s\n" % [Location.code(loc), s.name.replace("_", " ")]
	return t


static func _heat_color(h: int) -> String:
	if h >= 14:
		return "#ff5050"
	if h >= 8:
		return "#ffb040"
	if h >= 5:
		return "#ffe070"
	return "#a0ffa0"
