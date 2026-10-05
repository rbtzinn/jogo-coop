class_name ConfettiCannon
extends Enemy
## Canhão de confete parado em cima de um vagão, virado para a esquerda (de onde os jogadores
## vêm). De tempos em tempos solta uma bola de confete rente ao chão (pular por cima); a cada
## quatro, uma vem rosa (parry). 8 tiros derrubam. As bolas também seguem o relógio da fase.

const BALL_RADIUS := 18.0

@export var period := 2.4
@export var offset := 0.0
@export var ball_speed := 420.0
@export var ball_range := 900.0

## Bolas na tela: número do disparo -> nó.
var _balls := {}
var _recoil := 0.0


func _init() -> void:
	max_health = 8
	body_size = Vector2(90, 70)


func _move(t: float) -> void:
	var travel := ball_range / ball_speed
	var newest := floori((t - offset) / period)
	var oldest := ceili((t - offset - travel) / period)
	for k in range(maxi(oldest, 0), newest + 1):
		var since := t - offset - k * period
		if since < 0.0:
			continue
		if not _balls.has(k):
			_balls[k] = _make_ball(k)
		var ball: Node2D = _balls[k]
		if is_instance_valid(ball):
			ball.position = Vector2(-60.0 - ball_speed * since, -BALL_RADIUS - 2.0)
	for k in _balls.keys():
		if k < oldest:
			if is_instance_valid(_balls[k]):
				_balls[k].queue_free()
			_balls.erase(k)
	var since_last := t - offset - newest * period
	_recoil = clampf(1.0 - since_last / 0.25, 0.0, 1.0) if newest >= 0 else 0.0


func die() -> void:
	super()
	for ball in _balls.values():
		if is_instance_valid(ball):
			ball.queue_free()
	_balls.clear()


func _make_ball(k: int) -> Node2D:
	var ball := ConfettiBall.new()
	ball.pink = k % 4 == 3
	ball.parry_id = "%s:%d" % [parry_id, k]
	add_child(ball)
	return ball


func _draw() -> void:
	var kick := _recoil * 8.0
	# Rodas.
	for x in [-26.0, 26.0]:
		draw_circle(Vector2(x + kick, -16), 17, INK)
		draw_circle(Vector2(x + kick, -16), 13, Color("a3282a"))
	# Cano listrado virado para a esquerda, com cara.
	var barrel := Rect2(Vector2(-56 + kick, -66), Vector2(96, 40))
	draw_rect(barrel.grow(3), INK)
	draw_rect(barrel, Color("f2e6cc"))
	for i in 3:
		draw_rect(Rect2(barrel.position + Vector2(14 + i * 28, 0), Vector2(12, 40)), Color("5fbfd8"))
	draw_circle(Vector2(-58 + kick, -46), 22, INK)
	draw_circle(Vector2(-58 + kick, -46), 15, Color("2a1f2e"))
	draw_circle(Vector2(18 + kick, -56), 5, INK)
	draw_arc(Vector2(16 + kick, -40), 9, 0.3, PI - 0.3, 8, INK, 3.0)
