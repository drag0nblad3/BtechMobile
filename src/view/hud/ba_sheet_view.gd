class_name BaSheetView
extends RefCounted
## A battle armor squad's live record sheet as rich text: MP, troopers with
## their armor, and the squad's weapons.


static func text(u: Unit) -> String:
	var b := u.def.battle_armor
	var t := "[b]%s[/b]  %s · %d troopers%s\n" % [Names.unit(u), u.def.model, b.troopers,
			" · Clan" if u.def.is_clan() else ""]
	t += "MP %d ground / %d jump · no heat · +%d to hit it\n" % [b.ground_mp, b.jump_mp, BaFire.TARGET_MOD]
	t += "Gunnery %d\n\n[b]Troopers[/b]\n" % u.pilot.gunnery
	for i in u.ba.troopers.size():
		var a: int = u.ba.troopers[i]
		t += ("%d  [color=#ff6060]down[/color]\n" % (i + 1)) if a == BaState.DEAD \
				else "%d  armor %d/%d\n" % [i + 1, a, b.armor]
	t += "\n[b]Squad weapons[/b] (one cluster roll per weapon, a shot per trooper)\n"
	for w in u.weapons:
		var line := "%s · %d×%d · %s" % [w.def.name, w.def.missiles, w.def.damage, w.def.range_text()]
		if w.def.uses_ammo():
			line += " · %d volley%s left" % [u.ammo_for(w.def), "" if u.ammo_for(w.def) == 1 else "s"]
		t += ("[color=#888888][s]%s[/s][/color]\n" % line) if not u.can_fire(w) else line + "\n"
	if b.claw:
		t += "Battle claws (swarm and leg attacks: not in the game yet)\n"
	return t
