// Two slow cross-waves, shallow variation and modest specular response.
// Uses world position, not a per-tile texture, so adjacent water hexes join.
shader_type spatial;
render_mode cull_back;

uniform vec4 deep_color : source_color = vec4(0.075, 0.23, 0.33, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.19, 0.43, 0.49, 1.0);
uniform float opacity = 0.77;
uniform float speed = 0.55;
varying vec2 water_pos;

void vertex() {
	water_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float a = sin(water_pos.x * 2.5 + water_pos.y * 1.6 + TIME * speed);
	float b = sin(water_pos.x * -1.4 + water_pos.y * 3.2 - TIME * speed * 0.75);
	float ripple = 0.5 + 0.25 * a + 0.25 * b;
	float shine = pow(max(0.0, ripple), 5.0);
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, clamp(ripple, 0.0, 1.0));
	EMISSION = shallow_color.rgb * shine * 0.075;
	ROUGHNESS = 0.23;
	SPECULAR = 0.8;
	ALPHA = opacity;
}
