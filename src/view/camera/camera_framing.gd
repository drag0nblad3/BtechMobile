class_name CameraFraming
extends RefCounted
## Where to point the camera so two units (attacker and target) sit in the
## part of the screen the right-hand side panel leaves visible.

## Share of the screen width the side panel covers.
const PANEL_SHARE := 0.38
## Share of the screen height the pair may span (HUD rows above and below).
const HEIGHT_SHARE := 0.3


## {"focus": Vector3, "distance": float}: the pair's midpoint moved so it
## shows left of the panel, and a camera distance (never closer than now)
## at which both fit between the HUD rows.
static func beside_panel(camera: Camera3D, current_dist: float, a: Vector3, b: Vector3, screen: Vector2) -> Dictionary:
	var mid := (a + b) * 0.5
	if camera == null or screen.y <= 0.0:
		return {"focus": mid, "distance": current_dist}
	var view := 2.0 * tan(deg_to_rad(camera.fov) * 0.5)
	var dist := maxf(current_dist, a.distance_to(b) / (HEIGHT_SHARE * view))
	var world_per_px := dist * view / screen.y
	var right := camera.global_transform.basis.x
	right.y = 0.0
	return {"focus": mid + right.normalized() * (screen.x * PANEL_SHARE * 0.5) * world_per_px,
			"distance": dist}
