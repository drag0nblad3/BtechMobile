class_name ShotFx
extends RefCounted
## Transient visual-only weapon trails. One brief beam or moving projectile
## per shot; no raycasts, no physics and no new particles or render passes.
## One root per shot is automatically freed after its short animation.

const MAX_ACTIVE := 28
const BEAM_TIME := 0.18
const PROJECTILE_TIME := 0.34


static func arrival_time(weapon: String) -> float:
	return 0.0 if style(weapon) in ["ppc", "laser", "flame"] else PROJECTILE_TIME


## Weapon families intentionally use different silhouettes and colors.
static func style(weapon: String) -> String:
	var w := weapon.to_lower()
	if "ppc" in w:
		return "ppc"
	if "laser" in w or "pulse" in w or "er_laser" in w:
		return "laser"
	if "flamer" in w or "plasma" in w:
		return "flame"
	if "lrm" in w or "srm" in w or "mrm" in w or "atm" in w or "missile" in w or "rocket" in w:
		return "missile"
	return "ballistic"


static func tint(kind: String) -> Color:
	match kind:
		"ppc": return Color("#83c9ff")
		"laser": return Color("#ff6060")
		"flame": return Color("#ffb350")
		"missile": return Color("#ffb45d")
		_: return Color("#ffe1a0")


## Stable aim deviation. Misses are visibly off-target without introducing
## new randomness in combat/replays or changing the game state.
static func miss_offset(attacker: int, target: int, weapon: String) -> Vector3:
	var seed := absi(attacker * 97 + target * 193 + weapon.length() * 53)
	var angle := float(seed % 360) * PI / 180.0
	var radius := 0.46 + float(seed % 5) * 0.12
	return Vector3(cos(angle) * radius, -0.18, sin(angle) * radius)


static func spawn(holder: Node3D, start: Vector3, end: Vector3,
		weapon: String, hit: bool) -> Node3D:
	if start.distance_to(end) < 0.12:
		return null
	var kind := style(weapon)
	var hue := tint(kind)
	var root := Node3D.new()
	root.name = "ShotTrail"
	root.add_to_group("battle_shot")
	holder.add_child(root)
	var is_beam := kind in ["ppc", "laser", "flame"]
	var radius := 0.025 if kind == "ppc" else 0.015
	if not is_beam:
		radius = 0.012
	var trail_end := end if is_beam else start.lerp(end, 0.08)
	var core := _beam(root, start, trail_end, radius, hue, 0.95)
	var haze := _beam(root, start, trail_end, radius * 3.2, hue, 0.24)
	var t := BEAM_TIME if is_beam else PROJECTILE_TIME
	var fade := root.create_tween()
	fade.set_parallel(true)
	fade.tween_property(core, "transparency", 1.0, t)
	fade.tween_property(haze, "transparency", 1.0, t * 0.8)
	if not is_beam:
		var orb := MeshInstance3D.new()
		orb.name = "Projectile"
		var mesh := SphereMesh.new()
		mesh.radius = 0.05 if kind == "missile" else 0.025
		mesh.height = mesh.radius * 2.0
		orb.mesh = mesh
		orb.material_override = _glow(hue, 1.0)
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		orb.position = start
		root.add_child(orb)
		var travel := root.create_tween()
		travel.tween_method(func(t: float):
			var p := start.lerp(end, t)
			if kind == "missile":
				p += Vector3.UP * sin(t * PI) * minf(2.2, start.distance_to(end) * 0.18)
			orb.position = p
			var tail := start.lerp(end, maxf(0.0, t - 0.08))
			if kind == "missile":
				tail += Vector3.UP * sin(maxf(0.0, t - 0.08) * PI) * minf(2.2, start.distance_to(end) * 0.18)
			for line: MeshInstance3D in [core, haze]:
				var span := p - tail
				if span.length() > 0.001:
					line.position = (p + tail) * 0.5
					line.basis = Basis(Quaternion(Vector3.UP, span.normalized()))
					(line.mesh as CylinderMesh).height = span.length()
		, 0.0, 1.0, PROJECTILE_TIME)
		travel.tween_property(orb, "transparency", 1.0, 0.08)
	var dispose := root.create_tween()
	dispose.tween_interval(t + (0.1 if not is_beam else 0.02))
	dispose.tween_callback(root.queue_free)
	return root


static func _beam(parent: Node3D, a: Vector3, b: Vector3, radius: float,
		color: Color, alpha: float) -> MeshInstance3D:
	var line := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 6
	line.mesh = mesh
	line.material_override = _glow(color, alpha)
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line.position = (a + b) * 0.5
	line.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
	parent.add_child(line)
	return line


static func _glow(color: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.2
	m.no_depth_test = false
	return m
