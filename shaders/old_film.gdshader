// Filtro de filme antigo aplicado na tela toda: leve sépia, grão, tremulação,
// arranhões e vinheta. Intensidades controladas pela qualidade gráfica.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float sepia_amount : hint_range(0.0, 1.0) = 0.15;
uniform float grain_amount : hint_range(0.0, 0.3) = 0.07;
uniform float flicker_amount : hint_range(0.0, 0.2) = 0.03;
uniform float scratch_amount : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_amount : hint_range(0.0, 2.0) = 0.7;
uniform float frames_per_second = 24.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float frame = floor(TIME * frames_per_second);

	vec3 sepia = vec3(
		dot(color, vec3(0.393, 0.769, 0.189)),
		dot(color, vec3(0.349, 0.686, 0.168)),
		dot(color, vec3(0.272, 0.534, 0.131)));
	color = mix(color, sepia, sepia_amount);

	color *= 1.0 + (hash(vec2(frame, 1.7)) - 0.5) * flicker_amount;

	float grain = hash(floor(SCREEN_UV * vec2(960.0, 540.0)) + frame * 13.1) - 0.5;
	color += grain * grain_amount;

	if (scratch_amount > 0.0) {
		float x = hash(vec2(frame, 4.2));
		float visible = step(1.0 - scratch_amount * 0.35, hash(vec2(frame, 9.1)));
		float line = 1.0 - smoothstep(0.0, 0.0012, abs(SCREEN_UV.x - x));
		color = mix(color, vec3(0.95, 0.9, 0.78), line * visible * 0.35);
	}

	vec2 centered = SCREEN_UV - 0.5;
	float vignette = 1.0 - dot(centered, centered) * vignette_amount * 1.4;
	color *= clamp(vignette, 0.0, 1.0);

	COLOR = vec4(color, 1.0);
}
