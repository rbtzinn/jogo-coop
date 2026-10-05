shader_type canvas_item;
// Palco da tela de carregamento: lâmpadas da moldura e do letreiro correndo em sequência de três, varais
// piscando soltos (mapa de tools/blender/loading_screen.py) e névoa passando devagar na rua do circo.
uniform sampler2D bulbs : filter_linear;
uniform sampler2D mist_noise : repeat_enable, filter_linear;
uniform float chase_speed = 0.9;
uniform vec3 glow_color : source_color = vec3(1.0, 0.78, 0.42);

float light_level(float code) {
	if (code < 0.5) {
		// Moldura e letreiro: fases 0, 1/3, 2/3 (gravadas em 0..0,45); um terço aceso por vez.
		float phase = code / 0.45 * (2.0 / 3.0);
		float wave = fract(phase - floor(TIME * chase_speed * 3.0) / 3.0);
		// Acesa agora, a que acabou de acender ainda morna e a próxima apagada: a luz anda.
		return wave < 0.1 ? 1.0 : (wave > 0.5 ? 0.7 : 0.38);
	}
	// Varais: cada lâmpada no seu ritmo, oscilando pouco.
	float seed = (code - 0.5) * 2.0;
	return 0.72 + 0.28 * sin(TIME * (1.7 + seed * 2.3) + seed * 37.0);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 map = texture(bulbs, UV).rgb;
	vec3 color = base.rgb;
	if (map.g > 0.003) {
		float level = light_level(map.b);
		float core = map.r;
		// Apagada: o vidro escurece e o brilho em volta diminui; acesa: o vidro estoura e o halo cresce.
		color *= mix(1.0, mix(0.42, 1.18, level), core);
		color *= mix(1.0, 0.82 + 0.18 * level, map.g * (1.0 - core));
		color += glow_color * map.g * map.g * max(level - 0.6, 0.0) * 0.9;
	}
	// Névoa: só na faixa da rua, atrás da barra.
	vec2 p = UV * vec2(1.6, 0.9);
	float mist = texture(mist_noise, p + vec2(TIME * 0.012, 0.0)).r * texture(mist_noise, p * 1.7 - vec2(TIME * 0.02, TIME * 0.004)).r;
	float band = smoothstep(0.52, 0.62, UV.y) * (1.0 - smoothstep(0.70, 0.80, UV.y)) * (1.0 - smoothstep(0.18, 0.34, abs(UV.x - 0.52)));
	color += vec3(0.55, 0.62, 0.78) * mist * band * 0.22;
	COLOR = vec4(color, base.a);
}
