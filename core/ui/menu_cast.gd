class_name MenuCast
extends Control
## Palhaço ou acrobata de corpo inteiro para a tela de título e o menu (16/10/2026): folha de 6 quadros
## (core/ui/art/menu_cast/<kind>_menu_sheet.png, grade 3 x 2 de 512 px, gerada pelo usuário no GPT) tocada a
## 12 quadros por segundo, com um quique e um balanço leves por código, presos no pé, porque os quadros
## mudam pouco entre si. A folha olha para a direita; `facing_left` espelha.
## Colocar com place_feet(): o nó se posiciona pelo ponto entre os pés.

const SHEET := "res://core/ui/art/menu_cast/%s_menu_sheet.png"
const CELL := 512.0
const COLUMNS := 3
const FRAMES := 6
const FPS := 12.0
## Ponto entre os pés dentro de um quadro (os pés de todos os quadros estão nessa linha).
const FEET_IN_CELL := Vector2(256, 489)
## Ritmo de cada um: [segundos por quique, fase, quanto estica, quanto balança (radianos)].
const MOTION := {
	"clown": [1.15, 0.0, 0.018, 0.012],
	"acrobat": [0.9, 1.7, 0.014, 0.010],
}

var kind := "clown"
var facing_left := false
var _sheet: Texture2D
var _time := 0.0


func _init(cast_kind := "clown", face_left := false, height := 440.0) -> void:
	kind = cast_kind
	facing_left = face_left
	size = Vector2(height, height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_sheet = load(SHEET % kind)
	_time = randf() * 2.0


## Põe o ponto entre os pés em `feet` (coordenadas do pai).
func place_feet(feet: Vector2) -> void:
	var scale_factor := size.y / CELL
	var feet_x := CELL - FEET_IN_CELL.x if facing_left else FEET_IN_CELL.x
	position = feet - Vector2(feet_x, FEET_IN_CELL.y) * scale_factor


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _sheet == null:
		return
	var frame := int(_time * FPS) % FRAMES
	var region := Rect2(Vector2(frame % COLUMNS, floori(frame / float(COLUMNS))) * CELL, Vector2(CELL, CELL))
	var motion: Array = MOTION.get(kind, MOTION["clown"])
	var beat: float = (_time / motion[0] + motion[1]) * TAU
	var scale_factor := size.y / CELL
	var feet_x := CELL - FEET_IN_CELL.x if facing_left else FEET_IN_CELL.x
	# Estica para cima e afina um pouco (quique) e balança, sempre a partir do pé; o espelho entra na escala.
	var stretch: float = motion[2] * sin(beat)
	var squash := Vector2((1.0 - stretch * 0.5) * (-1.0 if facing_left else 1.0), 1.0 + stretch)
	draw_set_transform(Vector2(feet_x, FEET_IN_CELL.y) * scale_factor, motion[3] * sin(beat * 0.5), squash)
	draw_texture_rect_region(_sheet, Rect2(-FEET_IN_CELL * scale_factor, Vector2(CELL, CELL) * scale_factor), region)
	draw_set_transform(Vector2.ZERO)
