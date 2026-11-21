class_name Atm
extends RefCounted
## Launchers with munitions in their own bins: the MML's SRMs/LRMs (p. 186)
## and Advanced Tactical Missiles (book p. 186, Clan): Artemis IV built in (+2
## on the cluster roll unless hostile ECM jams it), no indirect fire, and
## three munitions, each in its own ammo bins: standard (2 a missile, 4-hex
## minimum range, 5/10/15), extended range (1 a missile, 4-hex minimum,
## 9/18/27) and high explosive (3 a missile, 3/6/9). Hits land in 6-point
## groups (errata v0.2). The firing mode picks the munition.
## TODO(rules): an ammo explosion uses the standard munition's damage.

const ER := "er"
const HE := "he"


## Notes which munitions each launcher has ammo for; starts on one it has.
static func setup_ammo(u: Unit) -> void:
	for w in u.weapons:
		if w.def.munitions.is_empty():
			continue
		w.ammo_kinds.clear()
		for kind: String in [""] + w.def.munitions.keys():
			if u.ammo_for(w.def, kind) > 0:
				w.ammo_kinds.append(kind)
		if not w.ammo_kinds.is_empty() and not w.ammo_kinds.has(""):
			w.mode = w.ammo_kinds[0]


## The stats a shot uses: the loaded munition's, or the launcher's own.
static func profile(w: MountedWeapon) -> WeaponDef:
	return w.def.munitions.get(w.mode, w.def)


static func mode_text(w: MountedWeapon) -> String:
	var p := profile(w)
	var label := p.label if p.label != "" else ("Standard" if w.mode == "" else w.mode.to_upper())
	return "%s missiles (%d each, %s)" % [label, p.damage, p.range_text()]