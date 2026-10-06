class_name TrapezeGhost
extends Enemy
## Trapezista do Além (Trem, vagão TRAPÉZIO): fantasma pendurada de cabeça para baixo num trapézio que balança
## por cima do vagão pelo relógio da fase. No ponto mais baixo ela passa na altura da cabeça de quem está em
## pé: abaixar (ou pular por cima dela nas pontas do balanço). 8 tiros derrubam. O ponto onde ela é colocada é
## onde as mãos dela passam no ponto mais baixo. Desenho provisório por código (pedido de arte D2 em
## docs/prompts/chatgpt_trem_desafiantes.md).

const SCARF := Color("7a3fa0")
const SKIN := Color("e9f0f2")
const BAR := Color("d9a441")
const ROPE := Color("c9b48a")

## Comprimento das cordas (até as mãos), ângulo máximo, duração de uma ida e volta e atraso (fração).
@export var length := 430.0
@export var amplitude := 1.0
@export var period := 2.8
@export var offset := 0.0

var _pivot := Vector2.ZERO
var _angle := 0.0


func _init() -> void:
	max_health = 8
	body_size = Vector2(60, 120)


func _ready() -> void:
	super()
	_pivot = home - Vector2(0, length)


func _move(t: float) -> void:
	_angle = amplitude * sin(TAU * (t / period + offset))
	position = _pivot + Vector2(sin(_angle), cos(_angle)) * length


func _update_art() -> void:
	queue_redraw()


func _draw() -> void:
	var bar := Vector2(0, -body_size.y)
	var top := _pivot - position
	for x in [-50.0, 50.0]:
		draw_line(top + Vector2(x * 0.4, 0), bar + Vector2(x, 0), INK, 6.0)
		draw_line(top + Vector2(x * 0.4, 0), bar + Vector2(x, 0), ROPE, 3.0)
	draw_line(bar + Vector2(-56, 0), bar + Vector2(56, 0), INK, 12.0)
	draw_line(bar + Vector2(-52, 0), bar + Vector2(52, 0), BAR, 6.0)
	# Pernas dobradas no trapézio, corpo e cabeça para baixo, braços esticados para pegar.
	draw_line(bar, bar + Vector2(0, 50), INK, 22.0)
	draw_line(bar, bar + Vector2(0, 50), SCARF, 14.0)
	var head := bar + Vector2(0, 76)
	draw_circle(head, 24.0, INK)
	draw_circle(head, 20.0, SKIN)
	draw_circle(head + Vector2(-7, 4), 4.0, INK)
	draw_circle(head + Vector2(7, 4), 4.0, INK)
	draw_arc(head + Vector2(0, -6), 8.0, PI + 0.3, TAU - 0.3, 8, INK, 3.0)
	for x in [-14.0, 14.0]:
		draw_line(head + Vector2(x * 0.6, 18), Vector2(x * 1.4, -4), INK, 9.0)
		draw_line(head + Vector2(x * 0.6, 18), Vector2(x * 1.4, -4), SKIN, 4.5)
	# Lenço que fica para trás no balanço.
	draw_line(bar + Vector2(0, 30), bar + Vector2(-sin(_angle) * 70.0, 20), SCARF, 8.0)
