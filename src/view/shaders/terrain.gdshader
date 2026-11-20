// Triplanar terrain: noise-textured tops in the terrain's colors,
// earthy cliff sides. Instance COLOR tints by elevation.
shader_type spatial;

uniform vec4 top_color : source_color = vec4(0.48, 0.6, 0.29, 1.0);
uniform vec4 detail_color : source_color = vec4(0.37, 0.5, 0.22, 1.0);
uniform vec4 side_color : source_color = vec4(0.42, 0.34, 0.25, 1.0);
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float tex_scale = 0.45;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 tint;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	tint = COLOR.rgb;
}

float tri_noise(vec3 p, vec3 n, float s) {
	vec3 w = abs(n);
	w /= (w.x + w.y + w.z);
	return texture(noise_tex, p.zy * s).r * w.x
		+ texture(noise_tex, p.xz * s).r * w.y
		+ texture(noise_tex, p.xy * s).r * w.z;
}

void fragment() {
	float n = tri_noise(world_pos, world_normal, tex_scale);
	float fine = tri_noise(world_pos, world_normal, tex_scale * 4.0);
	vec3 top = mix(detail_color.rgb, top_color.rgb, smoothstep(0.3, 0.7, n));
	vec3 side = side_color.rgb * (0.75 + 0.5 * fine);
	// Horizontal strata on cliff sides make levels readable.
	side *= 0.85 + 0.15 * step(0.5, fract(world_pos.y / 0.45));
	float is_top = smoothstep(0.6, 0.9, world_normal.y);
	ALBEDO = mix(side, top * (0.85 + 0.3 * fine), is_top) * tint;
	ROUGHNESS = 0.95;
}
