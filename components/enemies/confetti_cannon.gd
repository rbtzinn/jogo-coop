class_name ConfettiCannon
extends Enemy
## Canhão de confete parado em cima de um vagão, virado para a esquerda (de onde os jogadores
## vêm). De tempos em tempos solta uma bola de confete rente ao chão (pular por cima); a cada
## quatro, uma vem rosa (parry). 8 tiros derrubam. As bolas também seguem o relógio da fase.
## Desenho em 4 quadros: entediado, enchendo as bochechas antes do tiro, atirando e tonto depois.

const ART := preload("res://components/enemies/art/cannon.tres")
## Quanto antes do tiro ele enche as bochechas, e quanto tempo fica tonto depois.
const CHARGE_TIME := 0.45
const DIZZY_TIME := 0.6

const BALL_RADIUS := 18.0

@export var period := 2.4
@export var offset := 0.0
@export var ball_speed := 420.0
@export var ball_range := 900.0

## Bolas na tela: número do disparo -> nó.
var _balls := {}
var _recoil := 0.0
## Tempo desde o último tiro e até o próximo (para escolher o quadro).
var _since_shot := INF
var _to_shot := INF
var _art := Sprite2D.new()


func _init() -> void:
	max_health = 8
	body_size = Vector2(90, 70)


func _ready() -> void:
	super()
	add_child(_art)


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
	_since_shot = since_last if newest >= 0 else INF
	_to_shot = (newest + 1) * period + offset - t


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


func _update_art() -> void:
	var index := 0
	if _since_shot < 0.25:
		index = 2
	elif _since_shot < DIZZY_TIME:
		index = 3
	elif _to_shot < CHARGE_TIME:
		index = 1
	ART.show_on(_art, index)
	_art.scale = Vector2.ONE * ART.frame_scale
	_art.position.x = _recoil * 8.0
