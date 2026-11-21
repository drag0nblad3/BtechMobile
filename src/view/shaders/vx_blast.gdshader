// One-shot voxel explosion. Each cube's INSTANCE_CUSTOM holds its velocity
// (xyz) and kind (w: 0 fireball, 0.5 smoke, 1 debris); `t` runs 0 -> 1.
shader_type spatial;

uniform float t = 0.0;
uniform float gravity = 3.0;
uniform vec4 hot : source_color = vec4(1.0, 0.9, 0.45, 1.0);
uniform vec4 burn : source_color = vec4(0.95, 0.3, 0.06, 1.0);
uniform vec4 smoke_color : source_color = vec4(0.08, 0.075, 0.07, 1.0);
uniform vec4 debris_color : source_color = vec4(0.12, 0.11, 0.1, 1.0);

varying float kind;

void vertex() {
	kind = INSTANCE_CUSTOM.w;
	vec3 v = INSTANCE_CUSTOM.xyz;
	float size;
	vec3 move;
	if (kind < 0.25) {  // fireball: bursts out fast, slows, burns away
		move = v * (1.0 - pow(1.0 - t, 3.0)) * 0.6;
		size = (1.0 + 3.0 * t) * (1.0 - smoothstep(0.3, 0.65, t));
	} else if (kind < 0.75) {  // smoke: swells and climbs, then thins out
		move = v * t * 0.5 + vec3(0.0, t * 0.6, 0.0);
		size = smoothstep(0.0, 0.25, t) * (1.0 + t) * (1.0 - smoothstep(0.75, 1.0, t));
	} else {  // debris: thrown, falls, tumbles
		move = v * t - vec3(0.0, gravity * t * t, 0.0);
		size = 1.0 - smoothstep(0.85, 1.0, t);
		float a = t * 12.0 * v.x;
		VERTEX.xy = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
	}
	VERTEX = VERTEX * size + move / length(MODEL_MATRIX[0].xyz);  // cube scale lives in the instance basis
}

void fragment() {
	if (kind < 0.25) {
		vec3 c = mix(hot.rgb, burn.rgb, smoothstep(0.05, 0.45, t));
		ALBEDO = c;
		EMISSION = c * 1.2;
	} else if (kind < 0.75) {
		ALBEDO = smoke_color.rgb * (1.0 + t);
		ROUGHNESS = 1.0;
	} else {
		ALBEDO = debris_color.rgb;
		EMISSION = burn.rgb * max(0.0, 0.6 - t) * 1.5;  // glowing hot at first
	}
}
