shader_type canvas_item;
// Personagem recortado da pintura que ganha vida sem quadros novos: respira (estica a partir dos pés),
// balança o tronco, mexe os dois braços em volta do ombro e pisca (a pálpebra cobre o branco do olho).
// Tudo é deslocamento da imagem; os pés ficam parados no chão. Medidas em pixels do recorte.
uniform vec2 sprite_size;
uniform float feet;
uniform float breath = 0.010;
uniform float sway = 0.006;
uniform float tempo = 1.0;
uniform float phase = 0.0;
// Braços: ombro.xy, mão.xy; raio da área que acompanha; amplitude (radianos).
uniform vec4 arm0;
uniform float arm0_radius;
uniform float arm0_swing = 0.05;
uniform vec4 arm1;
uniform float arm1_radius;
uniform float arm1_swing = 0.04;
// Olhos: centro.xy e raios por fora do traço; quanto a pálpebra fechou (0 aberto, 1 fechado).
uniform vec4 eye0;
uniform vec4 eye1;
uniform float blink = 0.0;
uniform vec3 skin : source_color;
uniform vec3 ink : source_color = vec3(0.07, 0.04, 0.03);

vec2 rotate_about(vec2 p, vec2 pivot, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	vec2 v = p - pivot;
	return pivot + vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

vec2 bend_arm(vec2 p, vec4 arm, float radius, float angle) {
	vec2 axis = arm.zw - arm.xy;
	vec2 v = p - arm.xy;
	float t = dot(v, axis) / dot(axis, axis);
	float dist = length(v - axis * clamp(t, 0.0, 1.0));
	float weight = smoothstep(-0.05, 0.4, t) * (1.0 - smoothstep(radius, radius * 1.7, dist));
	return rotate_about(p, arm.xy, -angle * weight);
}

vec4 eyelid(vec4 color, vec2 p, vec4 eye) {
	// A pálpebra cobre também o traço em volta do olho.
	vec2 radii = eye.zw * 1.2;
	vec2 e = (p - eye.xy) / radii;
	if (blink <= 0.01 || dot(e, e) > 1.0) {
		return color;
	}
	// O nariz vermelho na frente do olho continua na frente.
	if (color.r > 0.6 && color.g < 0.35) {
		return color;
	}
	// As duas pálpebras se encontram numa curva abaixo do meio: o olho fechado sorrindo.
	float meet = 0.05 + 0.3 * (1.0 - e.x * e.x);
	float upper = mix(-1.2, meet, blink);
	float lower = mix(1.2, meet, blink);
	float edge = min(abs(e.y - upper), abs(e.y - lower)) * radii.y;
	float line = 1.0 - smoothstep(1.6, 2.8, edge);
	if (e.y > upper && e.y < lower) {
		return vec4(mix(color.rgb, ink, line), color.a);
	}
	// Some nas pontas da elipse para não deixar um corte reto na pele.
	float rim = smoothstep(0.82, 1.0, dot(e, e));
	return vec4(mix(mix(skin, ink, line * (1.0 - rim)), color.rgb, rim), color.a);
}

void fragment() {
	vec2 p = UV * sprite_size;
	float t = TIME * tempo + phase;
	float up = clamp((feet - p.y) / feet, 0.0, 1.0);
	// Respiração: o desenho estica um pouco para cima a partir dos pés.
	float stretch = 1.0 + breath * sin(t * 2.1);
	p.y = feet - (feet - p.y) / stretch;
	// Balanço: o alto do corpo vai de um lado para o outro, os pés não saem do lugar.
	p.x -= sway * feet * sin(t * 1.05) * up * up;
	p = bend_arm(p, arm0, arm0_radius, arm0_swing * sin(t * 1.6 + 0.6));
	p = bend_arm(p, arm1, arm1_radius, arm1_swing * sin(t * 1.3 + 2.1));
	vec4 color = texture(TEXTURE, p / sprite_size);
	if (p.x < 0.0 || p.y < 0.0 || p.x > sprite_size.x || p.y > sprite_size.y) {
		color = vec4(0.0);
	}
	color = eyelid(color, p, eye0);
	color = eyelid(color, p, eye1);
	COLOR = color;
}
