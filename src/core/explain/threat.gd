class_name Threat
extends RefCounted
## Danger of a move: expected damage enemies could deal to a unit standing at
## a hex, if they fire everything from where they are now. Used by the move
## tip so players learn to compare ground. Only reads the state: the unit's
## position fields are tried and put back, no dice are rolled.


## Expected damage enemies could deal to u at coord/facing after moving `hexes` in `mode` (-1 = stood still).
static func incoming(state: GameState, u: Unit, coord: Vector2i, facing: int, mode: int, hexes: int) -> float:
	var save := [u.coord, u.facing, u.move_mode, u.hexes_moved]
	u.coord = coord
	u.facing = facing
	u.move_mode = mode
	u.hexes_moved = hexes
	var total := 0.0
	for e in state.units:
		if e.side == u.side or e.destroyed:
			continue
		for o in FireOptions.for_target(state, e, u):
			if o["to_hit"].possible():
				total += Advisor.expected_damage(o["weapon"], o["to_hit"])
	u.coord = save[0]
	u.facing = save[1]
	u.move_mode = save[2]
	u.hexes_moved = save[3]
	return total


## One line comparing the previewed hex with staying put ("" at OFF).
static func text(state: GameState, u: Unit, coord: Vector2i, facing: int, mode: int, hexes: int, level: int) -> String:
	if level == ExplainLevel.OFF:
		return ""
	var here := incoming(state, u, coord, facing, mode, hexes)
	var stay := incoming(state, u, u.coord, u.facing, -1, 0)
	if level == ExplainLevel.LIGHT:
		return "Danger here %.1f (stay put %.1f)" % [here, stay]
	if here == 0.0:
		return "No enemy weapon could reach you here from where they stand now."
	var t := "If enemies fired everything from where they stand, they would average %.1f damage on you here" % here
	if coord == u.coord and facing == u.facing:
		return t + "."
	if here < stay * 0.8:
		return t + ", less than the %.1f you'd face staying put." % stay
	if here > stay * 1.2:
		return t + ", more than the %.1f you'd face staying put." % stay
	return t + ", about the same as staying put (%.1f)." % stay
