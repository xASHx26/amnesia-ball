shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.06, 0.04, 0.14, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.12, 0.08, 0.25, 1.0);
uniform vec4 grid_color : source_color = vec4(0.3, 0.5, 0.9, 0.15);
uniform vec4 glow_color : source_color = vec4(0.0, 0.8, 1.0, 0.25);
uniform float grid_scale : hint_range(10.0, 100.0) = 40.0;
uniform float speed : hint_range(0.1, 5.0) = 0.5;

void fragment() {
	vec2 uv = UV;
	
	// Vertical background gradient
	vec4 bg_color = mix(color_top, color_bottom, uv.y);
	
	// Scrolling UVs for moving grid pattern
	vec2 st = uv * grid_scale;
	st.y += TIME * speed * 2.0;
	st.x += sin(TIME * speed * 0.5 + uv.y * 3.0) * 1.5;
	
	// Grid line calculation
	vec2 grid = abs(fract(st - 0.5) - 0.5) / fwidth(st);
	float line = min(grid.x, grid.y);
	float grid_pattern = 1.0 - min(line, 1.0);
	
	// Floating glowing wave light
	float wave = sin(uv.y * 6.0 - TIME * 1.5) * 0.5 + 0.5;
	wave *= cos(uv.x * 4.0 + TIME * 0.8) * 0.5 + 0.5;
	
	// Combine layers
	vec4 final_color = bg_color;
	final_color += grid_color * grid_pattern;
	final_color += glow_color * wave * 0.35;
	
	COLOR = final_color;
}
