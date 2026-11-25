class_name TacticalIntel
extends RefCounted
## Read-only tactical overlays for reachable hexes.
const MODES := ["Movement", "Incoming damage", "Cover", "Movement defense", "Enemy range"]


static func colors(state: GameState, u: Unit, options: MoveOptions, mode: int, overlay: int) -> Dictionary:
	var out := {}
	for c: Vector2i in options.reachable_hexes():
		var key: Vector3i = options.end_keys_in(c)[0]
		var moved := int(options.cost.get(key, 0)) > 0
		var hexes := Hex.distance(u.coord, c) if mode == MoveMode.Kind.JUMP else MoveOptions.hexes_entered(options.path_to(key), u.coord)
		var value := 0.0
		match overlay:
			1:
				value = clampf(Threat.incoming(state, u, c, key.z, mode if moved else -1, hexes) / 30.0, 0, 1)
			2:
				var tile := state.map.get_tile(c)
				value = clampf(float(LineOfSight.woods_value(tile)) / 2.0 + (0.5 if tile.is_water() and tile.depth == 1 else 0.0), 0, 1)
			3:
				value = clampf(float(ToHitCalc.target_movement_mod(hexes, moved and mode == MoveMode.Kind.JUMP)) / 5.0, 0, 1)
			4:
				var count := 0
				for e: Unit in state.units:
					if e.side == u.side or e.destroyed:
						continue
					for w: MountedWeapon in e.weapons:
						if Hex.distance(e.coord, c) <= Atm.profile(w).long_range:
							count += 1
				value = clampf(float(count) / 12.0, 0, 1)
		var good := Color(0.18, 0.8, 0.64, 0.40)
		var bad := Color(0.98, 0.23, 0.18, 0.55)
		out[c] = bad.lerp(good, value) if overlay in [2, 3] else good.lerp(bad, value)
	return out


static func legend(overlay: int) -> String:
	match overlay:
		1: return "INTEL: incoming damage, green 0 to red 30+; current enemy positions, one facing per hex."
		2: return "INTEL: terrain cover, green more cover; not a directional LOS prediction."
		3: return "INTEL: target movement modifier, green higher defense."
		4: return "INTEL: enemy weapons in nominal range, red 12+; ignores arcs, LOS and ammo."
	return ""
