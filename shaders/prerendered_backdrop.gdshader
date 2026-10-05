shader_type spatial;
// Cenário pré-renderizado (tools/blender/park_render.py) visto por uma câmera ortográfica com o mesmo
// ângulo do Blender: cada pixel mostra a cor renderizada e grava a profundidade renderizada, então os
// bonecos 3D ficam atrás ou na frente do cenário como se ele fosse de verdade. Fica num quadrado
// preso à frente da câmera; a posição da câmera escolhe que pedaço da imagem aparece.
render_mode unshaded, cull_disabled, depth_draw_always, shadows_disabled, fog_disabled;

uniform sampler2D color_texture : source_color, filter_linear, repeat_disable;
// Profundidade em 16 bits: R = byte alto, G = byte baixo, entre depth_range.x e depth_range.y metros.
uniform sampler2D depth_texture : filter_nearest, repeat_disable;
// Centro da câmera do Blender no mundo, tamanho da imagem em metros e eixos da câmera.
uniform vec3 origin;
uniform vec2 span;
uniform vec2 depth_range;
uniform vec3 axis_right;
uniform vec3 axis_up;
uniform vec3 axis_forward;

void fragment() {
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 rel = world - origin;
	vec2 uv = vec2(dot(rel, axis_right) / span.x + 0.5, 0.5 - dot(rel, axis_up) / span.y);
	ALBEDO = texture(color_texture, uv).rgb;
	vec2 packed = texture(depth_texture, uv).rg;
	float q = (floor(packed.r * 255.0 + 0.5) * 256.0 + floor(packed.g * 255.0 + 0.5)) / 65535.0;
	// Distância do cenário a este quadrado, ao longo do olhar da câmera.
	float ahead = mix(depth_range.x, depth_range.y, q) - dot(rel, axis_forward);
	vec4 clip = PROJECTION_MATRIX * vec4(VERTEX.xy, VERTEX.z - ahead, 1.0);
	float ndc = clip.z / clip.w;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	DEPTH = ndc * 0.5 + 0.5;
#else
	DEPTH = ndc;
#endif
}
