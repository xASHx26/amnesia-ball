shader_type canvas_item;

uniform vec4 color_top    : source_color = vec4(0.02, 0.04, 0.06, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.05, 0.06, 0.10, 1.0);
uniform vec4 phosphor_tint: source_color = vec4(0.0, 0.06, 0.03, 1.0);
uniform float scanline_density  : hint_range(60.0, 600.0) = 220.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float vignette_strength : hint_range(0.0, 3.0) = 1.1;
uniform float flicker_speed     : hint_range(0.0, 8.0) = 3.0;
uniform float noise_amount      : hint_range(0.0, 0.1) = 0.025;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// Slight barrel distortion for CRT curvature
	vec2 cuv = uv * 2.0 - 1.0;
	cuv *= 1.0 + dot(cuv, cuv) * 0.04;
	uv = cuv * 0.5 + 0.5;

	// Out-of-bounds → black (CRT edge)
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	// Vertical background gradient
	vec4 bg = mix(color_top, color_bottom, uv.y);

	// Horizontal scanlines
	float scan = sin(uv.y * scanline_density * 3.14159265) * 0.5 + 0.5;
	scan = pow(scan, 1.8);
	bg.rgb -= scan * scanline_strength;

	// Faint vertical noise bars
	float noise_col = rand(vec2(floor(uv.x * 120.0), floor(TIME * 8.0))) * noise_amount;
	bg.rgb += noise_col;

	// Subtle phosphor color shift per channel (RGB triad simulation)
	float r_shift = sin(uv.x * 320.0 * 3.14159265) * 0.5 + 0.5;
	bg.r += r_shift * 0.012;
	bg.b += (1.0 - r_shift) * 0.01;

	// CRT flicker
	float flicker = 1.0 + sin(TIME * flicker_speed * 47.0) * 0.008;
	bg.rgb *= flicker;

	// Phosphor tint overlay
	bg.rgb += phosphor_tint.rgb * 0.7;

	// Vignette (darkens edges)
	vec2 vig_uv = uv * 2.0 - 1.0;
	float vig = 1.0 - dot(vig_uv * 0.55, vig_uv * 0.55);
	vig = clamp(pow(max(vig, 0.0), vignette_strength), 0.0, 1.0);
	bg.rgb *= vig;

	// Reflection glare at very top
	float glare = smoothstep(0.95, 1.0, 1.0 - uv.y) * 0.06;
	bg.rgb += glare;

	COLOR = clamp(bg, 0.0, 1.0);
}
