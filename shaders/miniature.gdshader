shader_type spatial;
render_mode diffuse_toon, specular_toon;
// Miniatura pintada (mundo 3D): cor chapada com sombra em degraus (toon), um brilho de verniz e uma
// luz de borda quente, como bonequinho de chumbo pintado à mão. Opcional: losangos de arlequim
// (palhaço) e variação suave de tinta.

uniform vec4 albedo : source_color = vec4(0.8, 0.2, 0.2, 1.0);
uniform vec4 pattern_color : source_color = vec4(0.95, 0.9, 0.8, 1.0);
// 0 = sem desenho; > 0 = número de losangos em volta (arlequim).
uniform float diamonds = 0.0;
// > 0 = número de quadrados em volta (xadrez do palhaço).
uniform float checker = 0.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.55;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec4 rim_color : source_color = vec4(1.0, 0.85, 0.6, 1.0);
uniform float paint_noise : hint_range(0.0, 0.2) = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 color = albedo.rgb;
	if (diamonds > 0.0) {
		vec2 uv = vec2(UV.x * diamonds, UV.y * diamonds * 0.5);
		vec2 cell = abs(fract(uv) - 0.5);
		float d = step(cell.x + cell.y, 0.5);
		float parity = mod(floor(uv.x) + floor(uv.y), 2.0);
		color = mix(color, pattern_color.rgb, abs(d - parity));
	}
	if (checker > 0.0) {
		vec2 uv = vec2(UV.x * checker * 2.0, UV.y * checker);
		float parity = mod(floor(uv.x) + floor(uv.y), 2.0);
		color = mix(color, pattern_color.rgb, parity);
	}
	float n = hash(floor(UV * 64.0));
	color *= 1.0 - paint_noise + paint_noise * 2.0 * n;
	ALBEDO = color;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.4;
	RIM = rim_strength;
	RIM_TINT = 0.6;
}
