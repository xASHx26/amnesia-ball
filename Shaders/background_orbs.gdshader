shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.16, 0.04, 0.24, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.04, 0.02, 0.12, 1.0);
uniform vec4 orb_color : source_color = vec4(0.0, 0.9, 0.75, 0.35);
uniform float speed : hint_range(0.1, 3.0) = 0.5;

void fragment() {
	vec2 uv = UV;
	vec4 bg = mix(color_top, color_bottom, uv.y);
	
	float total_orb = 0.0;
	for (int i = 0; i < 7; i++) {
		float fi = float(i);
		vec2 center = vec2(
			0.2 + 0.6 * sin(fi * 1.7 + TIME * speed * 0.7),
			mod(1.0 - fi * 0.16 - TIME * speed * 0.18, 1.15) - 0.08
		);
		float dist = length(uv - center);
		float radius = 0.10 + 0.04 * sin(fi * 2.3 + TIME);
		total_orb += smoothstep(radius, 0.0, dist) * 0.55;
	}
	
	COLOR = bg + orb_color * total_orb;
}
