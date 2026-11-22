class_name PpcCapacitor
extends RefCounted
## PPC capacitor (book p. 188), linked to one PPC. Instead of firing the PPC
## a 'Mech may charge the capacitor (weapon mode "charge"); a charged
## capacitor costs 5 heat every turn it is held, and firing the PPC uses the
## charge: +5 damage and +5 heat. A charged PPC can't fire without it.
## A critical hit on the PPC or capacitor while charged is a component
## explosion of 2 per combined slot that wrecks both; a PPC that was declared
## firing this phase doesn't count as charged.
## TODO(rules): starting the game charged; the computer never charges one.
## 1 t and 1 slot are MegaMek construction data.

const CHARGE := "charge"
const HEAT := 5
const DAMAGE := 5
const TONS := 1.0


static func has(w: MountedWeapon) -> bool:
	return w.capacitor and not w.capacitor_lost and not w.destroyed


## Weapon modes: charging is offered only while it's empty.
static func modes(w: MountedWeapon) -> Array[String]:
	var out: Array[String] = [""]
	if has(w) and not w.cap_charged:
		out.append(CHARGE)
	return out


## Firing a charged PPC: uses the charge; returns the extra damage.
static func discharge(attacker: Unit, w: MountedWeapon) -> int:
	if not (has(w) and w.cap_charged):
		return 0
	w.cap_charged = false
	w.cap_released = true
	attacker.heat_generated += HEAT
	return DAMAGE


## End of the weapon phase: capacitors set to charge now hold a charge; every
## held charge adds its heat.
static func end_phase(state: GameState, emit: Callable) -> void:
	for u in state.units:
		if u.destroyed:
			continue
		for i in u.weapons.size():
			var w := u.weapons[i]
			if w.mode == CHARGE:
				w.mode = ""
				if has(w) and not w.fired and not u.shutdown:
					w.cap_charged = true
					emit.call(GameEvent.CAPACITOR, {"unit_id": u.id, "weapon": w.def.name})
			if has(w) and w.cap_charged:
				u.heat_generated += HEAT


## Does a critical hit on this PPC or its capacitor set it off?
static func explodes(state: GameState, u: Unit, w: MountedWeapon) -> bool:
	if not (w.capacitor and w.cap_charged):
		return false
	var i := u.weapons.find(w)
	return not state.declared_fire.any(func(d: Dictionary) -> bool:
			return int(d["attacker_id"]) == u.id and int(d.get("weapon_index", -1)) == i)


static func explode(state: GameState, dice: Dice, emit: Callable, u: Unit, w: MountedWeapon, loc: int) -> void:
	w.cap_charged = false
	w.capacitor_lost = true
	w.destroyed = true
	var i := u.weapons.find(w)
	for l in u.slots.size():
		for s: CritSlot in u.slots[l]:
			if s.ref == i and (s.kind == CritSlot.Kind.WEAPON or s.kind == CritSlot.Kind.CAPACITOR):
				s.hit = true
	ComponentExplosion.explode(state, dice, emit, u, w, loc, ComponentExplosion.PER_SLOT * (w.def.slots + 1))
