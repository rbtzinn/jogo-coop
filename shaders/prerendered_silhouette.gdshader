shader_type spatial;
// Silhueta de quem está atrás do cenário pré-renderizado (camada extra, material_overlay): só aparece
// onde a profundidade gravada no Blender fica na frente do boneco. Os mesmos dados do fundo
// (shaders/prerendered_backdrop.gdshader).
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform sampler2D depth_texture : filter_nearest, repeat_disable;
uniform vec3 origin;
uniform vec2 span;
uniform vec2 depth_range;
uniform vec3 axis_right;
uniform vec3 axis_up;
uniform vec3 axis_forward;
uniform vec4 tint : source_color = vec4(1.0, 0.82, 0.48, 0.55);

void fragment() {
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 rel = world - origin;
	vec2 uv = vec2(dot(rel, axis_right) / span.x + 0.5, 0.5 - dot(rel, axis_up) / span.y);
	vec2 packed = texture(depth_texture, uv).rg;
	float q = (floor(packed.r * 255.0 + 0.5) * 256.0 + floor(packed.g * 255.0 + 0.5)) / 65535.0;
	float scenery = mix(depth_range.x, depth_range.y, q);
	if (dot(rel, axis_forward) < scenery + 0.08) {
		discard;
	}
	ALBEDO = tint.rgb;
	ALPHA = tint.a;
}
