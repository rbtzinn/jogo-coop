class_name MagicProp
extends EnemyHitbox
## Objeto de mágica do Zaratan: carta, coelho, serra, pomba ou "tralha" que cai da cartola.
## Quem move é o ataque (posição calculada pelo tempo, igual nos dois PCs); este nó só desenha
## e machuca. Os turquesa (`pink`; eram rosa até 06/10/2026) aceitam parry. As "cartas" (`card`) são desenhadas
## como bilhetes encantados do circo desde 06/10/2026 (antes, cartas de baralho com ás de copas).

const INK := Color("1b1410")
## Bilhete (o papel creme e a tinta vermelha dos ingressos do circo).
const TICKET_PAPER := Color("f2e6cc")
const TICKET_RED := Color("a3282a")

## card, rabbit, saw, dove, junk
@export var kind := &"card"
@export var pink := false

## Identifica o objeto nos dois PCs (para estourar o mesmo quando o parceiro faz parry).
var parry_id := ""
var popped := false
## Direção do movimento (para virar o desenho).
var heading := Vector2.LEFT
## Carta que persegue: desenhada preta, sem girar, apontando para onde vai, com "P1" ou "P2" (quem ela
## caça; vazio se ninguém).
var homing := false
var homing_label := ""

var _time := 0.0


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius()
	shape.shape = circle
	add_child(shape)


func radius() -> float:
	match kind:
		&"saw":
			return 34.0
		&"rabbit":
			return 26.0
		&"dove":
			return 22.0
	return 20.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func on_parried() -> void:
	popped = true
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.2)


func _draw() -> void:
	match kind:
		&"card":
			if homing:
				_draw_homing_card()
				return
			# Bilhete encantado (era carta de baralho com ás de copas até 06/10/2026: lembrava demais o Cuphead).
			draw_set_transform(Vector2.ZERO, _time * 10.0)
			_draw_ticket(Rect2(-18, -26, 36, 52), ParryStyle.MAIN if pink else TICKET_PAPER,
					Color.WHITE if pink else TICKET_RED, INK)
			draw_set_transform(Vector2.ZERO)
		&"saw":
			draw_set_transform(Vector2.ZERO, _time * 20.0)
			var teeth := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				teeth.append(Vector2.from_angle(a) * (34.0 if i % 2 == 0 else 26.0))
			draw_colored_polygon(teeth, Color("c8c8d0"))
			teeth.append(teeth[0])
			draw_polyline(teeth, INK, 3.0)
			draw_circle(Vector2.ZERO, 8, INK)
			draw_set_transform(Vector2.ZERO)
		&"rabbit":
			var f := signf(heading.x) if heading.x != 0.0 else -1.0
			var body := ParryStyle.MAIN if pink else Color("f2f2f6")
			for ear in [-1.0, 1.0]:
				var base := Vector2(6 * f + ear * 6, -18)
				var tip := base + Vector2(ear * 6 - 4 * f, -30)
				draw_line(base, tip, INK, 12.0)
				draw_line(base, tip, body, 7.0)
			draw_circle(Vector2.ZERO, 24, INK)
			draw_circle(Vector2.ZERO, 21, body)
			draw_circle(Vector2(12 * f, -6), 4, Color("d23a3a"))
			draw_circle(Vector2(18 * f, 2), 3, Color("ff8fb0"))
			draw_circle(Vector2(-20 * f, 6), 7, Color.WHITE)
		&"dove":
			var f := signf(heading.x) if heading.x != 0.0 else -1.0
			var flap := sin(_time * 20.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-6 * f, -4), Vector2(-14 * f, -24 * flap - 6), Vector2(8 * f, -2)]),
					Color("e8e8ee"))
			draw_circle(Vector2.ZERO, 18, INK)
			draw_circle(Vector2.ZERO, 15, ParryStyle.MAIN if pink else Color.WHITE)
			draw_circle(Vector2(14 * f, -8), 8, ParryStyle.MAIN if pink else Color.WHITE)
			draw_circle(Vector2(17 * f, -10), 2, INK)
		_:
			# Tralha da cartola: bola listrada.
			draw_set_transform(Vector2.ZERO, _time * 6.0)
			draw_circle(Vector2.ZERO, 23, INK)
			draw_circle(Vector2.ZERO, 20, ParryStyle.MAIN if pink else Color("ffc93c"))
			draw_rect(Rect2(-20, -5, 40, 10), Color.WHITE if pink else Color("d23a3a"))
			draw_set_transform(Vector2.ZERO)
	# Marca do parry: a estrelinha.
	if pink:
		ParryStyle.draw_sparkle(self, Vector2(18, -26), 10.0, _time)


## Bilhete do circo: papel com um dente de cada lado, picote no meio e um selo de estrela.
func _draw_ticket(rect: Rect2, paper: Color, mark: Color, outline: Color) -> void:
	var points := PackedVector2Array()
	var notch := 7.0
	var mid := rect.get_center().y
	points.append(rect.position)
	points.append(Vector2(rect.end.x, rect.position.y))
	for i in 7:
		var a := PI * i / 6.0
		points.append(Vector2(rect.end.x - sin(a) * notch, mid - cos(a) * notch))
	points.append(rect.end)
	points.append(Vector2(rect.position.x, rect.end.y))
	for i in 7:
		var a := PI * i / 6.0
		points.append(Vector2(rect.position.x + sin(a) * notch, mid + cos(a) * notch))
	draw_colored_polygon(points, paper)
	points.append(points[0])
	draw_polyline(points, outline, 3.0, true)
	# Picote.
	var y := rect.position.y + rect.size.y * 0.3
	var x := rect.position.x + 4.0
	while x < rect.end.x - 4.0:
		draw_line(Vector2(x, y), Vector2(minf(x + 3.0, rect.end.x - 4.0), y), mark, 2.0)
		x += 6.0
	# Selo de estrela.
	var star := PackedVector2Array()
	var center := Vector2(rect.get_center().x, mid + 6.0)
	for i in 10:
		var a := -PI * 0.5 + PI * i / 5.0
		star.append(center + Vector2.from_angle(a) * (9.0 if i % 2 == 0 else 4.0))
	draw_colored_polygon(star, mark)


func _draw_homing_card() -> void:
	var back := -heading.normalized()
	for i in 3:
		var from := back * (30.0 + i * 16.0)
		draw_line(from, from + back * 10.0, INK, 4.0 - i)
	draw_set_transform(Vector2.ZERO, heading.angle() + PI / 2.0)
	_draw_ticket(Rect2(-18, -26, 36, 52), INK, Color("6e1c1b"), Color("fff3c4"))
	draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, Vector2(-18, 8), homing_label, HORIZONTAL_ALIGNMENT_CENTER, 36, 20,
			Color("fff3c4"))
