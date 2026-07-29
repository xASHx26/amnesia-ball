shader_type canvas_item;

uniform vec4 bg_color   : source_color = vec4(0.01, 0.01, 0.05, 1.0);
uniform vec4 star_color : source_color = vec4(0.65, 0.82, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float warp_speed    : hint_range(0.1, 4.0) = 1.4;
uniform float star_density  : hint_range(10.0, 120.0) = 55.0;
uniform float trail_length  : hint_range(0.01, 0.3) = 0.12;
uniform float brightness    : hint_range(0.5, 3.0) = 1.8;

float hash1(float n) {
	return fract(sin(n) * 43758.5453);
}
float hash2x(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	// Correct for non-square viewport
	uv.x *= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;

	float t = TIME * warp_speed;
	vec3 accum = bg_color.rgb;

	for (float i = 0.0; i < star_density; i += 1.0) {
		// Unique direction and depth per star
		float angle = hash1(i * 7.31 + 0.1) * 6.28318;
		vec2 dir = vec2(cos(angle), sin(angle));

		// Depth cycles 0→1 continuously
		float depth = fract(hash1(i * 3.17 + 0.5) + t * 0.14);

		// Stars accelerate as they come closer (depth → 1 = close)
		float ease = depth * depth;

		// Position: projected outward from center by depth
		float dist_from_center = ease * 1.6;
		vec2 pos = dir * dist_from_center;

		// Size: grows with depth
		float star_size = mix(0.003, 0.014, ease);

		// Streak: a thin line from origin toward current pos
		vec2 to_star = pos - vec2(0.0);
		float trail_half = trail_length * ease;
		vec2 along = normalize(to_star + 0.0001);
		vec2 perp  = vec2(-along.y, along.x);

		vec2 diff = uv - pos;
		float along_dist = dot(diff, -along);
		float perp_dist  = abs(dot(diff, perp));

		// Star dot
		float dot_dist = length(uv - pos);
		float dot_glow = smoothstep(star_size * 2.5, 0.0, dot_dist);

		// Trail streak
		float trail_mask = float(along_dist > 0.0 && along_dist < trail_half);
		float trail_fade = smoothstep(trail_half, 0.0, along_dist);
		float trail_thin = smoothstep(star_size * 0.8, 0.0, perp_dist);
		float trail_glow = trail_mask * trail_fade * trail_thin;

		float star_bright = clamp((dot_glow + trail_glow * 0.55) * (1.0 - depth * 0.25) * brightness, 0.0, 1.0);

		// Color: white core → star_color edges
		vec3 s_col = mix(core_color.rgb, star_color.rgb, clamp(dot_dist / (star_size * 3.0), 0.0, 1.0));
		accum += s_col * star_bright;
	}

	// Subtle radial vignette at edges
	float vig = 1.0 - smoothstep(0.6, 1.2, length(uv));
	accum = mix(bg_color.rgb * 0.4, accum, vig);

	COLOR = vec4(clamp(accum, 0.0, 1.5), 1.0);
}
