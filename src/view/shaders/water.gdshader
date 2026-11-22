// Mobile-friendly water: soft shoreline shallows and two intersecting wave
// bands. The shader runs only on water caps; no extra render passes or textures.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

uniform vec4 deep_color : source_color = vec4(0.065, 0.18, 0.27, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.12, 0.39, 0.46, 1.0);
uniform vec4 foam_color : source_color = vec4(0.45, 0.67, 0.70, 1.0);
uniform float wave_speed = 0.7;

varying vec2 field;
varying vec2 local_hex;
varying float depth_tint;

void vertex() {
	field = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	local_hex = VERTEX.xz;
	depth_tint = COLOR.r;
}

void fragment() {
	// Hex apothem for a unit-radius hex is sqrt(3) / 2. This masks the
	// shoreline without introducing visible circular rims or new geometry.
	vec2 p = local_hex;
	float rim = max(abs(p.y), max(abs(0.8660254 * p.x + 0.5 * p.y),
								 abs(0.8660254 * p.x - 0.5 * p.y)));
	float shore = smoothstep(0.68, 0.86, rim);
	float w1 = sin(field.x * 12.0 + field.y * 4.5 + TIME * wave_speed * 2.2);
	float w2 = sin(field.y * 14.0 - field.x * 3.0 - TIME * wave_speed * 1.65);
	float crests = smoothstep(1.0, 1.8, w1 + w2);
	vec3 water = mix(deep_color.rgb, shallow_color.rgb, 0.4 + shore * 0.55);
	water *= depth_tint;
	water = mix(water, foam_color.rgb * depth_tint, crests * 0.19 + shore * 0.12);
	ALBEDO = water;
	ROUGHNESS = 0.23;
	METALLIC = 0.07;
	SPECULAR = 0.7;
	EMISSION = shallow_color.rgb * crests * 0.07 * depth_tint;
	ALPHA = 0.78 + shore * 0.12;
}
