shader_type spatial;
render_mode diffuse_toon, specular_toon;
// Lona listrada do circo (tendas, toldos), com sombra em degraus como o resto do mundo, um pouco de
// sujeira de baixo para cima e variação de tinta.

uniform vec4 color_a : source_color = vec4(0.64, 0.16, 0.16, 1.0);
uniform vec4 color_b : source_color = vec4(0.95, 0.9, 0.8, 1.0);
uniform float stripes = 12.0;
// Escurece a parte de baixo (terra respingada), 0 = nada.
uniform float grime = 0.25;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float band = step(0.5, fract(UV.x * stripes));
	vec3 color = mix(color_a.rgb, color_b.rgb, band);
	color *= 1.0 - grime * smoothstep(0.55, 1.0, UV.y);
	color *= 0.94 + 0.12 * hash(floor(UV * vec2(80.0, 40.0)));
	ALBEDO = color;
	ROUGHNESS = 0.85;
	RIM = 0.15;
	RIM_TINT = 0.6;
}
