class_name AttackEventMatch
extends RefCounted
## Match only the current attack, not later attacks with the same shooter.
static func starts(e: GameEvent) -> bool:
	return e.type in [GameEvent.WEAPON_FIRED, GameEvent.PHYSICAL]


static func belongs(attack: GameEvent, event: GameEvent) -> bool:
	var a := attack.data
	var d := event.data
	if event.type == GameEvent.DAMAGE:
		return int(d.get("source_id", -2)) == int(a.get("attacker_id", -1)) and int(d.get("unit_id", -2)) == int(a.get("target_id", -1)) and (String(d.get("source", "")) == String(a.get("weapon", "")) or String(d.get("source", "")) == String(a.get("kind", "")) or attack.type == GameEvent.WEAPON_FIRED)
	if event.type == GameEvent.BUILDING:
		return (d.get("kind") == "cover_hit" and d.get("unit_id") == a.get("target_id")) or (d.get("kind") == "shot" and d.get("unit_id") == a.get("attacker_id") and d.get("coord") == a.get("target_hex"))
	return false


static func fired(d: Dictionary) -> bool:
	return not d.get("no_ammo", false) and not d.get("streak_held", false)


static func intercepted(d: Dictionary) -> bool:
	return bool(d.get("pod_shot_down", false)) or (bool(d.get("ams", false)) and int(d.get("missiles", -1)) == 0 and d.has("cluster_roll"))
