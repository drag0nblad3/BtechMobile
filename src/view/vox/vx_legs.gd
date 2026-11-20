class_name VxLegs
extends RefCounted
## Poses both legs of a VxMech each frame: plantigrade (thigh, shin, foot)
## or digitigrade (thigh, reverse knee, shin, upright tarsus, foot).

const STRIDE := 0.6
const LIFT := 0.22
const RUN_STRIDE := 0.85
const RUN_LIFT := 0.3


## Returns how far the body sits below its built height (plus walk bob).
static func pose(m: VxMech, phase: float, walking: bool, crouch: float, kick: Array, run: bool = false) -> float:
	var reverse := m.hocks[0] != null
	var reach := m.thigh + m.shin
	var ankle_rest := m.hip_height - reach - m.tarsus
	var bend := (0.84 if reverse else 0.95) - 0.3 * crouch
	var hip := ankle_rest + m.tarsus + reach * bend
	for side in 2:
		var p := phase + 0.5 * side
		var f := VxGait.foot(p, RUN_STRIDE if run else STRIDE, RUN_LIFT if run else LIFT) if walking else Vector2.ZERO
		f += Vector2(0.75, 0.45) * float(kick[side]) * reach
		var a := VxGait.solve(f.x, hip - ankle_rest - m.tarsus - f.y, m.thigh, m.shin, reverse)
		_apply(m, side, a, VxGait.swing(p) if walking else 0.0, reverse)
	var bob := absf(sin(phase * TAU)) * (0.09 if run else 0.05) if walking else 0.0
	return hip - m.hip_height + bob


static func _apply(m: VxMech, side: int, a: Vector3, swing: float, reverse: bool) -> void:
	if not m.is_attached(m.hips[side]):
		return
	m.hips[side].rotation.x = a.x
	if not m.is_attached(m.knees[side]):
		return
	m.knees[side].rotation.x = a.y
	if reverse:
		m.hocks[side].rotation.x = a.z + 0.25 * swing  # tarsus swings forward in the air
		m.ankles[side].rotation.x = -0.25 * swing - 0.6 * swing  # toes curl down
	else:
		m.ankles[side].rotation.x = a.z - 0.35 * swing
