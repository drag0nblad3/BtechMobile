class_name FacingMarker
extends MeshInstance3D
## Arrow on a hex showing where a planned move ends and which way it faces.


func _ready() -> void:
	var arrow := PrismMesh.new()
	arrow.size = Vector3(0.7, 0.8, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.9, 0.3)
	arrow.material = mat
	mesh = arrow
	visible = false


func show_at(world_pos: Vector3, facing: int) -> void:
	# PrismMesh points +Y; lay it flat so the tip points -Z, then yaw.
	var b := Basis(Vector3.UP, HexLayout.facing_yaw(facing)) \
			* Basis(Vector3.RIGHT, -PI / 2.0)
	transform = Transform3D(b, world_pos + Vector3(0, 0.08, 0))
	visible = true
