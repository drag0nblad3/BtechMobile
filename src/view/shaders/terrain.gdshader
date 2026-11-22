// Triplanar terrain: tops get a pattern per terrain type, sampled on a
// voxel-sized grid so the ground matches the voxel props; earthy cliff
// sides with strata. Instance COLOR tints by elevation.
// pattern: 0 grass, 1 rocks, 2 paving slabs, 3 rubble, 4 riverbed, 5 forest floor.
shader_type spatial;

uniform vec4 top_color : source_color = vec4(0.48, 0.6, 0.29, 1.0);
uniform vec4 detail_color : source_color = vec4(0.37, 0.5, 0.22, 1.0);
uniform vec4 side_color : source_color = vec4(0.42, 0.34, 0.25, 1.0);
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float tex_scale = 0.45;
uniform int pattern = 0;
uniform float pixel = 0.07;  // ground "voxel" size in world units

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 tint;
varying vec2 tile_local;
uniform float hex_radius = 0.97;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	tint = COLOR.rgb;
	tile_local = VERTEX.xz;
}

float tri_noise(vec3 p, vec3 n, float s) {
	vec3 w = abs(n);
	w /= (w.x + w.y + w.z);
	return texture(noise_tex, p.zy * s).r * w.x
		+ texture(noise_tex, p.xz * s).r * w.y
		+ texture(noise_tex, p.xy * s).r * w.z;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n2(vec2 p, float s) {
	return texture(noise_tex, p * s).r;
}

vec3 top_pattern(vec2 p) {
	vec2 q = (floor(p / pixel) + 0.5) * pixel;  // voxel-sized texels
	float big = n2(q, tex_scale);
	float fine = hash2(floor(p / pixel));
	vec3 base = mix(detail_color.rgb, top_color.rgb, smoothstep(0.3, 0.7, big));
	if (pattern == 0 || pattern == 5) {  // grass or leaf litter: speckled blades, bare patches
		base *= 0.95 + 0.1 * fine;
		float dirt = smoothstep(0.62, 0.7, n2(q + 17.0, tex_scale * 2.0));
		vec3 soil = pattern == 5 ? vec3(0.27, 0.2, 0.12) : vec3(0.36, 0.3, 0.2);
		base = mix(base, soil * (0.85 + 0.3 * fine), dirt * (pattern == 5 ? 0.8 : 0.55));
		if (fine > 0.96) base *= pattern == 5 ? 0.8 : 1.12;  // light blade tips / dark leaves
	} else if (pattern == 1) {  // rocks: stones split by dark cracks
		float stones = n2(q, tex_scale * 6.0);
		float crack = 1.0 - smoothstep(0.02, 0.06, abs(stones - 0.5));
		base *= 0.85 + 0.3 * smoothstep(0.3, 0.8, stones) + 0.08 * fine;
		base *= 1.0 - 0.45 * crack;
	} else if (pattern == 2) {  // paving: square slabs, joint lines, worn slabs
		vec2 slab = floor(p / 0.4);
		vec2 f = fract(p / 0.4);
		float joint = step(f.x, 0.05) + step(f.y, 0.05);
		base *= 0.88 + 0.2 * hash2(slab) + 0.06 * fine;
		base *= 1.0 - 0.35 * min(joint, 1.0);
		float crack = 1.0 - smoothstep(0.0, 0.03, abs(n2(q, tex_scale * 5.0) - 0.5));
		base *= 1.0 - 0.3 * crack * step(0.6, hash2(slab + 3.0));
	} else if (pattern == 3) {  // rubble: blocky chunks with deep gaps
		vec2 chunk = floor(p / 0.15);
		float h = hash2(chunk);
		base *= 0.7 + 0.5 * h + 0.06 * fine;
		vec2 f = fract(p / 0.15);
		base *= 1.0 - 0.5 * step(0.8, max(f.x, f.y)) * step(0.4, h);
		if (h > 0.9) base = mix(base, vec3(0.45, 0.25, 0.18), 0.5);  // brick fragments
	} else {  // riverbed pebbles
		base *= 0.8 + 0.35 * step(0.55, n2(q, tex_scale * 9.0)) + 0.08 * fine;
	}
	return base;
}

void fragment() {
	float fine = tri_noise(world_pos, world_normal, tex_scale * 4.0);
	vec3 side = side_color.rgb * (0.75 + 0.5 * fine);
	// Horizontal strata on cliff sides make levels readable.
	side *= 0.85 + 0.15 * step(0.5, fract(world_pos.y / 0.45));
	float is_top = smoothstep(0.6, 0.9, world_normal.y);
	vec3 top = is_top > 0.0 ? top_pattern(world_pos.xz) : vec3(0.0);
	// Shade just the inside of each hex rim. This creates a precise
	// readable grid without a second mesh or screen-space outlines.
	vec2 a = abs(tile_local);
	float edge = max(a.y / (0.8660254 * hex_radius),
			max(abs(tile_local.x + tile_local.y / 1.7320508),
				abs(tile_local.x - tile_local.y / 1.7320508)) / hex_radius);
	float rim = smoothstep(0.88, 0.99, edge);
	top *= 1.0 - 0.17 * rim;
	ALBEDO = mix(side, top, is_top) * tint;
	// Distant cliffs retain a subtle geological band instead of becoming
	// a monochrome vertical wall.
	ROUGHNESS = mix(1.0, 0.91, is_top);
}
