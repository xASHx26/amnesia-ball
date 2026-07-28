shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.08, 0.04, 0.16, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.02, 0.10, 0.20, 1.0);
uniform vec4 hex_color : source_color = vec4(0.2, 0.8, 1.0, 0.2);
uniform float hex_scale : hint_range(5.0, 50.0) = 22.0;
uniform float speed : hint_range(0.1, 3.0) = 0.5;

vec4 hex_coords(vec2 uv) {
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	vec2 id = uv - gv;
	return vec4(gv.x, gv.y, id.x, id.y);
}

void fragment() {
	vec2 uv = UV * hex_scale;
	uv.y += TIME * speed;
	vec4 hc = hex_coords(uv);
	
	float edge = smoothstep(0.0, 0.06, abs(max(abs(hc.x), abs(hc.y) * 0.866025 + abs(hc.x) * 0.5) - 0.46));
	float pulse = sin(hc.z * 2.5 + hc.w * 2.5 + TIME * 2.0) * 0.5 + 0.5;
	
	vec4 bg = mix(color_top, color_bottom, UV.y);
	COLOR = bg + hex_color * (1.0 - edge) * (0.35 + pulse * 0.65);
}
