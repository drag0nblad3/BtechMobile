class_name SpaToHit
extends RefCounted
## To-hit modifiers from Special Pilot Abilities on a ranged weapon attack:
## Sniper (p. 80) halves the range modifier, Multi-Tasker (p. 78) takes 1
## off the secondary-target modifier, Blood Stalker (p. 73) favors its quarry,
## Jumping Jack (p. 76) turns the +3 for jumping into +1, Weapon Specialist
## (p. 82) is -2 with its chosen weapon, Oblique Attacker (p. 78) -1 indirect,
## Range Master (p. 78) swaps its range band's modifier with short range's,
## and a Forest Ranger (p. 81) is harder to hit in woods (TerrainMaster).
## TODO(rules): Sniper with Range Master halves the swapped modifier.
## TODO(rules): Multi-Tasker is written for Total Warfare's +1/+2 secondary
## modifiers; the Core Rulebook's flat +1 becomes +0.


const RANGE_MODS := {"medium": 2, "long": 4}


static func add(th: ToHit, state: GameState, attacker: Unit, w: MountedWeapon, target: Unit, br: int, secondary: bool) -> void:
	if Spa.has(attacker, Spa.SNIPER):
		if br == WeaponDef.Bracket.MEDIUM:
			th.add("Sniper", -1, "Sniper: range modifiers are halved (+1 at medium range).")
		elif br == WeaponDef.Bracket.LONG:
			th.add("Sniper", -2, "Sniper: range modifiers are halved (+2 at long range).")
	if secondary and Spa.has(attacker, Spa.MULTI_TASKER):
		th.add("Multi-Tasker", -1, "Multi-Tasker: secondary targets cost 1 less.")
	BloodStalker.add(th, state, attacker, target, not secondary)
	if attacker.move_mode == MoveMode.Kind.JUMP and Spa.has(attacker, Spa.JUMPING_JACK):
		th.add("Jumping Jack", -2, "Jumping Jack: jumping costs +1 to hit, not +3.")
	if Spa.choice(attacker, Spa.WEAPON_SPECIALIST) == w.def.id:
		th.add("Weapon Specialist", -2, "Weapon Specialist: -2 with the %s." % w.def.name)
	if th.indirect and Spa.has(attacker, Spa.OBLIQUE_ATTACKER):
		th.add("Oblique Attacker", -1, "Oblique Attacker: -1 when firing indirectly.")
	_range_master(th, attacker, br)
	TerrainMaster.add_cover(th, state, target)


static func _range_master(th: ToHit, attacker: Unit, br: int) -> void:
	var band := Spa.choice(attacker, Spa.RANGE_MASTER)
	if not RANGE_MODS.has(band):
		return
	var mod: int = RANGE_MODS[band]
	var chosen := WeaponDef.Bracket.MEDIUM if band == "medium" else WeaponDef.Bracket.LONG
	if br == chosen:
		th.add("Range Master", -mod, "Range Master (%s): this range band counts like short range." % band)
	elif br == WeaponDef.Bracket.SHORT:
		th.add("Range Master", mod, "Range Master (%s): short range takes the %s-range modifier instead." % [band, band])
