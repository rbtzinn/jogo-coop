extends Node2D
## Palco PROVISÓRIO do Maestro, todo em código (até chegar o cenário pintado): parede e assoalho no shader
## shaders/maestro_stage.gdshader, órgão de tubos e cortinas desenhados aqui e o metrônomo do palco marcando o
## compasso da luta. Fica atrás de toda a ação; nada aqui machuca nem bloqueia.

const VIEW_SIZE := Vector2(1920, 1080)
const GROUND_Y := 930.0
const STAGE_SHADER := preload("res://shaders/maestro_stage.gdshader")
const INK := Color("1c120b")
const BRASS := Color("a8782f")
const BRASS_LIGHT := Color("e9c272")
const BRASS_DARK := Color("5c3b14")
const VELVET := Color("6e1420")
const VELVET_DARK := Color("3a0910")
const GOLD := Color("d9a441")


## Metrônomo grande no canto do palco: o braço bate um lado em cada tempo e a lâmpada pisca na batida.
class StageMetronome extends Node2D:
	var boss: RustMaestroBoss

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var clock := boss.beat_clock if boss != null else 0.0
		var beat := RustMaestroBoss.BEAT
		var body := PackedVector2Array([Vector2(-95, 0), Vector2(95, 0), Vector2(38, -420), Vector2(-38, -420)])
		draw_colored_polygon(body, Color("4a2a16"))
		draw_colored_polygon(PackedVector2Array([Vector2(-95, 0), Vector2(-40, 0), Vector2(-14, -420), Vector2(-38, -420)]), Color("2e190c"))
		draw_colored_polygon(PackedVector2Array([Vector2(20, 0), Vector2(48, 0), Vector2(18, -420), Vector2(8, -420)]), Color("6b4325"))
		draw_polyline(body + PackedVector2Array([body[0]]), INK, 5.0, true)
		# Escala de latão atrás do braço.
		var face := Rect2(-18, -380, 36, 300)
		draw_rect(face, BRASS_DARK)
		for i in 10:
			draw_line(Vector2(-12, -370 + i * 30), Vector2(12, -370 + i * 30), BRASS_LIGHT, 2.0)
		# Braço: bate num extremo a cada tempo.
		var angle := 0.38 * cos(PI * clock / beat)
		var pivot := Vector2(0, -60)
		var tip := pivot + Vector2(sin(angle), -cos(angle)) * 380.0
		draw_line(pivot, tip, INK, 10.0, true)
		draw_line(pivot, tip, BRASS_LIGHT, 5.0, true)
		var weight := pivot + Vector2(sin(angle), -cos(angle)) * 250.0
		var block := PackedVector2Array([Vector2(-22, -18), Vector2(22, -18), Vector2(16, 18), Vector2(-16, 18)])
		var placed := PackedVector2Array()
		for point in block:
			placed.append(weight + point.rotated(angle))
		draw_colored_polygon(placed, GOLD)
		draw_polyline(placed + PackedVector2Array([placed[0]]), INK, 3.0, true)
		draw_circle(pivot, 12.0, BRASS)
		# Lâmpada no topo: acende na batida.
		var flash := clampf(1.0 - fposmod(clock, beat) / 0.18, 0.0, 1.0)
		draw_circle(Vector2(0, -432), 20.0 + flash * 10.0, Color(1.0, 0.85, 0.5, 0.25 * flash))
		draw_circle(Vector2(0, -432), 13.0, Color("3a2412").lerp(Color("ffe6a3"), flash))
		draw_arc(Vector2(0, -432), 13.0, 0, TAU, 20, INK, 3.0, true)


func _ready() -> void:
	z_index = -20
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.size = VIEW_SIZE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = STAGE_SHADER
	material.set_shader_parameter("floor_line", GROUND_Y / VIEW_SIZE.y)
	backdrop.material = material
	backdrop.show_behind_parent = true
	add_child(backdrop)
	var metronome := StageMetronome.new()
	metronome.name = "Metronome"
	metronome.position = Vector2(205, GROUND_Y)
	metronome.boss = get_parent().get_node_or_null("RustMaestroBoss")
	add_child(metronome)


func _draw() -> void:
	_draw_organ()
	_draw_curtains()


## Órgão de tubos no fundo, em dois grupos simétricos, com o console escuro embaixo.
func _draw_organ() -> void:
	var heights := [300, 360, 430, 500, 560, 600, 560, 500, 430, 360, 300]
	for bank: Vector2 in [Vector2(470, 0), Vector2(1130, 0)]:
		var console := Rect2(bank.x - 20, GROUND_Y - 170, 11 * 34 + 40, 170)
		draw_rect(console, Color("23150c"))
		draw_rect(console, INK, false, 4.0)
		for i in heights.size():
			var x: float = bank.x + i * 34
			var top: float = GROUND_Y - 170 - heights[i]
			var rect := Rect2(x, top, 28, heights[i])
			# Latão apagado: o brilho fica para as notas e tubos que machucam.
			draw_rect(rect, BRASS.darkened(0.55))
			draw_rect(Rect2(x, top, 8, heights[i]), BRASS_DARK.darkened(0.5))
			draw_rect(Rect2(x + 15, top, 5, heights[i]), BRASS_LIGHT.darkened(0.55))
			draw_rect(rect, INK, false, 2.5)
			# Boca do tubo.
			draw_colored_polygon(PackedVector2Array([Vector2(x + 5, top + 40), Vector2(x + 23, top + 40),
				Vector2(x + 18, top + 54), Vector2(x + 10, top + 54)]), INK)
	# Sombra do órgão escurecendo a parte de baixo dele (fica atrás, não compete com os ataques).
	draw_rect(Rect2(440, GROUND_Y - 40, 1100, 40), Color(0, 0, 0, 0.35))


## Cortinas de veludo nas laterais e bambinela com franja dourada no alto.
func _draw_curtains() -> void:
	for side: float in [-1.0, 1.0]:
		var outer := 0.0 if side < 0.0 else VIEW_SIZE.x
		for fold in 5:
			var x := fold * 26.0 if side < 0.0 else VIEW_SIZE.x - (fold + 1) * 26.0
			draw_rect(Rect2(x, 0, 26, GROUND_Y), VELVET if fold % 2 == 0 else VELVET_DARK)
		var edge := outer - side * 128.0
		draw_line(Vector2(edge, 0), Vector2(edge, GROUND_Y), INK, 4.0)
		# Abraçadeira dourada prendendo a cortina.
		draw_circle(Vector2(outer - side * 110.0, 520), 16.0, GOLD)
		draw_arc(Vector2(outer - side * 110.0, 520), 16.0, 0, TAU, 20, INK, 3.0, true)
	var valance := Rect2(0, 0, VIEW_SIZE.x, 70)
	draw_rect(valance, VELVET)
	for i in 32:
		var x := i * 60.0
		draw_circle(Vector2(x + 30, 70), 30, VELVET)
		draw_arc(Vector2(x + 30, 70), 30, 0, PI, 12, INK, 3.0, true)
		draw_line(Vector2(x + 30, 100), Vector2(x + 30, 118), GOLD, 4.0)
		draw_circle(Vector2(x + 30, 122), 6.0, GOLD)
	draw_rect(Rect2(0, 62, VIEW_SIZE.x, 8), GOLD)
