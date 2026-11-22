class_name ArrowInferno
extends RefCounted
## Inferno Arrow IV missiles (book p. 190, errata v0.2). Instead of damage,
## the struck hex and the six around it catch fire, and every unit in them
## takes 10 heat in this turn's Heat Phase. Fire on ground that can't burn
## goes out in the End Phase two turns later; woods and buildings burn on
## (Fire). A 'Mech carrying inferno ammo risks it exploding from heat
## (InfernoAmmo).
## TODO(rules): the 10 heat counts as outside heat (15 cap a turn); water
## hexes don't burn; the map's "no fire" setting stops the fire but not the heat.

const KIND := "inferno"
const HEAT := 10
const BURN_TURNS := 2


static func strike(state: GameState, emit: Callable, c: Vector2i) -> void:
	var hexes: Array[Vector2i] = [c]
	for f in 6:
		hexes.append(Hex.neighbor(c, f))
	var lit: Array[Vector2i] = []
	for h in hexes:
		var t := state.map.get_tile(h)
		if t == null:
			continue
		for u in state.units:
			if u.coord == h and not u.destroyed and u.carrier_id() < 0 and not EndPhase.submerged(state, u):
				u.outside_heat += HEAT
		if t.is_water() or state.map.no_fire or t.on_fire:
			continue
		t.on_fire = true
		t.fire_out = state.turn + BURN_TURNS if Fire.heat_to_light(t) <= 0 else -1
		lit.append(h)
	emit.call(GameEvent.BUILDING, {"kind": "inferno", "coord": c, "name": "inferno", "hexes": lit, "heat": HEAT})


## End Phase: Inferno IV fire on bare ground burns out.
static func end_phase(state: GameState, emit: Callable) -> void:
	var out: Array[Vector2i] = []
	for t: MapTile in state.map.tiles.values():
		if t.fire_out >= 0 and t.fire_out <= state.turn:
			t.on_fire = false
			t.fire_out = -1
			out.append(t.coord)
	if not out.is_empty():
		emit.call(GameEvent.BUILDING, {"kind": "fire_out", "coord": out[0], "name": "fire", "hexes": out})
