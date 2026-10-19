shader_type canvas_item;
// Fundo provisório do Maestro Ferrugem, todo em código: parede de oficina verde-petróleo manchada de
// ferrugem, luz quente de refletor no meio do palco, assoalho de tábuas e vinheta nos cantos.
// Vai num ColorRect do tamanho da arena (1920x1080); `floor_line` é o chão em fração da altura.

uniform float floor_line = 0.861;
uniform vec3 wall_top : source_color = vec3(0.055, 0.09, 0.09);
uniform vec3 wall_low : source_color = vec3(0.12, 0.2, 0.19);
uniform vec3 rust : source_color = vec3(0.45, 0.22, 0.09);
uniform vec3 plank : source_color = vec3(0.36, 0.22, 0.12);
uniform vec3 light_color : source_color = vec3(1.0, 0.83, 0.55);
uniform vec2 spot = vec2(0.42, 0.86);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	vec2 px = uv * vec2(1920.0, 1080.0);
	vec3 color;
	if (uv.y < floor_line) {
		// Parede: gradiente, painéis verticais rebitados e manchas de ferrugem escorrendo.
		color = mix(wall_top, wall_low, smoothstep(0.0, floor_line, uv.y));
		float panel = fract(px.x / 240.0);
		color *= 0.88 + 0.12 * smoothstep(0.0, 0.02, panel) * smoothstep(1.0, 0.98, panel);
		float stain = fbm(vec2(px.x / 90.0, px.y / 380.0)) * fbm(px / 160.0 + 7.0);
		color = mix(color, rust * 0.7, smoothstep(0.28, 0.5, stain) * 0.55);
		color *= 0.92 + 0.16 * fbm(px / 18.0);
		// Rebites na junta dos painéis.
		vec2 rivet = vec2(mod(px.x + 6.0, 240.0) - 6.0, mod(px.y, 60.0) - 30.0);
		color += vec3(0.12, 0.1, 0.06) * smoothstep(5.0, 3.0, length(rivet));
		// Sombra de rodapé.
		color *= mix(1.0, 0.55, smoothstep(floor_line - 0.06, floor_line, uv.y));
	} else {
		// Assoalho: tábuas compridas com veio e frestas escuras.
		float row = floor((px.y - floor_line * 1080.0) / 26.0);
		float offset = hash(vec2(row, 3.0)) * 400.0;
		float board = fract((px.x + offset) / 400.0);
		color = plank * (0.8 + 0.3 * hash(vec2(row, floor((px.x + offset) / 400.0))));
		color *= 0.85 + 0.25 * fbm(vec2(px.x / 60.0, px.y / 6.0));
		color *= smoothstep(0.0, 0.006, board) * 0.6 + 0.4;
		color *= 0.7 + 0.3 * smoothstep(0.0, 0.25, fract((px.y - floor_line * 1080.0) / 26.0));
		// Beira do palco clara.
		color += vec3(0.25, 0.18, 0.1) * smoothstep(6.0, 0.0, px.y - floor_line * 1080.0);
	}
	// Refletor quente: cone do alto e poça de luz no palco.
	vec2 to_spot = (uv - spot) * vec2(1.78, 1.0);
	float pool = smoothstep(0.55, 0.0, length(to_spot * vec2(0.8, 2.4)));
	float cone = smoothstep(0.32, 0.0, abs(uv.x - mix(0.5, spot.x, uv.y)) - uv.y * 0.12) * (1.0 - uv.y * 0.6);
	color += light_color * (pool * 0.35 + cone * 0.08);
	// Vinheta.
	float edge = length((uv - vec2(0.5, 0.45)) * vec2(1.2, 1.0));
	color *= mix(1.0, 0.45, smoothstep(0.45, 0.85, edge));
	COLOR = vec4(color, 1.0);
}
