shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 paint_primary : source_color = vec4(0.35, 0.45, 0.45, 1.0);
uniform vec4 paint_secondary : source_color = vec4(0.75, 0.70, 0.55, 1.0);
uniform vec4 badge_ink : source_color = vec4(0.97, 0.92, 0.78, 1.0);
uniform int paint_pattern = 1;
uniform int badge_shape = 4;

// Per-part instance parameters: dozens of articulated parts can use one
// cached material while their markings stay aligned with their own armor.
instance uniform vec3 paint_origin = vec3(0.0);
instance uniform vec3 panel_min = vec3(0.0);
instance uniform vec3 panel_span = vec3(1.0);
instance uniform float badge_enabled = 0.0;

varying vec3 paint_pos;
varying vec3 paint_normal;

void vertex() {
	paint_pos = VERTEX + paint_origin;
	paint_normal = NORMAL;
}

void fragment() {
	vec3 authored = COLOR.rgb;
	ALBEDO = authored;
	ROUGHNESS = 0.79;
	METALLIC = 0.15;
	// UV2.x is the armor/structure role from the mesher. Weapons, joints,
	// exposed internals and scorched cavities keep their authored colors.
	if (UV2.x < 0.5) {
		return;
	}
	vec3 span = max(panel_span, vec3(0.01));
	vec3 rel = (paint_pos - panel_min) / span;
	float accent = 0.0;
	if (paint_pattern == 1) { // broad diagonal sash
		accent = 1.0 - step(0.16, abs(rel.y - (0.21 + 0.62 * rel.x)));
	} else if (paint_pattern == 2) { // paired horizontal unit stripes
		accent = 1.0 - step(0.07, min(abs(rel.y - 0.33), abs(rel.y - 0.41)));
	} else if (paint_pattern == 3) { // split panel
		accent = step(0.59, rel.x);
	} else if (paint_pattern == 4) { // large-scale irregular camouflage
		vec2 block = floor(paint_pos.xz * 6.0 + paint_pos.y * 2.0);
		accent = step(0.56, fract(sin(dot(block, vec2(12.7, 78.2))) * 43758.5));
	}
	float source_value = clamp(dot(authored, vec3(0.30, 0.59, 0.11)) * 1.65, 0.57, 1.05);
	vec3 armor = mix(authored, paint_primary.rgb * source_value, 0.87);
	armor = mix(armor, paint_secondary.rgb * source_value, accent * 0.86);

	// Recessed-on-surface geometric field badge, front of the main torso
	// plates only. No projector, polygon, decal plane or floating geometry.
	if (badge_enabled > 0.5 && paint_normal.z < -0.9 &&
			paint_pos.z < panel_min.z + max(0.07, panel_span.z * 0.28)) {
		vec2 glyph = (rel.xy - vec2(0.5, 0.64)) * vec2(2.2, 2.6);
		float radius = length(glyph);
		if (radius < 0.58) {
			armor = mix(armor, paint_secondary.rgb * 0.64, 0.92);
			float ink = 0.0;
			if (badge_shape == 1) { // three claw cuts
				float slash = glyph.x + glyph.y * 0.39;
				ink = 1.0 - step(0.065, min(abs(slash + 0.28), min(abs(slash), abs(slash - 0.28))));
			} else if (badge_shape == 2) { // spread wings
				ink = 1.0 - step(0.12, abs(abs(glyph.y) - (0.43 - abs(glyph.x) * 0.7)));
			} else if (badge_shape == 3) { // sun / starburst
				float rays = abs(sin(atan(glyph.y, glyph.x) * 4.0));
				ink = 1.0 - step(0.12, radius);
				ink = max(ink, step(0.9, rays) * (1.0 - step(0.48, radius)));
			} else if (badge_shape == 4) { // diamond
				ink = 1.0 - step(0.10, abs(abs(glyph.x) + abs(glyph.y) - 0.47));
			} else if (badge_shape == 5) { // spear / pennant
				ink = 1.0 - step(0.10, abs(abs(glyph.x) - (0.48 - glyph.y) * 0.45));
				ink *= step(-0.42, glyph.y) * (1.0 - step(0.42, glyph.y));
			} else { // cross
				ink = max(1.0 - step(0.105, abs(glyph.x)), 1.0 - step(0.105, abs(glyph.y)));
			}
			armor = mix(armor, badge_ink.rgb, ink * 0.97);
		}
	}
	ALBEDO = armor;
}
