// Looping voxel fire and smoke: each MultiMesh cube rises, drifts and
// shrinks on its own clock (INSTANCE_CUSTOM: x phase, y speed, z sway),
// so burning hexes animate with no per-frame CPU work.
shader_type spatial;

uniform bool smoke = false;
uniform float rise = 0.4;
uniform vec4 hot : source_color = vec4(1.0, 0.86, 0.35, 1.0);
uniform vec4 cool : source_color = vec4(0.85, 0.18, 0.05, 1.0);
uniform vec4 soot : source_color = vec4(0.1, 0.095, 0.09, 1.0);

varying float life;

void vertex() {
	life = fract(TIME * INSTANCE_CUSTOM.y + INSTANCE_CUSTOM.x);
	float size = smoke ? mix(0.5, 1.4, life) * (1.0 - smoothstep(0.75, 1.0, life)) : mix(1.0, 0.1, life);
	VERTEX *= size;
	VERTEX.y += life * rise;
	VERTEX.x += sin(life * 6.0 + INSTANCE_CUSTOM.x * 20.0) * INSTANCE_CUSTOM.z;
	VERTEX.z += cos(life * 5.0 + INSTANCE_CUSTOM.x * 13.0) * INSTANCE_CUSTOM.z;
}

void fragment() {
	if (smoke) {
		ALBEDO = mix(soot.rgb, soot.rgb * 2.5, life);
		ROUGHNESS = 1.0;
	} else {
		vec3 c = mix(hot.rgb, cool.rgb, smoothstep(0.0, 0.8, life));
		ALBEDO = c;
		EMISSION = c * 0.8;
	}
}
