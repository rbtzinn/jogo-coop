class_name CheerText
extends Node2D
## Letreiro curto que salta no lugar da jogada e sobe sumindo ("Número Perfeito!").
## Desenhado por código com a fonte de título; menor que a faixa do Fight, para não
## esconder a luta.

const DURATION := 1.3
const FONT_SIZE := 46

var text := ""
var color := Color("ffc93c")
var _time := 0.0


static func spawn(at: Vector2, message: String, text_color := Color("ffc93c")) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var cheer := CheerText.new()
	cheer.text = message
	cheer.color = text_color
	cheer.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	tree.current_scene.add_child(cheer)
	# Fica dentro da tela mesmo quando a jogada acontece perto da borda.
	cheer.global_position = Vector2(clampf(at.x, 260.0, 1660.0), clampf(at.y, 160.0, 940.0))
	cheer.z_index = 60


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	position.y -= 60.0 * delta
	queue_redraw()


func _draw() -> void:
	var k := _time / DURATION
	# Entra quicando (cresce além do tamanho e volta) e some no fim.
	var pop := ease(minf(_time / 0.25, 1.0), -2.0)
	var grow := 0.3 + 0.7 * pop + sin(minf(_time / 0.25, 1.0) * PI) * 0.25
	var alpha := 1.0 if k < 0.7 else 1.0 - (k - 0.7) / 0.3
	var font := UiTheme.TITLE_FONT
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	draw_set_transform(Vector2.ZERO, sin(_time * 7.0) * 0.04, Vector2.ONE * grow)
	var at := Vector2(-text_size.x * 0.5, text_size.y * 0.3)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 12, Color(UiTheme.INK, alpha))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(color, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
