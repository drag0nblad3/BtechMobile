class_name VoxelGait
extends RefCounted
## Deterministic sagittal two-link IK: positive forward is world -Z.

const CYCLE_SECONDS := 1.30
const STANCE_FRACTION := 0.60
const STRIDE := 0.80
const THIGH := 0.70
const SHIN := 0.70
const ANKLE_HEIGHT := 0.12
const SWING_HEIGHT := 0.24


## Stance: planted foot moves backward relative to a forward-moving hip.
## Swing: foot lifts and moves forward. Legs use phases separated by 0.5.
static func foot_target(phase: float) -> Vector2:
	var p := fposmod(phase, 1.0)
	if p < STANCE_FRACTION:
		return Vector2(lerpf(STRIDE * 0.5, -STRIDE * 0.5,
				p / STANCE_FRACTION), ANKLE_HEIGHT)
	var u := (p - STANCE_FRACTION) / (1.0 - STANCE_FRACTION)
	var smooth := u * u * (3.0 - 2.0 * u)
	return Vector2(lerpf(-STRIDE * 0.5, STRIDE * 0.5, smooth),
			ANKLE_HEIGHT + sin(u * PI) * SWING_HEIGHT)


static func sample(phase: float, hip_height: float) -> Vector3:
	var foot := foot_target(phase)
	var down := hip_height - foot.y
	var forward := foot.x
	var dist := minf(sqrt(forward * forward + down * down), THIGH + SHIN - 0.001)
	var cos_knee := clampf((dist * dist - THIGH * THIGH - SHIN * SHIN)
			/ (2.0 * THIGH * SHIN), -1.0, 1.0)
	var bend := acos(cos_knee)
	var hip := atan2(forward, down) + atan2(SHIN * sin(bend), THIGH + SHIN * cos(bend))
	return Vector3(hip, -bend, bend - hip)
