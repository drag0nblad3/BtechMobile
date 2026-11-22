class_name ArrowSmoke
extends RefCounted
## Smoke Arrow IV missiles (book pp. 190-191). Instead of damage, the struck
## hex and the six around it fill with heavy smoke, two levels high, from the
## next phase on (here: once this phase's shots are done). Heavy smoke turns
## light in the End Phase of the turn after it was made and is gone an End
## Phase later; light smoke leaves first, then heavy turns light. New smoke
## on light smoke makes it heavy again; on heavy it does nothing more. Smoke
## acts like woods for sight and to-hit (Obscurant); wind blows it away.

const KIND := "smoke"
const HEAVY := 2


## A smoke missile struck `c`: the smoke rises once the phase is over.
static func drop(state: GameState, c: Vector2i) -> void:
	for h in [c] + range(6).map(func(f: int) -> Vector2i: return Hex.neighbor(c, f)):
		if state.map.get_tile(h) != null and not state.smoke_pending.has(h):
			state.smoke_pending.append(h)


## End of the weapon phase: pending smoke fills its hexes.
static func apply_pending(state: GameState, emit: Callable) -> void:
	if state.smoke_pending.is_empty():
		return
	for h: Vector2i in state.smoke_pending:
		var t := state.map.get_tile(h)
		t.smoke = HEAVY
		t.smoke_turn = state.turn
	emit.call(GameEvent.BUILDING, {"kind": "smoke", "coord": state.smoke_pending[0], "name": "smoke",
			"hexes": state.smoke_pending.duplicate(), "level": HEAVY})
	state.smoke_pending.clear()


## End Phase: last turn's light smoke clears, then heavy smoke thins.
static func end_phase(state: GameState, emit: Callable) -> void:
	var changed: Array[Vector2i] = []
	for t: MapTile in state.map.tiles.values():
		if t.smoke == 1 and state.turn > t.smoke_turn:
			t.smoke = 0
			changed.append(t.coord)
		elif t.smoke == HEAVY and state.turn > t.smoke_turn:
			t.smoke = 1
			t.smoke_turn = state.turn
			changed.append(t.coord)
	if not changed.is_empty():
		emit.call(GameEvent.BUILDING, {"kind": "smoke_thins", "coord": changed[0], "name": "smoke", "hexes": changed})
