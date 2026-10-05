shader_type spatial;
render_mode diffuse_toon, specular_disabled;
// Chão do diorama: a cor do vértice (terra, grama, cantos escuros) com manchas em três escalas. Na
// terra entra a textura pintada (pedrinhas, palha, pegadas) e na grama a de grama baixa, as duas
// tingidas pela cor do lugar.

// Terra batida, uma repetição a cada 4 m (UV = posição em metros × 0,25). Lida como está (sem
// conversão de cor), igual à cor do vértice, e dividida pela própria média: o resultado é só o
// detalhe, e a cor de cada lugar continua vindo do vértice.
uniform sampler2D dirt_albedo : filter_linear_mipmap_anisotropic, repeat_enable;
const vec3 DIRT_MEAN = vec3(138.0, 100.0, 64.0) / 255.0;
// Grama baixa, do mesmo jeito.
uniform sampler2D grass_albedo : filter_linear_mipmap_anisotropic, repeat_enable;
const vec3 GRASS_MEAN = vec3(66.0, 69.0, 42.0) / 255.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	// Manchas em três escalas (grande, média e fina), torcidas para não formar grade. Também
	// escondem a repetição da textura.
	vec2 warp = vec2(noise(p * 0.35 + 3.1), noise(p * 0.35 - 7.7)) * 2.0;
	float blotch = noise(p * 0.45 + warp) * 0.45 + noise(p * 1.7 + warp * 0.5) * 0.35 + noise(p * 6.5) * 0.2;
	vec3 color = COLOR.rgb * (0.8 + 0.34 * blotch);
	// Na terra (cor mais avermelhada): o detalhe da textura.
	float dirt = smoothstep(0.03, 0.09, COLOR.r - COLOR.g);
	vec3 detail = texture(dirt_albedo, p * 0.25).rgb / DIRT_MEAN;
	color *= mix(vec3(1.0), detail, dirt);
	// Na grama: o detalhe da textura de grama, com só 30% da cor dele (o resto é claro e escuro). As falhas
	// de terra da T2 vieram avermelhadas e, tingidas pela grama, ficavam manchas vermelhas.
	vec3 grass_detail = texture(grass_albedo, p * 0.25).rgb / GRASS_MEAN;
	float grass_light = dot(grass_detail, vec3(0.3, 0.59, 0.11));
	grass_detail = mix(vec3(grass_light), grass_detail, 0.3);
	color *= mix(grass_detail, vec3(1.0), dirt);
	ALBEDO = color;
	ROUGHNESS = 0.95;
}
