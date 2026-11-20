class_name VoxelJennerGait
extends RefCounted
## Jenner-specific proportions for the same three-pivot digitigrade kinematics.
## The profile is taller and narrower than Catapult's generic digitigrade rig.

const CYCLE_SECONDS := 1.12
const STANCE_FRACTION := 0.58
const STRIDE := 1.00
const THIGH := 0.78
const SHIN := 0.82
const METATARSAL := 0.27
const HIP_HEIGHT := 1.72
const TOE_HEIGHT := 0.15
const SWING_HEIGHT := 0.29
const HOCK_TO_TOE_ANGLE := 0.52


static func foot_target(phase: float) -> Vector2:
	var p := fposmod(phase, 1.0)
	if p < STANCE_FRACTION:
		return Vector2(lerpf(STRIDE * 0.5, -STRIDE * 0.5,
				p / STANCE_FRACTION), TOE_HEIGHT)
	var u := (p - STANCE_FRACTION) / (1.0 - STANCE_FRACTION)
	var smooth := u * u * (3.0 - 2.0 * u)
	return Vector2(lerpf(-STRIDE * 0.5, STRIDE * 0.5, smooth),
			TOE_HEIGHT + sin(u * PI) * SWING_HEIGHT)


## Returns hip, knee, hock, toe rotations in radians for a raised toe
## contact point. Foot stays approximately level during stance.
static func sample(phase: float, hip_height: float = HIP_HEIGHT) -> Vector4:
	var toe := foot_target(phase)
	var forward := toe.x - METATARSAL * sin(HOCK_TO_TOE_ANGLE)
	var down := hip_height - toe.y - METATARSAL * cos(HOCK_TO_TOE_ANGLE)
	var reach := clampf(Vector2(forward, down).length(), 0.001,
			THIGH + SHIN - 0.0001)
	var cosine := clampf((reach * reach - THIGH * THIGH - SHIN * SHIN)
			/ (2.0 * THIGH * SHIN), -1.0, 1.0)
	var bend := acos(cosine)
	var hip := atan2(forward, down) + atan2(SHIN * sin(bend),
			THIGH + SHIN * cos(bend))
	var knee := -bend
	var hock := HOCK_TO_TOE_ANGLE - hip - knee
	return Vector4(hip, knee, hock, -HOCK_TO_TOE_ANGLE)


static func horizontal_speed() -> float:
	return STRIDE / (STANCE_FRACTION * CYCLE_SECONDS)
