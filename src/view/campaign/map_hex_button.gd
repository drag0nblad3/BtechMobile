class_name MapHexButton
extends Button
## Transparent, keyboard-accessible hex button with nonrectangular hit test.

var radius := 42.0


func _ready() -> void:
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_STOP


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, polygon(size / 2.0, radius))


static func polygon(at: Vector2, r: float, closed := false) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 7 if closed else 6:
		points.append(at + Vector2.from_angle(float(i) * TAU / 6.0) * r)
	return points
