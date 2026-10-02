class_name Juggler
extends Node2D
## Um dos Irmãos Malabaristas (Tico ou Teco), desenhado e animado por código (provisório,
## trocável por arte quadro a quadro: docs/prompts/codex_malabaristas.md).
## O ponto do nó é entre os pés. Os ataques mudam `pose`, `spin`, `facing` e a posição; o
## desenho cuida do resto (pernas andando, braços malabarizando, cara de cada momento).
## Filhos esperados: Hurtbox (leva tiro) e Hitbox (encostar machuca).

const INK := Color("1b1410")
const SKIN := Color("f1c8a0")
const CREAM := Color("f2e6cc")
const BALL_COLORS := [Color("d23a3a"), Color("ffc93c"), Color("5fbfd8")]

@export var stripe_color := Color("c8302c")
@export var hair_color := Color("2a1a12")

## Para onde olha (1 = direita, -1 = esquerda).
var facing := 1
## idle, throw, crouch, spin, sit (em cima do irmão), ride (no monociclo), dizzy, down.
var pose := &"idle"
## Voltas do corpo (salto mortal, rolando).
var spin := 0.0
## Andando (pernas se mexem).
var walking := false
## Tonto: estrelas girando, olhos em X, não malabariza.
var dizzy := false
## Bolinhas girando nas mãos.
var juggling := true

var _time := 0.0
var _flash := 0.0

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: EnemyHitbox = $Hitbox


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6)
	queue_redraw()


func flash() -> void:
	_flash = 0.5


## Liga/desliga levar tiro e machucar ao encostar.
func set_vulnerable(value: bool) -> void:
	hurtbox.monitorable = value
	hitbox.active = value


## Altura da área que machuca (no totem o de cima fica mais baixo para os pedestais serem seguros).
func set_hitbox_height(height: float) -> void:
	var shape := hitbox.get_child(0) as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	rect.size.y = height
	shape.position.y = -height * 0.5


## Mão que joga (na frente) e a de trás, no espaço do mundo.
func hand_position() -> Vector2:
	return global_position + Vector2(facing * 38, -150 if pose != &"crouch" else -120)


func head_position() -> Vector2:
	return global_position + Vector2(0, -180)


func _draw() -> void:
	var lying := pose == &"down"
	var crouch := 22.0 if pose == &"crouch" else 0.0
	var center := Vector2(0, -105 + crouch)
	var angle := spin * TAU * facing
	if lying:
		angle = -PI * 0.5 * facing
	draw_set_transform(center, angle)
	var f := float(facing)
	var o := -center
	# Pernas.
	var step := sin(_time * 12.0) * 16.0 if walking else 0.0
	var feet := [Vector2(-16 - step, 0), Vector2(16 + step, 0)]
	if pose == &"sit" or pose == &"ride":
		feet = [Vector2(-10 + 26 * f, -30), Vector2(14 + 26 * f, -24)]
	elif pose == &"spin":
		feet = [Vector2(-14, -40), Vector2(14, -44)]
	for i in 2:
		var hip := o + Vector2(-14 + 28 * i, -70 + crouch)
		var foot: Vector2 = o + feet[i]
		draw_line(hip, foot, INK, 14.0)
		draw_line(hip, foot, CREAM, 8.0)
		draw_circle(foot + Vector2(6 * f, -4), 11, INK)
		draw_circle(foot + Vector2(6 * f, -4), 8, Color("6e1c1b"))
	# Tronco listrado.
	var torso := o + center
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		points.append(torso + Vector2(cos(a) * 40, sin(a) * 52))
	draw_colored_polygon(points, CREAM)
	for k in [-30.0, -6.0, 18.0]:
		var w := sqrt(maxf(0.0, 1.0 - pow((k + 7.0) / 52.0, 2))) * 40.0
		draw_rect(Rect2(torso + Vector2(-w, k), Vector2(w * 2, 14)), stripe_color)
	points.append(points[0])
	draw_polyline(points, INK, 4.0, true)
	# Braços e mãos.
	var shoulders := [torso + Vector2(-30, -36), torso + Vector2(30, -36)]
	var hands := _hand_offsets()
	for i in 2:
		var hand: Vector2 = torso + hands[i]
		draw_line(shoulders[i], hand, INK, 11.0)
		draw_line(shoulders[i], hand, stripe_color, 6.0)
		draw_circle(hand, 10, INK)
		draw_circle(hand, 7.5, Color.WHITE)
	# Cabeça.
	var head := torso + Vector2(0, -78)
	draw_circle(head, 36, INK)
	draw_circle(head, 33, SKIN)
	draw_arc(head + Vector2(0, -4), 33, PI * 1.05, PI * 1.95, 16, hair_color, 14.0)
	draw_circle(head + Vector2(-26 * f, -14), 9, hair_color)
	_draw_face(head, f)
	if dizzy:
		for i in 3:
			var a := _time * 5.0 + TAU * i / 3.0
			_draw_star(head + Vector2(cos(a) * 46, -40 + sin(a) * 12), 9.0, Color("ffc93c"))
	# Bolinhas de malabares.
	if juggling and not dizzy and pose in [&"idle", &"sit", &"ride"]:
		for i in 3:
			var a := _time * 7.0 + TAU * i / 3.0
			var at := torso + Vector2(cos(a) * 30, -70 + sin(a) * 46)
			draw_circle(at, 9, INK)
			draw_circle(at, 7, BALL_COLORS[i])
	draw_set_transform(Vector2.ZERO)


## Onde ficam as mãos (relativo ao meio do tronco) em cada pose.
func _hand_offsets() -> Array:
	var f := float(facing)
	match pose:
		&"throw":
			return [Vector2(-34 * f, -10), Vector2(38 * f, -70)]
		&"crouch":
			return [Vector2(-44, 10), Vector2(44, 10)]
		&"spin":
			return [Vector2(-20, -10), Vector2(20, -10)]
		&"dizzy", &"down":
			return [Vector2(-46, 20), Vector2(46, 20)]
	if dizzy:
		return [Vector2(-46, 20), Vector2(46, 20)]
	var bob := sin(_time * 14.0) * 12.0
	return [Vector2(-30, -6 + bob), Vector2(30, -6 - bob)]


func _draw_face(head: Vector2, f: float) -> void:
	var expression := _expression()
	var eye_y := head.y - 4
	for side in [-1.0, 1.0]:
		var eye := Vector2(head.x + side * 12 + 6 * f, eye_y)
		match expression:
			&"dizzy", &"down":
				draw_line(eye + Vector2(-6, -6), eye + Vector2(6, 6), INK, 3.0)
				draw_line(eye + Vector2(-6, 6), eye + Vector2(6, -6), INK, 3.0)
			&"focus":
				draw_line(eye + Vector2(-7, -2), eye + Vector2(7, 2 * side * f), INK, 4.0)
			_:
				var tall := 10.0 if expression in [&"shout", &"scared"] else 8.0
				draw_circle(eye, tall * 0.8, Color.WHITE)
				draw_circle(eye + Vector2(3 * f, 0), 3.5, INK)
	# Nariz e bigode enrolado.
	var nose := head + Vector2(16 * f, 6)
	draw_circle(nose, 7, Color("e09a7a"))
	for side in [-1.0, 1.0]:
		var start := nose + Vector2(-2 * f, 8)
		draw_arc(start + Vector2(side * 12, 2), 11, 0.2 if side > 0 else PI - 1.2, 1.2 if side > 0 else PI - 0.2, 8, INK, 6.0)
	# Boca.
	var mouth := head + Vector2(8 * f, 22)
	match _expression():
		&"shout", &"scared":
			draw_circle(mouth, 9, INK)
			draw_circle(mouth + Vector2(0, 3), 5, Color("c23b3b"))
		&"laugh":
			draw_arc(mouth, 10, 0.1, PI - 0.1, 10, INK, 4.0)
			draw_circle(mouth + Vector2(0, 4), 6, INK)
		&"dizzy", &"down":
			var wave := PackedVector2Array()
			for i in 7:
				wave.append(mouth + Vector2(-12 + i * 4, sin(i * 1.6 + _time * 8.0) * 3))
			draw_polyline(wave, INK, 3.0)
		&"focus":
			draw_line(mouth + Vector2(-8, 0), mouth + Vector2(8, 0), INK, 4.0)
		_:
			draw_arc(mouth + Vector2(0, -4), 11, 0.3, PI - 0.3, 10, INK, 4.0)


## Cara de cada momento (expressão diferente em cada ação).
func _expression() -> StringName:
	if dizzy:
		return &"dizzy"
	match pose:
		&"throw":
			return &"shout"
		&"crouch":
			return &"focus"
		&"spin":
			return &"laugh"
		&"down":
			return &"down"
	return &"grin"


func _draw_star(at: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		points.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * radius)
	draw_colored_polygon(points, color)
