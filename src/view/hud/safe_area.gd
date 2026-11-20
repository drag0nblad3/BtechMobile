class_name SafeArea
extends RefCounted
## Insets (in HUD pixels) that keep controls clear of notches, camera cutouts and
## gesture bars on phones. All zero on desktop.


static func insets(viewport: Viewport) -> Dictionary:
	var out := {"left": 0, "right": 0, "top": 0, "bottom": 0}
	if not OS.has_feature("mobile"):
		return out
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if screen.x <= 0.0 or screen.y <= 0.0 or safe.size.x <= 0.0:
		return out
	var to_hud := viewport.get_visible_rect().size / screen
	out["left"] = ceili(safe.position.x * to_hud.x)
	out["top"] = ceili(safe.position.y * to_hud.y)
	out["right"] = ceili((screen.x - safe.end.x) * to_hud.x)
	out["bottom"] = ceili((screen.y - safe.end.y) * to_hud.y)
	return out
