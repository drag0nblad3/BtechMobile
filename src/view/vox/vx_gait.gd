class_name VxGait
extends RefCounted
## Foot path and two-bone leg solve for voxel 'Mechs. Angles are about the
## x axis; positive swings a limb toward the front (-z).

const STANCE := 0.6  ## Share of the cycle a foot is planted.


## Foot target for a cycle phase: x = forward of the hip, y = lift.
static func foot(phase: float, stride: float, lift: float) -> Vector2:
	var p := fposmod(phase, 1.0)
	if p < STANCE:
		return Vector2(lerpf(stride * 0.5, -stride * 0.5, p / STANCE), 0.0)
	var u := (p - STANCE) / (1.0 - STANCE)
	var s := u * u * (3.0 - 2.0 * u)
	return Vector2(lerpf(-stride * 0.5, stride * 0.5, s), sin(u * PI) * lift)


## Hip, knee and ankle angles that put the ankle `forward` ahead and `down`
## below the hip, keeping the foot level. Knees bend backward.
static func solve(forward: float, down: float, thigh: float, shin: float) -> Vector3:
	var dist := clampf(sqrt(forward * forward + down * down), 0.01, thigh + shin - 0.001)
	var cos_k := clampf((dist * dist - thigh * thigh - shin * shin) / (2.0 * thigh * shin), -1.0, 1.0)
	var bend := acos(cos_k)
	var hip := atan2(forward, down) + atan2(shin * sin(bend), thigh + shin * cos(bend))
	return Vector3(hip, -bend, bend - hip)


## Where the ankle ends up for given hip and knee angles (for tests).
static func ankle_of(hip: float, knee: float, thigh: float, shin: float) -> Vector2:
	return Vector2(thigh * sin(hip) + shin * sin(hip + knee), thigh * cos(hip) + shin * cos(hip + knee))
