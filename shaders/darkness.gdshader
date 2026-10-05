// Escuridão com holofotes: pinta a tela de preto, menos dentro de dois círculos de luz
// (um em cada jogador). Usado no Blackout do Grande Mágico.
shader_type canvas_item;

uniform vec2 rect_size = vec2(1920.0, 1080.0);
uniform vec2 light_a = vec2(-9999.0);
uniform vec2 light_b = vec2(-9999.0);
uniform float radius_a = 240.0;
uniform float radius_b = 240.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;

float spot(vec2 p, vec2 center, float radius) {
	float d = distance(p, center);
	return 1.0 - smoothstep(radius * 0.7, radius, d);
}

void fragment() {
	vec2 p = UV * rect_size;
	float lit = max(spot(p, light_a, radius_a), spot(p, light_b, radius_b));
	COLOR = vec4(0.02, 0.01, 0.03, darkness * (1.0 - lit) * 0.95);
}
