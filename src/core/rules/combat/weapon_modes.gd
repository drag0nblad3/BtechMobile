class_name WeaponModes
extends RefCounted
## Firing modes and cluster results for advanced weapons (pp. 182-192):
## Ultra ACs may fire two shots as one attack (cluster column 2, a location
## each); LB-X ACs may fire cluster ammo (-1 to hit, a 1-point pellet per
## column hit, column = AC size); Streaks hit with every missile; Artemis IV
## adds +2 to the cluster roll; rotary ACs fire 1-6 shots (RotaryAc).
## TODO(rules): the Core Rulebook has no Ultra AC jam.

const ULTRA := "ultra"
const CLUSTER := "cluster"
const ARTEMIS_BONUS := 2


## Modes a player can pick for this weapon ("" is normal fire).
static func modes(w: MountedWeapon) -> Array[String]:
	if w.def.rotary:
		return RotaryAc.modes(w)
	if w.def.rapid > 1:
		return ["", ULTRA]
	if w.def.lbx:
		return ["", CLUSTER]
	if w.narc_ammo:
		return ["", Narc.KIND]
	if w.ammo_kinds.size() > 1:
		return w.ammo_kinds
	if Apollo.working(w):
		return ApolloSaturation.modes(w)
	return PpcCapacitor.modes(w)


static func next_mode(w: MountedWeapon) -> String:
	var m := modes(w)
	return m[(m.find(w.mode) + 1) % m.size()]


static func shots(w: MountedWeapon) -> int:
	if w.def.rotary:
		return mini(RotaryAc.shots(w.mode), w.def.rapid)
	return w.def.rapid if w.mode == ULTRA and w.def.rapid > 1 else 1


static func ammo_kind(w: MountedWeapon) -> String:
	if w.mode == Narc.KIND and w.narc_ammo:
		return Narc.KIND
	if w.def.munitions.has(w.mode):
		return w.mode
	if w.artemis_v:
		return "artemis_v"
	return CLUSTER if w.mode == CLUSTER and w.def.lbx else ""


static func to_hit_mod(w: MountedWeapon) -> int:
	return -1 if ammo_kind(w) == CLUSTER else 0


## Artemis needs standard missiles: Narc-equipped ones don't use it.
static func has_artemis(w: MountedWeapon) -> bool:
	return (w.artemis or w.artemis_v or w.def.artemis_builtin) and not w.artemis_lost and ammo_kind(w) != Narc.KIND


## Clan Artemis V adds three cluster points; standard Artemis IV adds two.
static func artemis_bonus(w: MountedWeapon) -> int:
	if not has_artemis(w):
		return 0
	return 3 if w.artemis_v else ARTEMIS_BONUS


## Average damage when the attack hits, in the weapon's current mode.
static func expected_per_hit(w: MountedWeapon) -> float:
	var d := Atm.profile(w)
	if d.streak:
		return float(d.missiles * d.damage)
	if shots(w) > 1:
		return ClusterTable.expected(shots(w)) * d.damage
	if ammo_kind(w) == CLUSTER:
		return ClusterTable.expected(d.damage)
	if d.is_cluster():
		return ClusterTable.expected(d.missiles, artemis_bonus(w)) * d.damage
	return float(d.damage)


## Rolls (if needed) how much of a hit lands: {n, roll, packets}.
## n is 0 for a plain single-packet weapon. `ams`: an anti-missile system
## engaged (AntiMissile): -4 to the roll, a Streak counts as a 7.
static func cluster(w: MountedWeapon, fired: int, dice: Dice, ams := false, no_artemis := false,
		narc := false, no_lock := false, range_mod := 0) -> Dictionary:
	var d := Atm.profile(w)
	if d.streak and not no_lock:
		var sn := ClusterTable.hits(d.missiles, AntiMissile.STREAK_ROLL) if ams else d.missiles
		return {"n": sn, "roll": AntiMissile.STREAK_ROLL if ams else 12, "packets": _packets(sn * d.damage, d.group * d.damage)}
	if fired > 1:
		var r := dice.roll_2d6()
		var n := ClusterTable.hits(fired, r)
		var p: Array[int] = []
		for i in n:
			p.append(d.damage)
		return {"n": n, "roll": r, "packets": p}
	if ammo_kind(w) == CLUSTER:
		var r2 := dice.roll_2d6()
		var pellets := ClusterTable.hits(d.damage, r2)
		return {"n": pellets, "roll": r2, "packets": _packets(pellets, 1)}
	if d.is_cluster():
		var r3 := dice.roll_2d6()
		var bonus := (artemis_bonus(w) if not no_artemis else 0) + (AntiMissile.CLUSTER_MOD if ams else 0) \
				+ (Narc.CLUSTER_BONUS if narc else 0) + Apollo.cluster_mod(w, d) + range_mod
		var m := 0 if r3 + bonus < 2 and range_mod == 0 else ClusterTable.hits(d.missiles, r3 + bonus)
		return {"n": m, "roll": r3, "bonus": bonus, "packets": _packets(m * d.damage, d.group * d.damage)}
	return {"n": 0, "roll": 0, "packets": [d.damage] as Array[int]}


static func _packets(total: int, size: int) -> Array[int]:
	return Damage.clusters(total, size)
