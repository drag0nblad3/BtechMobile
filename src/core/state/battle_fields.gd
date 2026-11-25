class_name BattleFields
extends RefCounted
## Explicitly permitted runtime fields in the versioned battle save format.
## Content definitions are referenced by id, never rewritten into a save.

static func names(o: Object) -> Array:
	if o is GameState:
		return ["map", "units", "turn", "phase", "initiative_order", "side_order",
				"order_index", "initiative_rolls", "declared_fire", "declared_physical",
				"building_hits", "doomed_buildings", "initiative_die_rule",
				"initiative_die", "fire_heat", "spotting", "tagged", "tag_used", "artillery", "smoke_pending", "minefields", "conditions", "sees_through",
				"mission", "hidden", "point_blank", "reserves", "waiting", "ecm_clear",
				"game_over", "winner"]
	if o is Unit:
		return ["id", "def", "side", "coord", "facing", "pilot", "asset", "vehicle", "ba", "armor",
				"rear_armor", "structure", "armor_partial", "rear_partial", "structure_partial", "weapons", "ammo", "slots", "heat",
				"engine_hits", "gyro_hits", "sensor_hits", "heat_sinks_lost",
				"sinks_off", "sinks_off_request", "stealth_off", "stealth_request", "melee_lost", "club",
				"destroyed", "destroyed_reason", "destroyed_announced", "prone",
				"flooded", "ecm_lost", "probe_lost", "tc_lost", "narc_pods",
				"drop_turn", "carry_arm", "on_roof", "on_bridge", "shutdown",
				"voluntary_shutdown", "power_request", "masc_level", "sc_level",
				"sc_lost", "has_moved", "has_fired", "has_physical", "move_mode",
				"hexes_moved", "masc_used", "masc_active", "masc_failed",
				"sc_used", "sc_active", "sc_failed", "flat_out", "torso_twist",
				"arms_flipped", "landed", "tmm_zero", "heat_generated",
				"outside_heat", "damage_this_phase", "psr_pending"]
	if o is AssetState:
		return ["card", "improved", "check", "damage", "ai_hit", "flushed",
				"last_attacker", "auto_fail", "deployed_turn", "indirect_turn",
				"carried_by", "altitude"]
	if o is VehicleState:
		return ["spec", "cruise_lost", "half_cruise", "immobile", "driving_mod",
				"sensor_hits", "stabilizers", "turret_locked", "turret_lost",
				"crew_stunned", "commander_hit", "driver_hit", "engine_hit"]
	if o is BaState:
		return ["troopers", "carried_by", "deployed_turn", "swarming"]
	if o is VehicleSpec:
		return ["motive", "cruise_mp", "engine", "turret"]
	if o is AssetCard:
		return ["kind", "motive", "mp", "tmm", "short_range", "medium_range",
				"long_range", "skill", "skill_improved", "damage", "groupings",
				"check", "threshold", "bsp", "bsp_improved", "specials", "mechanized"]
	if o is WeaponDef:
		return ["id", "name", "type", "heat", "damage", "damage_by_range",
				"missiles", "group", "min_range", "short_range", "medium_range",
				"long_range", "slots", "tons", "ammo_per_ton", "bv", "ammo_bv",
				"heat_damage", "heat_points", "indirect", "to_hit_mod", "explodes",
				"ammo_explodes", "rapid", "lbx", "rotary", "beacon", "ammo_damage",
				"streak", "pulse", "ams", "tech", "artemis_builtin", "munitions",
				"label", "cluster_mod", "one_shot", "ai",
				"range_cluster", "heat_dice", "to_hit_by_range", "large_missile"]
	if o is BattleMap:
		return ["name", "width", "height", "tiles", "colors", "rubble", "ground",
				"no_fire", "windy"]
	if o is MapTile:
		return ["coord", "terrain", "level", "depth", "building", "bridge",
				"on_fire", "surface", "fog", "smoke", "smoke_turn", "fire_out"]
	if o is Bridge:
		return ["type", "height", "level", "span"]
	if o is Building:
		return ["type", "height"]
	if o is Pilot:
		return ["name", "gunnery", "piloting", "hits", "conscious", "roll_owed",
				"out_since_turn", "abilities", "lucky", "quarry"]
	if o is MountedWeapon:
		return ["def", "loc", "rear", "destroyed", "exploded", "mode", "artemis",
				"artemis_lost", "artemis_v", "apollo", "apollo_lost", "fired", "engaged", "narc_ammo", "ammo_kinds",
				"jammed", "spent", "crit_hits", "on_vehicle", "on_squad", "capacitor", "capacitor_lost",
				"cap_charged", "cap_released"]
	if o is AmmoBin:
		return ["weapon", "loc", "shots", "destroyed", "kind"]
	if o is CritSlot:
		return ["kind", "name", "ref", "hit", "hit_when"]
	if o is ToHit:
		return ["mods", "impossible", "spotter_id", "indirect", "cover_hex",
				"legs_only", "aim_loc", "aim_covered", "narc_homing", "auto_hit"]
	if o is MissionState:
		return ["def", "vp", "crippled", "torso_saved", "withdraw_from",
				"withdraw_fails", "exited", "scans", "last_turn"]
	if o is Mission:
		return ["id", "name", "turns", "random_duration", "victory", "unit_vp",
				"forced_withdrawal", "scoring", "objectives", "home_edges", "exit",
				"exit_from_turn", "exit_side", "attacker", "ecm_interference",
				"waves", "scan", "summary", "notes", "initiative_side",
				"initiative_turns"]
	if o is Objective:
		return ["coord", "radius", "owner", "vp", "kind", "found", "claimed",
				"potential", "fragile", "mobile", "carrier_id", "destroyed"]
	if o is Conditions:
		return ["cold", "heat", "gravity", "low_visibility", "wind", "rain",
				"snowfall", "night"]
	if o is GameEvent:
		return ["type", "data"]
	return []


## Constructors requiring dependencies are kept here instead of allowing a
## save file to instantiate an arbitrary script or native Godot object.
static func create(tag: String, p: Dictionary, units: UnitDb, terrain: TerrainDb) -> Object:
	match tag:
		"GameState": return GameState.new(null)
		"BattleMap": return BattleMap.new()
		"MapTile": return MapTile.new(Vector2i.ZERO,
				terrain.get_type(String(p["terrain"]["id"])), 0)
		"Unit":
			var def: UnitDef = units.get_def(String(p["def"]["id"]))
			if def == null:
				return null
			return Unit.new(int(p["id"]), def, int(p["side"]), Vector2i.ZERO, 0)
		"Building": return Building.new(terrain.buildings.get(String(p["type"]["id"])))
		"Bridge": return Bridge.new(terrain.buildings.get(String(p["type"]["id"])), 0, [])
		"Pilot": return Pilot.new()
		"AssetCard": return AssetCard.new()
		"AssetState": return AssetState.new(AssetCard.new())
		"BaState": return BaState.new()
		"VehicleSpec": return VehicleSpec.new()
		"VehicleState": return VehicleState.new(VehicleSpec.new())
		"WeaponDef": return WeaponDef.new()
		"MountedWeapon":
			var saved_def: Dictionary = p["def"]
			var w: WeaponDef = units.weapons.get_def(String(saved_def["id"])) 					if String(saved_def.get("$", "")) == "weapon_def" else WeaponDef.new()
			return MountedWeapon.new(w, 0, false)
		"AmmoBin":
			var saved: Dictionary = p["weapon"]
			if String(saved.get("$", "")) != "weapon_def":  # a squad's generated weapon, saved inline
				return AmmoBin.new(WeaponDef.new(), 0)
			return AmmoBin.new(units.weapons.get_def(String(saved["id"])), 0)
		"CritSlot": return CritSlot.new(0, "")
		"ToHit": return ToHit.new()
		"MissionState": return MissionState.new()
		"Mission": return Mission.new()
		"Objective": return Objective.new()
		"Conditions": return Conditions.new()
		"GameEvent": return GameEvent.new(&"")
	return null
