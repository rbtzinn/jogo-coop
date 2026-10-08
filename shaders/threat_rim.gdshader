shader_type canvas_item;

// Silhueta de cor única (o contorno claro atrás dos ataques de chefão): o desenho vira uma mancha da cor
// `rim`, usando só o alpha dele. Desenhada um pouco maior atrás do desenho de verdade.
uniform vec4 rim : source_color = vec4(1.0, 0.95, 0.82, 0.9);

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(rim.rgb, rim.a * alpha) * vec4(1.0, 1.0, 1.0, COLOR.a);
}
