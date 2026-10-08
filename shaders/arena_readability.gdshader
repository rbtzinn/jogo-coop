shader_type canvas_item;

// Afasta o cenário para trás sem cobri-lo: menos cor, menos contraste e menos brilho competindo
// com jogadores, chefão, avisos e projéteis no primeiro plano.
uniform float saturation : hint_range(0.0, 1.0) = 0.58;
uniform float contrast : hint_range(0.0, 1.5) = 0.78;
uniform float brightness : hint_range(0.0, 1.2) = 0.76;
uniform vec3 cool_tint = vec3(0.92, 0.94, 1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float lightness = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 color = mix(vec3(lightness), source.rgb, saturation);
	color = (color - vec3(0.5)) * contrast + vec3(0.5);
	color *= brightness * cool_tint;
	COLOR = vec4(color, source.a) * COLOR;
}
