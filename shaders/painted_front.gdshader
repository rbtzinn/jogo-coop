// Camada da frente do mapa pintado (PaintedWorld): o que é alto no desenho (pedras, cristais, postes) fica na
// profundidade do chão no pé dele, e o personagem que anda atrás some atrás. A mesma malha da pintura; cada
// parte do mapa é uma superfície com este material. Dados em tools/front_layer.py.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

// A parte do mapa (a cor).
uniform sampler2D albedo : source_color, filter_linear, repeat_disable;
// Camada da frente do mapa inteiro: R + G * 256 = linha do pé (y em pixels), A = alto.
uniform sampler2D front : filter_nearest, repeat_disable;
// Canto e tamanho desta parte no mapa inteiro (pixels).
uniform vec2 part_corner;
uniform vec2 part_size;
uniform vec2 image_size;
// Metros de chão por pixel e o seno da inclinação da câmera (PaintedWorld.pixel_to_world).
uniform float meters_per_pixel;
uniform float sin_pitch;

void fragment() {
	vec2 pixel = part_corner + UV * part_size;
	vec4 data = texelFetch(front, ivec2(clamp(pixel, vec2(0.0), image_size - 1.0)), 0);
	if (data.a < 0.5) {
		discard;
	}
	float foot = round(data.r * 255.0) + round(data.g * 255.0) * 256.0;
	vec2 rel = (vec2(pixel.x, foot) - image_size * 0.5) * meters_per_pixel;
	vec4 ground = vec4(rel.x, 0.0, rel.y / sin_pitch, 1.0);
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * ground;
	float ndc = clip.z / clip.w;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	DEPTH = ndc * 0.5 + 0.5;
#else
	DEPTH = ndc;
#endif
	ALBEDO = texture(albedo, UV).rgb;
}
