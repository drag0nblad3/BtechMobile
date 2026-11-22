shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

// A single translucent interference plane: no screen texture, no refraction,
// no extra mobile framebuffer copies. Does not modify terrain or visibility.
uniform float strength = 0.5;
void fragment() {
	vec2 q = UV * 26.0;
	float ripple = sin(q.x * 3.1 + TIME * 2.9 + sin(q.y * 1.7 - TIME));
	ALBEDO = vec3(0.98, 0.61, 0.37);
	ALPHA = strength * (0.012 + 0.012 * max(0.0, ripple));
}
