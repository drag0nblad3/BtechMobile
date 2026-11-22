class_name BattleAudioCues
extends RefCounted
## Maps authoritative GameEvents to sounds; never calculates attack results.

static func of(e: GameEvent, state: GameState = null) -> String:
	var d: Dictionary = e.data
	match e.type:
		GameEvent.WEAPON_FIRED:
			if d.get("no_ammo", false) or d.get("streak_held", false):
				return ""
			var w := String(d.get("weapon_id", d.get("weapon", ""))).to_lower()
			if "gauss" in w or "hag" in w:
				return "gauss"
			if "flamer" in w or "plasma" in w:
				return "flamer"
			if "lrm" in w or "srm" in w or "mrm" in w or "missile" in w or "atm" in w:
				return "missile"
			if "laser" in w or "ppc" in w:
				return "energy"
			return "ballistic"
		GameEvent.UNIT_MOVED:
			return "jump" if d.get("mode", -1) == MoveMode.Kind.JUMP else "step"
		GameEvent.DAMAGE:
			var unit: Unit = state.unit_by_id(int(d.get("unit_id", -1))) if state != null else null
			var loc := int(d.get("loc", -1))
			if unit != null and loc >= 0 and loc < unit.armor.size() and unit.armor[loc] <= 0:
				return "breach"
			return "hit"
		GameEvent.PHYSICAL:
			return "hit" if d.get("hit", false) else "miss"
		GameEvent.FALL:
			return "fall"
		GameEvent.CRITICAL:
			return "critical"
		GameEvent.AMMO_EXPLOSION:
			return "ammo"
		GameEvent.UNIT_DESTROYED:
			return "kill"
		GameEvent.HEAT:
			return "heat" if int(d.get("heat", 0)) >= 14 else ""
		GameEvent.SHUTDOWN:
			return "shutdown" if d.get("shutdown", false) else "restart"
		GameEvent.BUILDING:
			return "collapse" if d.get("kind", "") in ["collapsed", "bridge_collapsed", "flattened"] else ""
	return ""


static func clip(key: String) -> String:
	if key in ["energy", "flamer", "heat", "critical", "shutdown", "restart"]:
		return "laser_alert"
	if key in ["step", "jump", "miss"]:
		return "step"
	return "heavy_impact"


static func pitch(key: String, tons: int = 50) -> float:
	match key:
		"step", "fall":
			return clampf(1.36 - float(tons) / 145.0, 0.64, 1.2)
		"gauss": return 0.65
		"missile": return 1.3
		"ballistic": return 0.9
		"energy": return 1.15
		"flamer": return 0.78
		"ammo": return 0.7
		"kill", "collapse": return 0.65
		"critical": return 1.5
		"heat", "shutdown": return 0.9
		_: return 1.0
