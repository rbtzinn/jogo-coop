class_name LanternGhost
extends Enemy
## Sombra do Lanterninha (Trem, vagão FANTASMAS): fantasma de lanterninha de teatro que anda de um lado para
## o outro em cima do vagão. Com a lanterna acesa ele é sólido e leva tiro; com ela apagada vira uma sombra
## que os tiros atravessam, mas que continua machucando quem encosta. Tudo pelo relógio da fase. 6 tiros
## derrubam. Desenho provisório por código (pedido de arte D5 em docs/prompts/chatgpt_trem_desafiantes.md).

## Ciclo da lanterna: acesa durante LIT_TIME, apagada no resto.
const CYCLE := 3.4
const LIT_TIME := 2.0
const UNIFORM := Color("2f3d6b")
const SKIN := Color("e9f0f2")
const FLAME := Color("ffc93c")

@export var patrol_range := 200.0
@export var speed := 120.0
@export var offset := 0.0

var _facing := -1.0
var _lit := true


func _init() -> void:
	max_health = 6
	body_size = Vector2(60, 140)


func _move(t: float) -> void:
	var cycle := 4.0 * patrol_range / speed
	var u := fmod(t + offset * cycle, cycle) / cycle
	var x := -patrol_range + 4.0 * patrol_range * u if u < 0.5 else 3.0 * patrol_range - 4.0 * patrol_range * u
	_facing = 1.0 if u < 0.5 else -1.0
	position = home + Vector2(x, 0)
	var lit := fmod(t + offset * CYCLE, CYCLE) < LIT_TIME
	if lit != _lit:
		_lit = lit
		hurtbox.set_deferred(&"monitorable", lit and not dead)


func _update_art() -> void:
	if not _lit:
		modulate.a *= 0.3
	queue_redraw()


func _draw() -> void:
	var body := Rect2(-24, -110, 48, 110)
	draw_rect(body.grow(4), INK)
	draw_rect(body, UNIFORM)
	var head := Vector2(0, -128)
	draw_circle(head, 24.0, INK)
	draw_circle(head, 20.0, SKIN)
	draw_rect(Rect2(head + Vector2(-20, -26), Vector2(40, 12)), UNIFORM)
	var eye := FLAME if not _lit else INK
	draw_circle(head + Vector2(_facing * 8.0 - 5.0, 0), 4.0, eye)
	draw_circle(head + Vector2(_facing * 8.0 + 5.0, 0), 4.0, eye)
	var lantern := Vector2(_facing * 38.0, -70)
	draw_line(Vector2(_facing * 20.0, -90), lantern, INK, 8.0)
	draw_rect(Rect2(lantern + Vector2(-12, 0), Vector2(24, 30)), INK)
	draw_rect(Rect2(lantern + Vector2(-8, 4), Vector2(16, 22)), FLAME if _lit else Color("3a3a3a"))
