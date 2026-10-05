shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;
// Contorno de tinta (casca invertida): o mesmo objeto um pouco inflado, só as costas, na cor da tinta.
// Usado como "next_pass" dos materiais das miniaturas e do cenário. A espessura é em metros do mundo
// (desfaz a escala do objeto, para esferas achatadas terem o mesmo traço).

uniform vec4 ink : source_color = vec4(0.106, 0.078, 0.063, 1.0);
uniform float thickness = 0.012;

void vertex() {
	vec3 s = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	VERTEX += NORMAL * thickness / max(s, vec3(0.0001));
}

void fragment() {
	ALBEDO = ink.rgb;
}
