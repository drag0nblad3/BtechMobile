class_name WeaponDef
extends RefCounted
## Static weapon stats from data/weapons.json. Ranges are the upper bound of
## each bracket in hexes; `min` > 0 means a minimum-range penalty applies.

enum Bracket { OUT, SHORT, MEDIUM, LONG }

var id: String
var name: String
var type: String       ## "energy", "ballistic" or "missile".
var heat: int
var damage: int        ## Per shot, or per missile for missile weapons.
var damage_by_range: Array[int] = []  ## Variable damage (p. 182): short, medium, long.
var missiles: int      ## 0 for non-missile weapons.
var group: int         ## Missile damage cluster size (LRM 5, SRM 1).
var min_range: int
var short_range: int
var medium_range: int
var long_range: int
var slots: int
var tons: float          ## Weight in tons (book weapon tables).
var ammo_per_ton: int  ## 0 = no ammo needed.
var bv: int           ## Battle Value of the weapon.
var ammo_bv: int       ## Battle Value of one ton of its ammo.
var heat_damage: bool  ## A hit also adds heat to the target (flamers).
var heat_points: int   ## Heat a flamer hit adds: its damage unless noted (ER flamer 1, p. 184).
var indirect: bool     ## May fire without line of sight via a spotter (LRMs).
var to_hit_mod: int    ## The weapon's own to-hit modifier (pulse lasers -2).
var explodes: bool     ## Blows up on its first critical hit (Gauss rifles, p. 184).
var explosion_damage: int = -1 ## Component's critical explosion; -1 uses 2 per slot.
var reengineered: bool ## Ignores reflective, hardened and ferro-lamellor armor reduction.
var rifle: bool ## Primitive rifle: 3 less damage to modern armored targets.
var ammo_explodes: bool = true  ## False for Gauss slugs.
var rapid: int         ## Most shots in one attack (Ultra ACs 2), 0 = normal.
var lbx: bool          ## LB-X: can fire cluster ammo.
var rotary: bool       ## Rotary AC: 1-6 shots, may jam (RotaryAc).
var beacon: bool       ## Narc: a hit attaches a homing pod, no damage (Narc).
var artillery: bool    ## Arrow IV: fired at a hex, area-effect damage (ArrowIv).
var ammo_damage: int   ## Explosion damage per shot, if not its damage (Narc pods 2).
var streak: bool       ## Streak: all missiles hit, or it doesn't fire.
var pulse: bool        ## Pulse laser (no targeting computer bonus on aimed shots).
var ams: bool          ## Anti-missile system: never fires at targets (AntiMissile).
## "inner_sphere" or "clan" (ids start "c_"): Clan versions are lighter,
## smaller and longer-ranged (book p. 251 tables).
var tech := "inner_sphere"
var artemis_builtin: bool  ## Artemis IV built in (ATMs, p. 186): no FCS item needed.
## Ammo kind -> WeaponDef with that munition's damage, ranges and cluster
## grouping (ATM "er"/"he"); its ammo still belongs to this launcher (Atm).
var munitions: Dictionary = {}
var label := ""       ## Munition name for the firing mode (MML "LRM"/"SRM").
var cluster_mod: int   ## Added to Cluster Hits rolls (MRM -1, p. 186).
var one_shot: bool     ## Fires once a game, no ammo bins (rocket launchers, p. 182).
var ai: bool           ## Anti-Infantry type (AI, book weapon tables): more harm to infantry Assets.
var range_cluster: bool ## HAG cluster modifiers depend on range.
var heat_dice: int     ## Plasma heat dice on impact.
var to_hit_by_range: Array[int] = [] ## VSP accuracy per range.
var large_missile: bool ## Thunderbolt: AMS intercepts one missile.


static func from_dict(d: Dictionary) -> WeaponDef:
	var w := WeaponDef.new()
	w.id = d["id"]
	w.name = d["name"]
	w.type = d.get("type", "energy")
	w.heat = int(d.get("heat", 0))
	w.damage = int(d["damage"])
	for v in d.get("damage_by_range", []):
		w.damage_by_range.append(int(v))
	w.missiles = int(d.get("missiles", 0))
	w.group = int(d.get("group", 1))
	w.min_range = int(d.get("min", 0))
	w.short_range = int(d["short"])
	w.medium_range = int(d["medium"])
	w.long_range = int(d["long"])
	w.slots = int(d.get("slots", 1))
	w.tons = float(d.get("tons", 0.0))
	w.ammo_per_ton = int(d.get("ammo_per_ton", 0))
	w.bv = int(d.get("bv", 0))
	w.ammo_bv = int(d.get("ammo_bv", 0))
	w.indirect = bool(d.get("indirect", false))
	w.heat_damage = bool(d.get("heat_damage", false))
	w.heat_points = int(d.get("heat_points", d.get("damage", 0)))
	w.to_hit_mod = int(d.get("to_hit", 0))
	w.explodes = bool(d.get("explodes", false))
	w.explosion_damage = int(d.get("explosion_damage", -1))
	w.reengineered = bool(d.get("reengineered", false))
	w.rifle = bool(d.get("rifle", false))
	w.ammo_explodes = bool(d.get("ammo_explodes", true))
	w.rapid = int(d.get("rapid", 0))
	w.lbx = bool(d.get("lbx", false))
	w.rotary = bool(d.get("rotary", false))
	w.beacon = bool(d.get("beacon", false))
	w.artillery = bool(d.get("artillery", false))
	w.ammo_damage = int(d.get("ammo_damage", 0))
	w.streak = bool(d.get("streak", false))
	w.ams = bool(d.get("ams", false))
	w.pulse = bool(d.get("pulse", false))
	w.tech = d.get("tech", "inner_sphere")
	w.artemis_builtin = bool(d.get("artemis_builtin", false))
	w.label = d.get("label", "")
	w.cluster_mod = int(d.get("cluster_mod", 0))
	w.one_shot = bool(d.get("one_shot", false))
	w.ai = bool(d.get("ai", false))
	w.range_cluster = bool(d.get("range_cluster", false))
	w.heat_dice = int(d.get("heat_dice", 0))
	for v in d.get("to_hit_by_range", []):
		w.to_hit_by_range.append(int(v))
	w.large_missile = bool(d.get("large_missile", false))
	var mun: Dictionary = d.get("munitions", {})
	for kind: String in mun:
		var v := d.duplicate()
		v.erase("munitions")
		v.merge(mun[kind], true)
		v["name"] = "%s (%s)" % [d["name"], mun[kind].get("label", kind)]
		w.munitions[kind] = WeaponDef.from_dict(v)
	return w


func is_clan() -> bool:
	return tech == "clan"


## Weapon Type codes from the book's tables (p. 182) that Assets care about:
## DE direct energy, P pulse, DB direct ballistic, M missile, AI, H heat.
## Weapon accuracy may vary by distance, e.g. VSP lasers.
func to_hit_at(br: int) -> int:
	if to_hit_by_range.is_empty() or br < Bracket.SHORT:
		return to_hit_mod
	return to_hit_by_range[br - Bracket.SHORT]


func attack_types() -> Array[String]:
	var out: Array[String] = []
	match type:
		"energy":
			out.append("P" if pulse else "DE")
		"ballistic":
			out.append("DB")
		"missile":
			out.append("M")
		"artillery":
			out.append("AE")
	if reengineered:
		out.append("RE")
	if ai:
		out.append("AI")
	if heat_damage:
		out.append("H")
	return out


func uses_ammo() -> bool:
	return ammo_per_ton > 0


func is_cluster() -> bool:
	return missiles > 0


## Damage if every shot/missile hits (for advice and record sheets).
## Variable damage (p. 182): the value for the bracket `dist` falls in,
## `shift` brackets longer (under water a beam counts one bracket longer).
func damage_at(dist: int, shift := 0) -> int:
	var br := bracket(dist)
	if damage_by_range.is_empty() or br == Bracket.OUT:
		return damage
	return damage_by_range[clampi(br + shift - Bracket.SHORT, 0, 2)]


func max_damage() -> int:
	return damage * missiles if is_cluster() else damage


func bracket(range_hexes: int) -> int:
	if range_hexes <= short_range:
		return Bracket.SHORT
	if range_hexes <= medium_range:
		return Bracket.MEDIUM
	if range_hexes <= long_range:
		return Bracket.LONG
	return Bracket.OUT


func range_text() -> String:
	var s := "%d/%d/%d" % [short_range, medium_range, long_range]
	return ("min %d, " % min_range + s) if min_range > 0 else s
