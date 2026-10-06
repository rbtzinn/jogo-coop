shader_type spatial;
// Sombra de contato redonda e macia embaixo de quem anda no mapa (sem luz nem sombra projetada).
render_mode unshaded, blend_mix, depth_draw_never;

uniform float strength = 0.45;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	ALBEDO = vec3(0.04, 0.02, 0.05);
	ALPHA = strength * (1.0 - smoothstep(0.2, 1.0, d));
}
