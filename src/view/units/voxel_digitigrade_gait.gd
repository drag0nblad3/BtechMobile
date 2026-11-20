class_name VoxelDigitigradeGait
extends RefCounted
## Three-segment leg: forward-facing knee, rearward hock, long sloping ankle link.
## All angles rotate around local X; forward movement is toward -Z.

const CYCLE_SECONDS := 1.18
const STANCE_FRACTION := 0.58
const STRIDE := 0.92
const THIGH := 0.70
const SHIN := 0.70
const METATARSAL := 0.32
const HOCK_TO_TOE_ANGLE := 0.65
const HIP_HEIGHT := 1.52
const TOE_HEIGHT := 0.15
const SWING_HEIGHT := 0.30


## Toe contact remains level through stance; the hock stays high off the floor.
static func foot_target(phase: float) -> Vector2:
	var p := fposmod(phase, 1.0)
	if p < STANCE_FRACTION:
		return Vector2(lerpf(STRIDE * 0.5, -STRIDE * 0.5,
				p / STANCE_FRACTION), TOE_HEIGHT)
	var u := (p - STANCE_FRACTION) / (1.0 - STANCE_FRACTION)
	var smooth := u * u * (3.0 - 2.0 * u)
	return Vector2(lerpf(-STRIDE * 0.5, STRIDE * 0.5, smooth),
			TOE_HEIGHT + sin(u * PI) * SWING_HEIGHT)


## Returns hip, knee, hock, and toe pitch. Hock is an actual third pivot,
## not a renamed human ankle. The toe stays flat while planted.
static func sample(phase: float, hip_height: float = HIP_HEIGHT) -> Vector4:
	var toe := foot_target(phase)
	var hock_forward := toe.x - METATARSAL * sin(HOCK_TO_TOE_ANGLE)
	var hock_down := hip_height - toe.y - METATARSAL * cos(HOCK_TO_TOE_ANGLE)
	var reach := sqrt(hock_forward * hock_forward + hock_down * hock_down)
	reach = clampf(reach, 0.001, THIGH + SHIN - 0.0001)
	var cos_knee := clampf((reach * reach - THIGH * THIGH - SHIN * SHIN)
			/ (2.0 * THIGH * SHIN), -1.0, 1.0)
	var bend := acos(cos_knee)
	var hip := atan2(hock_forward, hock_down) + atan2(SHIN * sin(bend),
			THIGH + SHIN * cos(bend))
	var knee := -bend
	var hock := HOCK_TO_TOE_ANGLE - hip - knee
	return Vector4(hip, knee, hock, -HOCK_TO_TOE_ANGLE)


static func horizontal_speed() -> float:
	return STRIDE / (STANCE_FRACTION * CYCLE_SECONDS)
