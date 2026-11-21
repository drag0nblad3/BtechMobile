// Voxel trees and plants: vertex colours (written as sRGB) with a gentle
// wind sway that grows with height. Instances sway out of step.
shader_type spatial;
render_mode cull_back;

uniform float sway = 0.035;
uniform float brightness = 0.9;

void vertex() {
	vec3 root = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float s = sin(TIME * 1.4 + root.x * 0.8 + root.z * 1.1) * sway * max(VERTEX.y, 0.0);
	VERTEX.x += s;
	VERTEX.z += s * 0.6;
}

void fragment() {
	ALBEDO = pow(COLOR.rgb, vec3(2.2)) * brightness;
	ROUGHNESS = 1.0;
}
